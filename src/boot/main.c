/* ATENÇÂO: NENHUMA rotina da libc ou outras libs podem ser usadas! */
#include "defines.h"

int main(void) 
{ 
  /* Ao chegar nesse ponto estamos no modo protegido! */

  /* Lê o arquivo do kernel para o enderço KERNEL_ADDR */
  /* Neste ponto teremos que lidar com a estrutura do filesystem. */

  /* Informa ao loader que não houveram erros. */ 
  return 0;
}
