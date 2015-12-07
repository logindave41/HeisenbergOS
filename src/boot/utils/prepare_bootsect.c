/* Programinha simples para escrever valores e validar o loader. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>

static char *buffer;
static long signature = 0x0B16B00B5;

char *find_signature(char *, size_t);

int main(int argc, char *argv[])
{
  unsigned short checksum;
  int cylinder, head, sector;
  long fsz;
  jmp_buf jb;
  FILE *f;
  unsigned char *p, *q;

  if (argc != 2)
  {
    puts("Usage: prepare_bootsect");
    return 1;
  }

  if ((f = fopen(argv[1], "rb")) == NULL)
  {
    perror("Error opening the file");
    return 1;
  }

  /* Tratamento de erro. */
  switch (setjmp(jb))
  {
    case 2:
      free(buffer);
    case 1:
      perror("Error");
      fclose(f);
      return 1;
  }

  /* Ok, o loader é pequeno o suficiente para que o coloquemos todo na memória! */
  fseek(f, 0L, SEEK_END);
  fsz = ftell(f);
  fseek(f, 0L, SEEK_SET);
  if ((buffer = malloc(fsz)) == NULL)
    longjmp(jb, 1);
  if (fread(buffer, fsz, 1, f) != 1)
    longjmp(jb, 2);
  fclose(f);
  
  /* Registra um tratador de erro para limpar o buffer! */
  if (setjmp(jb) == 1)
  {
    free(buffer);
    return 1;
  }

  /* Pergunta para o usuário o número do cilindro, cabeça e setor onde a MBR e o loader
     serão coloados. */
  printf("Cylinder: "); fflush(stdout);
  if (scanf("%d", &cylinder) != 1) { puts("Invalid cylinder value."); longjmp(jb, 1); }
  if (cylinder < 0 || cylinder > 1023) { puts("Cylinder must be between 0 and 1023!"); longjmp(jb, 1); }

  printf("Head: "); fflush(stdout);
  if (scanf("%d", &head) != 1) { puts("Invalid head value."); longjmp(jb, 1); }
  if (head < 0 || head > 255) { puts("Head must be between 0 and 255!"); longjmp(jb, 1); }

  printf("Sector: "); fflush(stdout);
  if (scanf("%d", &head) != 1) { puts("Invalid sector value."); longjmp(jb, 1); }
  if (head < 0 || head > 63) { puts("Sector must be between 0 and 63!"); longjmp(jb, 1); }

  /* Encontra a assinatura na imagem binária. */
  if ((p = find_signature(buffer, fsz)) == NULL)
  {
    puts("Signature not found!");
    longjmp(jb, 1);
  }
  p += sizeof(unsigned int);
  *(unsigned short *)p = cylinder;  p += sizeof(unsigned short);
  *p++ = head;
  *p = sector;

  /* Calcula Checksum do bloco do loader */
  p = &buffer[512]; q = buffer + fsz - 2;
  checksum = 0;
  while (p < q)
    checksum += *p++;
  /* leva em conta os carry's. */
  if (checksum >> 16)
    checksum = (checksum & 0xffff) + (checksum >> 16);
  *(unsigned short *)q = checksum;

  /* Abre o arquivo, de novo, e escreve o buffer inteiro lá! */
  if ((f = fopen(argv[1], "wb")) == NULL)
  {
    perror("Erro ao abrir arquivo para escrita");
    longjmp(jb, 1);
  }

  if (fwrite(buffer, fsz, 1, f) != 1)
  {
    perror("Erro ao escrever no arquivo");
    fclose(f);
    longjmp(jb, 1);
  }

  fclose(f);

  return 0;
}

char *find_signature(char *buffer, size_t size)
{
  while (size--)
  {
    if (memcmp(buffer, (void *)&signature, sizeof(unsigned int)) == 0)
      return buffer;
    buffer++;
  }

  return NULL;
}

