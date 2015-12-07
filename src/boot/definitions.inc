;-----------------------
; Estes são os segmentos, em modo real, usados pelo bootloader.
;-----------------------
%define _BOOTSEG  0x07c0
%define _MBRSEG   0x0060
%define _STKSEG   0x9000

%define _CODE32SEG 0x08
%define _DATA32SEG 0x10

%define _KERNEL_BASE_ADDRESS 0x100000

%define _PTR(x) ((x) + (_MBRSEG << 4))
