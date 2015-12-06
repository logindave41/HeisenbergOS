; mbr.asm
bits 16

%define _BOOTSEG  0x07c0
%define _MBRSEG   0x0060
%define _STKSEG   0x9000

;----------------------------
; Quando a BIOS carrega a MBR ela o coloca no endereço 0x0000:0x7c00.
; Note que o segmento é 0... Isso permite que o código acesso a área
; da BIOS sem muito esforço, no entanto, causa alguns problema para nós...
;
; O "segmento" de todo programa ASM standalone, que não é especificado
; no script do linker, começa sempre no endereço 0, não em 0x7c00. Assim,
; é mais fácil "normalizar" o endereço do boot para 0x07c0:0... É isso
; que o "far jump" abaixo faz.
;-----------------------------
_mbr_start:
  jmp   _BOOTSEG:boot_start

;-----------------------------
; Região de dados
;-----------------------------
loading_str:    db    "Loading Heisenberg OS...",13,10,0

boot_start:
  mov   ax,cs
  mov   ds,ax         ; Ajusta DS para acessar os mesmos dados deste segmento.

  ; É interessante inicializar uma pilha aqui porque
  ; não sabemos onde a pilha da BIOS está. Coloquei a nossa
  ; pilha (de apenas 2 kB) no final da memória RAM convencional.
  cli                 ; desabilita interrupções.
  mov   ax,_STKSEG
  mov   ss,ax
  mov   sp,0xfffc     ; SS:SP = 0x9fffc, pouco antes da memória de vídeo.
  sti                 ; habilita interrupções.

;----------------------------
; MBR é apenas um "pré-boot". Ele carregará o boot do sistema
; operacional (apenas 1 setor) que, por sua vez, carregará setores
; adicionais (que lidarão com o sistema de arquivos usados no SO).
; Aqui, lidamos apenas com a MBR... Que existe apenas em HDs.
;
; Assim, copiamos todo o setor para uma região mais baixa da memória
; para carregarmos o setor de boot na mesma posição onde este código se encontra.
; Escolhi o endereço físico 0x00600 (0x0060:0x0000) para isso.
;----------------------------
  cld
  mov   ax,_MBRSEG
  mov   es,ax
  xor   si,si
  mov   di,si
  mov   cx,256
  rep   movsw
  jmp   _MBRSEG:mbr_real_start

mbr_real_start:
  mov   ds,ax       ; Ajusta DS.

  ; Mostra a string "Loading Heisenberg OS...".
  mov   si,loading_str
  call  puts

  ;--- continua aqui ---
  hlt

;----------------------------
; Rotina auxiliar em modo real, usando a BIOS.
; puts
;   Entrada: DS:SI = ponteiro para a string
;----------------------------
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
; OBS: Temos que ter um espaço aqui para a
;      tabela de partição!
;----------------------------

;----------------------------
; O setor de boot tem que sempre termiar com os bytes 0x55 e 0xAA
; senão a BIOS não carregarã esse setor.
;
; O preenchimento do final do arquivo com zeros até a posição 510
; nos garante que esses dois bytes serão sempre colocados no final
; do setor (que tem 512 bytes) e também servem para nos dizer se
; nossos códigos e dados consumiram mais que os 510 bytes permitidos.
;----------------------------
  times 510 - ($ - $$) db 0
magic:
  db  0x55, 0xaa
