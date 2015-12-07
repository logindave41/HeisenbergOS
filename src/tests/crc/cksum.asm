bits 64 

section .text

global cksum_asm

; short cksum_asm(char *, size_t);
cksum_asm:
  cld
  xor   ax,ax
  xor   dx,dx
  xchg  rsi,rdi   ; ESI ptr, EDI size.
  test  rdi,rdi
.calc_cksum_loop:
  jz    .calc_cksum_end
  lodsb
  add   dx,ax
  adc   dx,0
  dec   rdi
  jmp   .calc_cksum_loop  
.calc_cksum_end:
  mov   ax,dx
  not   ax
  ret

