/* Definições vindas do kernel. */
#include <ioports.h>
#include <memory.h>

#include "defines.h"
#include "vars.h"     /* Macros para ajustes de ponteiros para acesso a variáveis globais. */

/*********************
 * Funções relacionadas ao vídeo.
 *********************/

/* Variáveis que mantém o registro da posição x,y na tela. */
static unsigned char screen_x = 0, screen_y = 1;  /* Deixamos o cursor na linha 1 em mbr.asm. */

static void scroll_up(void)
{
  void *srcptr, *destptr;
  unsigned long size;

  /* Move todas as linhas abaixo da primeira para cima. */
  destptr = (srcptr = VIDEO_BUFFER_PTR) + SCREEN_WIDTH*2;
  size = (SCREEN_HEIGHT - 1) * SCREEN_WIDTH * 2;
  memcpy(destptr, srcptr, size);

  /* Preenche a última linha com espaços. */
  destptr += size;
  memsetw(destptr, 0x0720, SCREEN_WIDTH); /* 0x0720 é um espaço com atributo
                                                     "branco sobre preto". */
}

void USEREGS putch(unsigned char c)
{
  unsigned char sx, sy;

  /* Pega a posição atual. */
  sx = UCHAR_VAR(screen_x);
  sy = UCHAR_VAR(screen_y);

  switch (c)
  {
    /* Line-feed salta para a próxima linha sem alterar a posição x. */
    case '\n':
    test_scroll:
      sy++;
      /* Se passamos da última linha, scroll-up e ficamos na última. */
      while (sy-- >= SCREEN_HEIGHT)
        scroll_up();
      break;

    /* Carriage-Return só nos coloca no início da linha! */
    case '\r':
      sx = 0;
      break;

    /***--- Eu poderia implementar o beep, mas não quero mexer com o timer no boot. ---***/

    default:
      /* Ignora todos os outros caracteres não imprimíveis. */
      if (c < ' ')
        return;

      /* Senão, escreve caracter na tela. */
      *((unsigned short *)VIDEO_PTR(sx++, sy)) = 0x0700 | c;

      /* Se chegamos ao final da linha, faz algo equivalente ao um
         "\r\n". */
      if (sx >= SCREEN_WIDTH)
      {
        sx = 0;
        goto test_scroll;
      }
  }

  /* Atualiza a posição atual.*/
  UCHAR_VAR(screen_x) = sx;
  UCHAR_VAR(screen_y) = sy;
}

void USEREGS _puts(char *s) { for (;*s;s++) putch(*s); }

/******************************************** 
 * Função para leitura de setores do disco.
 * Usa PIO-ATA, sem uso de UDMA ou IRQs, fazendo pooling. 
 *********************************************/
#define HDD_CMD_READRETRY       0x20
#define HDD_CMD_READNORETRY     0x21

#define HDC0_BASE_PORT          0x1f0
#define HDC1_BASE_PORT          0x170

#define HDC_DATA_PORT(x)          (x)
#define HDC_ERROR_PORT(x)         ((x) + 1)
#define HDC_SECTOR_COUNT_PORT(x)  ((x) + 2)
#define HDC_SECTOR_PORT(x)        ((x) + 3)
#define HDC_CYLINDER_LOW_PORT(x)  ((x) + 4)
#define HDC_CYLINDER_HI_PORT(x)   ((x) + 5)
#define HDC_DRIVE_HEAD_PORT(x)    ((x) + 6)
#define HDC_COMMAND_PORT(x)       ((x) + 7)
#define HDC_STATUS_PORT(x)        ((x) + 7)

static unsigned short select_hdc(unsigned char drive_no)
{
  if (drive_no >= 0x80)
    return HDC0_BASE_PORT &  ~(unsigned short)((drive_no & 2) << 6);
  return 0;
}

/* --- Isso está certo? */
#define CHS2LBA(c,h,s,nheads,nsectors) (((c)*(nheads)+(h)) * (nsectors) + ((s) - 1))

/* Lê setores usando LBA28. 
   Retorna EAX=0 se ok, caso contrário, erro!

   Essa é uma rotina preliminar. Possivelmente terei que colocar verificações de erros
   adicionais. */
int NOINLINE read_sectors(unsigned char drive_no, 
                                        unsigned long lba,
                                        unsigned char sectors,
                                        void *buffer)   /* Normalizado! */

{
  unsigned short port;
  unsigned int buffer_size;

  if (!(port = select_hdc(drive_no)))
    return 1;

  buffer_size = sectors * 512;
  
  /* Informa a cabeça e o drive. */
  outportb(HDC_DRIVE_HEAD_PORT(port), 
      inportb(HDC_DRIVE_HEAD_PORT(port)) | 
        0xe0                             | /* Os 3 bits superiores usam LBA. */
        ((drive_no & 1) << 4)            | /* Seleciona o HD da controladora. */
        ((lba >> 24) & 0x0f));             /* Os 4 bits inferiores nos dão a "cabeça". */

  /* Informa quantos setores, o setor inicial e o cilindro inicial. */
  outportb(HDC_SECTOR_COUNT_PORT(port), sectors);
  outportb(HDC_SECTOR_PORT(port), lba);
  outportb(HDC_CYLINDER_LOW_PORT(port), lba >> 8);
  outportb(HDC_CYLINDER_HI_PORT(port), lba >> 16);

  /* Envia comando para ler, com repetição! */
  outportb(HDC_COMMAND_PORT(port), HDD_CMD_READRETRY);

  /* Espera até a controladora terminar de processar o comando. */
  while ((inportb(HDC_STATUS_PORT(port)) & 0x08) == 0);

  /* Lê o bloco de dados para o buffer. 
     Não faço um insd aqui porque a documentação do PIIX3 e do ICH9 me dizem que
     leituras de dwords são internamente feitas como duas leituras de words.
     Então, para que tentar fazer? */
  __asm__ __volatile__ (
    "rep; insw"
    : 
    : "c" (buffer_size / 2), "d" (HDC_DATA_PORT(port)), "D" (buffer) 
    : "memory"
      );

  /* Tudo ok. */
  return 0;
}
