%ifndef __DEFINITIONS_INCLUDED__
%define __DEFINITIONS_INCLUDED__

;-----------------------
; Estes são os segmentos, em modo real, usados pelo bootloader.
;-----------------------
%define _BOOTSEG  0x07c0
%define _MBRSEG   0x0060
%define _STKSEG   0x9000

%define _STK16PTR 0xbffc
%define _STK32PTR 0x9bffc

; Índice 1, GDT e RPL=0
%define _CODE32SEG 0b00001000

; Índice 2, GDT e RPL=0
%define _DATA32SEG 0b00010000

; Índice 3, GDT e RPL=0 (G=0)
%define _TSSSEG   0b00011000

%define _KERNEL_BASE_ADDRESS 0x100000

; TSS tem 104 bytes + 32 bytes de I/O map.
%define TSS_LENGTH  (104+32)

%endif
