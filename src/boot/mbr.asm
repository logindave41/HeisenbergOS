; mbr.asm
;
; Este é o setor de boot (Master Boot Record), que não considera
; A tabela de partição. Se o SO for implementado em um HD é
; interessante usar um boot manager...
;
; A idéia aqui é carregar o "loader" que pulará para o modo protegido
; e carregará o kernel na memória alta (0x100000). O modo protegido
; aqui é ajustado de uma maneira mínima, sem paginação, sem considerar
; tratamento de interrupções..
;
; A primeira parte contém código em 16 bits, que pode usar a BIOS.
; Os "segmentos" .text e .data contém código em 32 bits, que são executados
; em modo protegido e estão contidos no arquivo loader.asm.
;
bits 16

%include "definitions.inc"

;===================
section .bdata

          ; Temos essa assinatura aqui porque alguns valores serão
          ; preenchidos por um utilitário externo. Precisamos dela
          ; para localizar esses valores no arquivo binário...
          dd  0x0B16B00B5   ; Ahhh "peitões"! :)

          ; Os números do cilindro, cabeça e setor serão colocados
          ; nessas posições por um utilitário externo.
cylinder: dw  0     ; valor default, preenchido depois.
head:     db  0     ; valor default, preenchido depois.
sector:   db  1     ; valor default, preenchido depois.

drive_no: db  0x80  ; Drive default é o primeiro HD, mas isso será
                    ; fornecido pela BIOS durante o boot!

          ; Nosso loader tem tamanho de múltiplo exato de 512 bytes!
          ; Com isso, precisamos apenas calclar o número de setores gastos.
          ; É complicado calcular isso em tempo de compilação, então deixo
          ; para o código fazê-lo.
num_sectors_after_mbr:  db  0

          ; Strings...
loading_str:            db  "Loading Heisenberg OS...",13,10,0
disk_read_error_str:    db  "Error reading loader. System halted!", 13, 10, 0

section .btext 

; Símbolos definidos pelo linker ou pelo loader.asm.
extern _loader_start
extern _end
extern loader
extern _cksum
extern _bss_start
extern _bss_end

;----------------------------
; Quando a BIOS carrega a MBR ela o coloca no endereço 0x0000:0x7c00.
; Note que o segmento é 0... Isso permite que o código acesse a área
; da BIOS (0x0040:0) sem muito esforço, no entanto, causa alguns problema para 
; nós...
;
; O "segmento" ".bstext" é o primeiro colocado no arquivo binário, de acordo
; com o script do linker. E o "endereço virtual" desse segmento é 0.
; Assim, faço um ljmp para que CS contenha 0x07c0.
;-----------------------------
_start:
  jmp   _BOOTSEG:boot_start

boot_start:
  ; Ajusta o seletor DS.
  ; Faço DS ser o mesmo que CS para facilitar o acesso aos dados.
  mov   ax,cs
  mov   ds,ax

  ; É interessante inicializar uma pilha aqui porque
  ; não sabemos onde a pilha da BIOS está. Coloquei a nossa
  ; pilha no final da memória RAM convencional, em 0x9fffc.
  ; Eu poderia simplesmente zerar SP, mas prefiro garantir que
  ; SP esteja garantidamente no topo da memória RAM baixa e alinhado
  ; por WORD.
  cli                 ; desabilita interrupções.
  mov   ax,_STKSEG
  mov   ss,ax
  mov   sp,_STK16PTR  ; SS:SP = 0x9fffc, pouco antes da memória de vídeo.
  sti                 ; habilita interrupções.

;----------------------------
; MBR é apenas um "pré-boot". A BIOS carrega apenas esse setor
; que, por sua vez, carregará setores adicionais (que lidarão 
; com o sistema de arquivos usados no SO). Assim, copiamos todo o setor para uma
; região mais baixa da memória (0x00600) para carregarmos o loader logo após,
; a partir do endereço 0x00800. 
;
; O motivo da escolha do endereço 0x00600 é que esta é a posição logo acima
; da área de dados da BIOS.
;
; Note que todo esse código não pode ultrapassar uns 8 kB se você pretende
; que ele funcione num diskete de 1.44 MB (18 setores por trilha).
;----------------------------
  cld                           ; Certifica-se que SI ou DI sejam incrementados.
                                ; nas instruções de bloco.
  mov   ax,_MBRSEG
  mov   es,ax
  xor   esi,esi
  mov   edi,esi
  mov   ecx,128
  rep   movsd
  jmp   _MBRSEG:mbr_real_start  ; Salta para a nova cópia.

mbr_real_start:
  mov   ds,ax       ; Ajusta DS.

  ; Armazena o drive informado pela BIOS.
  mov   [drive_no],dl

  ; Calcula o número de setores do loader.
  mov   ax,_end
  sub   ax,_loader_start
  cwd
  mov   bx,512
  div   bx
  or    dx,dx
  jz    .no_more_sectors
  inc   ax
.no_more_sectors:
  mov   [num_sectors_after_mbr],al
  
  ; Mostra a string "Loading Heisenberg OS...".
  mov   si,loading_str
  call  puts

  ; Usa a BIOS para carregar o loader...
  ; É necessário adequar o valor de CX em conformidade com INT 0x13/AH=2.
  mov   ax,ds
  mov   es,ax                       ; Ajusta ES.
  mov   bx,_loader_start
  call  chs_cylinder_sector_encode
  mov   al,[num_sectors_after_mbr]
  mov   dh,[head]
  mov   dl,[drive_no]
  int   0x13
  jnc   disk_read_ok                ; Se não houveram erros...

  ; Houve um erro, mostra mensagem e paraliza o processador.
  ; OBS: A especificação da INT 0x19 nos diz que podemos fazer um
  ; retorno "far", deixando a BIOS decidir se tenta bootar pelo próximo
  ; dispositivo. Escolhi não permitir isso!
error_loading_loader:
  mov   si,disk_read_error_str
  call  puts

  ; Pára tudo e deixa parado (mesmo se ouver uma interrupção!).
  ; Note que exportei o símbolo halt, que também é usado pelo loader.asm.
global  halt
halt:
  cli           ; Desabilita interrupções.
  hlt
  jmp   halt    ; Isto é apenas uma precaução... HLT "pára" o processador,
                ; mas uma interrupção NMI pode tirá-lo desse estado de
                ; "sonolência"... Não quero ter que mascarar NMIs aqui, agora.

  ; Se conseguiu ler os outros setores, testa o checksum...
disk_read_ok:
;--- código retirado provisóriamente.
;  mov   si,_loader_start
;  mov   cx,_end
;  sub   cx,si
;  call  calc_cksum
;  and   ax,[_cksum]
;  jnz   error_loading_loader      ; Se o checksum está errado, pára tudo!
;----

  ; Zera todo o segmento .bss
  mov   di,_bss_start
  xor   al,al
  mov   cx,_bss_end
  sub   cx,di
  rep   stosb

  ; E, finalmente, salta para o loader.
  jmp   loader                    

;----------------------------
; Rotina auxiliar em modo real, usando a BIOS.
; puts
;   Entrada: DS:SI = ponteiro para a string
;----------------------------
global puts         ; usaremos puts no loader também, exporto o endereço
                    ; para o linker por causa disso!
puts:
  lodsb
  or    al,al     ; obteve 0?
  jz    .puts_end
  mov   ah,0x0e
  int   0x10
  jmp   puts
.puts_end:
  ret
  
;----------------------------
; Rotina auxiliar: Monta, em CX o par cilindro/sector, como
; exigido pela INT 0x13/AH=2:
; Entrada: <nenhuma>
; Saída: CX
; Destrói AL.
;----------------------------
chs_cylinder_sector_encode:
  mov   cx,[cylinder]
  and   cx,0x3ff          ; Zera bits superiores de CX.
  rol   cx,8              ; CL contém parte superior e CH a inferior.
  rol   cl,6              ; Coloca os 2 bits superiores do cilindro na parte 
                          ; superior de CL.
  mov   al,[sector]
  and   al,0x1f           ; Zera a parte superior do setor.
  or    cl,al             ; mistura CL com AL.
  ret

;--- código retirado provisóriamente.
;;-----------------------------
;; Calcula o checksum de um bloco e retorna o inverso dele.
;; Entrada: DS:SI aponta para o início do bloco.
;;          CX tem o tamanho do bloco.
;; Saída: AX
;; Destrói CX e DX.
;;-----------------------------
;calc_cksum:
;  xor   ax,ax
;  xor   dx,dx
;.loop:
;  lodsb
;  add   dx,ax
;  adc   dx,0
;  dec   cx
;  jnz   .loop
;  not   dx
;  mov   ax,dx
;  ret

