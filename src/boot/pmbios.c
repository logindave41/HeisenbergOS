/* Rotinas de vídeo da nossa "BIOS". */
#include <ioports.h>
#include <memory.h>
#include "defines.h"
#include "vars.h"

/*********************
 * Funções relacionadas ao vídeo.
 *********************/

/* Isso é válido para o modo 2 */
#define VIDEO_BUFFER_PTR  (void *)0xb8000
#define SCREEN_WIDTH  80
#define SCREEN_HEIGHT 25
#define VIDEO_PTR(x,y) (void *)(VIDEO_BUFFER_PTR + ((y) * SCREEN_WIDTH * 2) + (x)*2)

static unsigned char screen_x = 0, screen_y = 1;  /* Deixamos o cursor na linha 1 em mbr.asm. */
static unsigned char screen_attrib = 7;

void USEREGS gotoxy(unsigned char x, unsigned char y)
{
  if (x > SCREEN_WIDTH) x = SCREEN_WIDTH - 1;
  if (y > SCREEN_HEIGHT) y = SCREEN_HEIGHT - 1;
  UCHAR_VAR(screen_x) = x;
  UCHAR_VAR(screen_y) = y;
}

void NOINLINE scroll_up(void)
{
  void *srcptr, *destptr;

  destptr = (srcptr = VIDEO_BUFFER_PTR) + SCREEN_WIDTH*2;
  memcpy(destptr, srcptr, (SCREEN_HEIGHT - 1)*SCREEN_WIDTH*2);
  memsetw(VIDEO_PTR(0,24), ((unsigned short)UCHAR_VAR(screen_attrib) << 8) | ' ', SCREEN_WIDTH);
}

/* Não são necessarias para o boot! */
#if 0
void USEREGS settext_attribute(unsigned char attrib)
{
  UCHAR_VAR(screen_attrib) = attrib;
}

unsigned char NOINLINE gettext_attribute(void)
{
  return UCHAR_VAR(screen_attrib);
}

void NOINLINE clearscreen(void)
{
  memsetw(VIDEO_BUFFER_PTR, 
          ((unsigned short)UCHAR_VAR(screen_attrib) << 8) | ' ', 
          SCREEN_WIDTH*SCREEN_HEIGHT);
  gotoxy(0,0);
}
#endif

void USEREGS putch(unsigned char c)
{
  unsigned char sx, sy;

  sx = UCHAR_VAR(screen_x);
  sy = UCHAR_VAR(screen_y);
  switch (c)
  {
    case '\r':
    test_scroll:
      if (++sy >= SCREEN_HEIGHT)
      {
        scroll_up();
        gotoxy(sx, sy = SCREEN_HEIGHT - 1);
      }
      break;

    case '\n':
      gotoxy(sx = 0, sy);
      break;

    default:
     *((unsigned short *)VIDEO_PTR(sx++, sy)) = 
          ((unsigned short)UCHAR_VAR(screen_attrib) << 8) | c;
     if (sx >= SCREEN_WIDTH)
     {
      sx = 0;
      goto test_scroll;
     }
  }

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

static unsigned short USEREGS select_hdc(unsigned char drive_no)
{
  if (drive_no >= 0x80)
  {
    register unsigned short port;

    if ((drive_no >> 1) & 1)
      return HDC1_BASE_PORT;
    return HDC0_BASE_PORT;
  }

  return 0;
}

/* --- Isso está certo? */
#define CHS2LBA(c,h,s,nheads,nsectors) (((c)*(nheads)+(h)) * (nsectors) + ((s) - 1))

/* Lê setores usando LBA28. 
 * Retorna EAX=0 se ok, caso contrário, erro! */
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
  
  outportb(HDC_DRIVE_HEAD_PORT(port), 
      inportb(HDC_DRIVE_HEAD_PORT(port)) | 
        0xe0                             | /* Os 3 bits superiores usam LBA. */
        ((drive_no & 1) << 4)            | /* Seleciona o HD da controladora. */
        ((lba >> 24) & 0x0f));             /* Os 4 bits inferiores nos dão a "cabeça". */

  outportb(HDC_SECTOR_COUNT_PORT(port), sectors);
  outportb(HDC_SECTOR_PORT(port), lba);
  outportb(HDC_CYLINDER_LOW_PORT(port), lba >> 8);
  outportb(HDC_CYLINDER_HI_PORT(port), lba >> 16);

  /* Envia comando para a controladora. */
  outportb(HDC_COMMAND_PORT(port), HDD_CMD_READRETRY);

  /* Espera até estar pronto. */
  while ((inportb(HDC_STATUS_PORT(port)) & 0x08) == 0);

  /* Lê o bloco de dados para o buffer. */
  __asm__ __volatile__ (
    "rep; insw"
    : 
    : "c" (buffer_size / 2), "d" (HDC_DATA_PORT(port)), "D" (buffer) 
    : "memory"
      );

  return 0;
}
