; mbr.asm
bits 16

%define _BOOTSEG  0x07c0

_mbr_start:
  jmp   _BOOTSEG:boot_start

boot_start:
  hlt

  times 510 - ($ - $$) db 0
magic:
  db  0x55, 0xaa
