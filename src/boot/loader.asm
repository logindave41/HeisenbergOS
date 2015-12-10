;
; Este é o código que começa a inicialização da carga do kernel...

;----------------------------------
; Algumas definições e macros para facilitar nossa vida.
;----------------------------------
%include "definitions.inc"
%include "macros.inc"

bits 16

; Usados para inicializar o segmento .bss
extern _bss_start
extern _bss_end

section .bdata

error_enabling_a20_str:
  db    "Error enabling gate A20!", 13, 10, 0
error_loading_kernel_str:
  db    "Error loading kernel!", 13, 10, 0

;--------------------------
; Estruturas usadas por LGDT, LIDT.
;--------------------------
gdtptr:
  dw    gdt_end - gdt - 1 ; Tamanho da tabela (aparentemente é necessário esse 
                          ; -1 no final!).
  dd    _PTR(gdt)         ; Endereço linear da tabela.

; Por enquanto não criei ainda uma tabela de vetores interrupção!
idtptr:
  dw    0
  dd    0

;--------------------------
; Tabela de descritores globais simples.
; OBS: Tenho que verificar se a alocação em runtime dessa
;      tabela é vantajosa ou não (para reduzir o tamanho do binário!).
;--------------------------
  align 16,db 0
gdt:
  GDT_ENTRY 0,0,0               ; Null descriptor
  GDT_ENTRY 0,0xfffff,0xc9a     ; Kernel Codeseg descriptor
  GDT_ENTRY 0,0xfffff,0xc92     ; Kernel Dataseg descriptor

  ; Um TSS é necessário para a inicialização do modo protegido,
tss_entry:
  GDT_ENTRY 0,TSS_LENGTH-1,0x48b    ; Segmento pequenininho (bit de granulidade 
                                    ; desligado!). Note que este é um segmento
                                    ; de sistema (TSS Busy).
                                    ; O limite superior é o final do TSS.
gdt_end:

  ; Movi o TSS para além do segmento .bss.

section .ldata
  ; Por enquanto não tem nada aqui!

section .btext

;------------------------
; Antes de entrarmos no modo protegido precisamos ligar o
; sinal "Gate A20". 
;------------------------
enableA20:
  ; Tenta usar a BIOS (pode ser que isso só funcione no PS/2):
  ;mov ax,0x2401
  ;int 0x15
  ;jnc .testA20       ; Se conseguiu, testa!

  ; Tenta usar o modo "fast".
  in  al,0x92
  or  al,0b00000010
  out 0x92,al

  ;*** É preciso tentar habilitar usando o Keyboard Controller?!

;--------------------------
; Testa se o gateA20 foi habilitado.
;--------------------------
.testA20:
  push ds        ; Guarda DS.

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
  mov   al,byte [si]
  test  al,al
  ; Neste ponto ZF=1 se gateA20 estiver funcionando!

  ; Recupera os valores originais.
  mov   [es:di],bh
  mov   [si],bl

  jz    .ok

  ; Erro ao testar o gate A20...
  mov   si,error_enabling_a20_str
  call  puts
  jmp   halt

.ok:
  pop   ds       ; Recupera DS.

  ;-------
  ; Cria TSS no final da imagem
  ;-------
  mov   di,_bss_end   ; Alinha por 16 bytes.
  add   di,15
  and   di,0x0f      

  ; Ajusta a base do descritor da TSS:
  mov   word [tss_entry+2],di
  ; Preenche o TSS.
  xor   ax,ax
  mov   cx,52   ; 104/2.
  rep   stosw
  dec   al
  mov   cl,32
  rep   stosb

  ;---------------
  ; Desabilita as interrupções...
  ;---------------
disable_interrupts:
  cli

  mov   dx,0x70
  in    al,dx
  or    al,0b10000000
  out   dx,al         ; desabilita NMI

  ; Aproveito para mascarar as interrupções aceitáveis pelo PIC1
  mov   dx,0x21
  in    al,dx
  and   al,0b00000100         ; Exceto a IRQ2!
  out   dx,al

  ; E também pelo PIC2.
  xor   al,al
  out   0xa1,al

  ; OBS: Não guardei o estado anterior pq o kernel rehabilitará as IRQs e a NMI...
  ret

;=====================
section .ltext

; Funções externas a esse módulo.
extern main
extern puts
extern _puts  ; Protected-mode.
extern halt

; "loader" é importado pelo mbr.asm.
global loader
loader:
  call  enableA20

;------------------------
; Prepara o ambiente para entrarmos
; no modo protegido. Esse pedaço ainda é prelimiar!
;------------------------
  ; Agora podemos carregar os registradores das tabelas de descritores
  ; e o task register.
  lgdt  [gdtptr]
  lidt  [idtptr]
  ;lldt [idtptr]      ; Será necessário carregar o LDTR para uma tabela nula?
  mov   ax,_TSSSEG
  ltr   ax
  
  ; Habilita o bit PE de CR0.
  mov   eax,cr0
  or    eax,1
  mov   cr0,eax

  ; Salta para o modo protegido!
  ; Note que o seletor agora tem estrtutura diferente da do modo real!
  jmp   _CODE32SEG:_PTR(protected_mode_entry)


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

protected_mode_entry:
  ; ajusta os seletores: DS=ES=FS=GS=SS=DATA32SEG
  mov   ax,_DATA32SEG
  mov   ds,ax
  mov   es,ax
  mov   fs,ax
  mov   gs,ax
  mov   ss,ax
  mov   esp,_STK32PTR   ; Continuamos com SS:ESP apontando para uma pilha na
                        ; memória inferior! Voltei a colocar ESP em 0x9bffc!

  ; main() retorna, depois de fazer tudo o que tem que fazer...
  call  _PTR(main)
  test  eax,eax
  jz    .run_kernel

  mov   eax,_PTR(error_loading_kernel_str)
  call  _puts

.run_kernel:
  ; Salta para o código do kernel.
  push  dword _KERNEL_BASE_ADDRESS
  ret
