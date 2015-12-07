;-----------------------------------------------------------------
; Este é o código que começa a inicialização da carga do kernel...
;-----------------------------------------------------------------

; Alguns macros para facilitar nossa vida.
%include "macros.inc"

bits 16

;------------------------
; Liga e verifica o sinal gateA20.
;------------------------
enableA20:
  ; Tenta usar a BIOS:
  mov ax,0x2401
  int 0x15
  jnc testA20

  ; Se não conseguiu tenta usar o modo "fast".
  in  al,0x92
  or  al,2
  out 0x92,al

  ;*** É preciso tentar habilitar usando o Keyboard Controller?!

;--------------------------
; Testa se o gateA20 foi habilitado.
;--------------------------
testA20:
  mov   cx,ds       ; Guarda DS.

  xor   ax,ax
  mov   ds,ax
  dec   ax
  mov   es,ax

  ; Com gateA20 desligado, 0x0000:0x0510 e 0xFFFF:0x0520 
  ; apontam para o mesmo lugar!
  ; PS: 0x510 localiza-se numa área de dados da BIOS "inútil".
  mov   si,0x510
  mov   di,0x520

  ; Salva os valores contidos nos segmentos.
  mov   bl,[si]
  mov   bh,[es:di]

  ; Escreve valores conhecidos em ambos os lugares.
  mov   byte [si],0
  mov   byte [es:di],0xff

  ; Se gateA20 estiver ligdo, 0x0000:0x0510 contém 0,
  ; senão, conterá 0xff.
  cmp   byte [si],0
  ; Neste ponto ZF=1 se gateA20 estiver funcionando!

  ; Recupera os valores originais.
  mov   [es:di],bh
  mov   [si],bl

  mov   ds,cx       ; Recupera DS.

  jz    prepare_protected_mode

  ; Erro ao testar o gate A20...
  mov   si,error_enabling_a20_str
  call  puts
  jmp   halt
error_enabling_a20_str:
  db    "Error enabling gate A20!", 13, 10, 0

;------------------------
; Prepara o ambiente para entrarmos
; no modo protegido. Esse pedaço ainda é prelimiar!
;------------------------
prepare_protected_mode:
  ;*** É interessante desabilitar NMIs aqui também?
  cli
  lgdt  [gdtptr]
  lidt  [idtptr]
  ;*** É necessário carregar o Task Register com um TSS válido aqui?
  
  ; Habilita o bit PE de CR0.
  mov   eax,cr0
  or    eax,1
  mov   cr0,eax

  ; Salta para o modo protegido!
  jmp   _CODE32SEG:_PTR(protected_mode_entry)

;--------------------------
; Estruturas usadas por LGDT, LIDT (e LTR?).
;--------------------------
gdtptr:
  dw    gdt_end - gdt - 1 ; Tamanho da tabela (aparentemente é necessário esse -1 no final!).
  dd    _PTR(gdt)         ; Endereço físico da tabela.

; Por enquanto não criei ainda uma tabela de vetores interrupção!
idtptr:
  dw    0
  dd    0

;--------------------------
; Tabela de descritores globais simples.
;--------------------------
  align 16
gdt:
  GDT_ENTRY 0,0,0               ; Null descriptor
  GDT_ENTRY 0,0xfffff,0xc9a     ; Kernel Codeseg descriptor
  GDT_ENTRY 0,0xfffff,0xc92     ; Kernel Dataseg descriptor
  ;*** Possívelmente terei que colocar um TSS aqui.
gdt_end:

;******************************************************************************
;------------------------
; Aqui começa a inicialização do modo protegido.
; Nosso trabalho aqui é deixar o ambiente pronto para a carga do kernel
; à partir do endereço físico 0x100000 (logo acima do primeiro megabyte de 
; memória). Mas é só o começo... o ambiente vai ser ajustado mesmo é pelo código
; do kernel! A partir deste ponto não podemos usar quaisquer rotinas da BIOS!
;
; Graças ao salto para o modo protegido, os ponteiros agora enxergam toda a
; memória de maneira linear (até 4 GB)... Só precisamos ajustar os seletores.
;------------------------
bits 32

  align 16
protected_mode_entry:
  ; ajusta os seletores: DS=ES=FS=GS=SS=DATA32SEG
  mov   eax,_DATA32SEG
  mov   ds,ax
  mov   es,ax
  mov   fs,ax
  mov   gs,ax
  mov   ss,ax
  mov   esp,0x9fffc     ; Continuamos com SS:ESP apontando para uma pilha na
                        ; memória inferior!
  sti

  hlt   ; continua...
