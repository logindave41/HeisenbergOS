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

  _bss_start = .;
  .bss : { *(.bss) }
  _bss_end = .;

  /DISCARD/ : { 
    *(.comment) 
    *(.eh_frame) 
    *(.text.unlikely)
    *(.text.startup)
  }
}
