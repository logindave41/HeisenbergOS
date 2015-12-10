#include <ioports.h>

#define KERNEL_ADDR   (void *)0x100000U

extern unsigned short drive_no;

void main(void) 
{ 
  /* Ao chegar nesse ponto estamos no modo protegido, com o Gate A20 ligado! */

  /* Lê o arquivo do kernel para o enderço KERNEL_ADDR */

  /* Salta para o kernel. */
  __asm__ __volatile__ ( "jmpl *%%eax" : : "a" (KERNEL_ADDR) );
}
