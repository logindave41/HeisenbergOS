/* Vamos obter um arquivo binário para o kernel (depois podemos fazer um elf32) */
OUTPUT_FORMAT(binary)
OUTPUT_ARCH(i386)   /* Lembrar de compilar os códigos com -m32. */

SECTIONS {
  /* O kernel começa no endereço 0x100000 - acima do primeiro 1 MB da memória. */
  . = 0x100000;
  _start = .;             /* _start é o ponto de entrada em c0.asm */
  .text : { *(.text) }
  _etext = .;
  .data : { *(.data) }
  .rodata : { *(.rodata) }
  __bss_start = .;
  .bss : { *(.bss) }
  _end = .;               /* Com base no símbolo _end podemos alocar espaço para a pilha e heap. */

  /* Descarta segmentos desnecessários. */
  /DISCARD/ : { *(.comment) *(.eh_frame) }
}
