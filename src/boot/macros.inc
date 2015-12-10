%ifndef __MACROS_INCLUDED__
%define __MACROS_INCLUDED__

;--------------------------------
; Macro usado para calcular o endereço linear em modo protegido.
;--------------------------------
%define _PTR(x) ((x) + (_MBRSEG << 4))

;---------------------------------
; Monta uma entrada na GDT.
; Parâmetros: BASE[31:0], LIMIT[19:0], ATTRIB[11:0]
;
; Lembre-se: O segundo parâmetro é um LIMITE, não o TAMANHO!
; Assim, uma base 0 e o limite 0xfffff faz com que o segmento começe
; em 0x00000000 e seja acessível até 0x000fffff.
;
; Quando o bit de granulidade do atributo estiver setado a unidade
; de medida do limite é em blocos de 4 kB (1 página). Assim, um limite de
; 0xfffff equivale a deslocar o limite 12 bits para a esquerda preenchendo
; os bits à direita com 1. O limite, neste caso, será 0xffffffff.
;---------------------------------
%macro GDT_ENTRY 3
  dw  (%2) & 0xffff
  dw  (%1) & 0xffff
  db  ((%1) >> 16) & 0xff
  dw  ((%3) & 0xff) | (((%2) >> 8) & 0x0f00) | (((%3) << 4) & 0xf000)
  db  ((%1) >> 24) & 0xff
%endmacro

%endif
