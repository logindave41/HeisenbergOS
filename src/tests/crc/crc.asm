bits 32

section .text

global crc_asm
crc_asm:
  xor   ax,ax
  xor   dx,dx
.calc_crc_loop:
  cmp   esi,0
  jbe   .calc_crc_end
  mov   al,[edi]
  add   dx,ax
  adc   dx,0
  inc   edi
  dec   esi
  jmp   .calc_crc_loop  
.calc_crc_end:
  not   ax
  ret

