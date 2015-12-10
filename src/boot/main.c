#define KERNEL_ENTRY (void *)0x100000U
void main(void) 
{ 
  /* Ao chegar nesse ponto estamos no modo protegido, com o Gate A20 ligado! */

  /* Lê o arquivo do kernel para o enderço KERNEL_ADDR */
  /* Neste ponto teremos que lidar com a estrutura do filesystem. */

  /* Salta para o kernel. */
  __asm__ __volatile__ ( "jmpl *%%eax" : : "a" (KERNEL_ENTRY) );
}
