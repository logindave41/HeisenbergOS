; mbr.asm
;
; Embora eu tenha chamado esse arquivo de mbr.asm, ele não implementa a MBR.
; Preferi usar um boot manager como o GRUB para "bootar" a partição correta.
; Essa listagem implementa o loader do kernel.
;
bits 16

%include "definitions.inc"

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
_start:
  jmp   _BOOTSEG:boot_start

;-----------------------------
; Região de dados
;-----------------------------

                        ; Temos essa assinatura aqui porque alguns valores serão preenchidos
                        ; por um utilitário externo. Precisamos dela para localizar esses valores no
                        ; arquivo binário...
                        dd  0x0B16B00B5   ; Ahhh "peitões"! :)
cylinder:               dw  0     ; valor default, preenchido depois.
head:                   db  0     ; valor default, preenchido depois.
sector                  db  1     ; valor default, preenchido depois.

num_sectors_after_mbr:  db  1 + ((_end - loader) / 512)   ; *** Isto está correto? ***
loading_str:            db  "Loading Heisenberg OS...",13,10,0
disk_read_error_str:    db  "Error reading loader. System halted!", 13, 10, 0

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
; MBR é apenas um "pré-boot". A BIOS carrega apenas esse setor
; que, por sua vez, carregará setores adicionais (que lidarão 
; com o sistema de arquivos usados no SO).
;
; Assim, copiamos todo o setor para uma região mais baixa da memória
; para carregarmos o setor de boot na mesma posição onde este código se encontra.
; Escolhi o endereço físico 0x00600 (0x0060:0x0000) para isso.
;
; Note que todo esse código não pode ultrapassar uns 8 kB se você pretende
; que ele funcione num diskete de 1.44 MB (18 setores por trilha).
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

  ; Usa a BIOS para carregar o loader...
  mov   ax,ds
  mov   es,ax
  mov   bx,loader
  call  chs_cylinder_sector_encode
  mov   al,[num_sectors_after_mbr]
  mov   dh,[head]
  int   0x13
  jnc   disk_read_ok

  ; Se chegou aqui, teve erro de leitura...
error_loading_loader:
  mov   si,disk_read_error_str
  call  puts

  ; Pára tudo e deixa parado (mesmo se ouver uma interrupção!).
.halt:
  cli
  hlt
  jmp   .halt  

disk_read_ok:
  mov   si,loader
  mov   cx,loader_crc - loader
  call  calc_crc
  and   ax,[loader_crc]
  jnz   error_loading_loader

  jmp   loader

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
; Rotina auxiliar em modo real. Calcula o CRC de um bloco.
; Retorna o complemento do CRC para facilitar a comparação, mais tarde.
; Se fizermos um AND entre o valor retornado por essa função e o valor
; que estará contido em "loader_crc", abaixo, o valor deve ser 0.
;
; Entrada: DS:SI endereço inicial do bloco.
;          CX tamanho do bloco em bytes.
; Saída:   AX crc.
;
; Rotina equivalente em C (desconsiderando os carry-outs):
;
;   short calc_crc(char *buffer, size_t size)
;   {
;      short sum = 0;
;      while (size--)
;        sum += *buffer++;
;      return ~sum;
;   }
;----------------------------
calc_crc:
  xor   ax,ax
  xor   dx,dx
.calc_crc_loop:
  cmp   cx,0
  jbe   .calc_crc_end
  lodsb
  add   dx,ax
  adc   dx,0
  inc   si
  dec   cx
  jmp   .calc_crc_loop  
.calc_crc_end:
  not   ax
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
  rol   cl,6              ; Coloca os 2 bits superiores do cilindro na parte superior de CL.
  mov   al,[sector]
  and   al,0x1f           ; Zera a parte superior do setor.
  or    cl,al             ; mistura CL com AL.
  ret

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
;--------------------
; O codigo e dados contidos no restante dessa listagem pertencem aos
; setores adjacentes ao MBR...
;--------------------

loader:         ; Início do loader.

; Coloquei o loader num arquivo separado porque:
; 1. Um pequeno pedaço é em modo real e...
; 2. Um outro pedaço é em modo protegido.
%include "loader.asm"

loader_crc:     dw    0     ; Apenas um checksum para determinar se
                            ; o código do MBR conseguiu ler todos os setores
                            ; corretamente. Vai ser preenchido por um utilitário
                            ; externo depois...
_end:           ; Fim do loader.
