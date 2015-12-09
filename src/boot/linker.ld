OUTPUT_FORMAT(binary)
OUTPUT_ARCH(i386)

SECTIONS {
  . = 0;
  .btext : { *(.btext) }
  .bdata : { *(.bdata) }
  . = 510;
  .brodata : { *(.brodata) SHORT(0xaa55) }
  _loader_start = .;
  .ltext : { *(.ltext) }
  .ldata : { *(.ldata) }
  . = ALIGN(16);
  .text  : { *(.text) }
  .data  : { *(.data) }
  .rodata : { *(.rodata) }
  _end = .;

  /* Só está aqui para colocar o símbolo _cksum no final do setor. */
  .unused : { 
    *(.unused)
    . += (510 - (. % 512));
    _cksum = .;
    SHORT(0xffff)
  }

  _bss_start = .;
  .bss : { *(.bss) }
  _bss_end = .;
}
