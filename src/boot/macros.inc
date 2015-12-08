%ifndef __MACROS_INCLUDED__
%define __MACROS_INCLUDED__

; Usado para calcular um endereço linear, em modo protegido.
%define _PTR(x) ((x) + (_MBRSEG << 4))

; Monta uma entrada na GDT.
; Parâmetros: BASE[31:0], LIMIT[19:0], ATTRIB[11:0]
%macro GDT_ENTRY 3
  dw  %2 & 0xffff
  dw  %1 & 0xffff
  db  (%1 >> 16) & 0xff
  dw  (%3 & 0xff) | ((%2 >> 8) & 0x0f00) | ((%3 << 4) & 0xf000)
  db  (%1 >> 24) & 0xff
%endmacro

%endif
