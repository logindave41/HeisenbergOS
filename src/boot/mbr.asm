; mbr.asm
;
; Embora eu tenha chamado esse arquivo de mbr.asm, ele não implementa a MBR.
; Preferi usar um boot manager como o GRUB para "bootar" a partição correta.
; Essa listagem implementa o bootsector e o loader do kernel.
;
bits 16

%include "definitions.inc"

;----------------------------
; Quando a BIOS carrega a MBR ela o coloca no endereço 0x0000:0x7c00.
; Note que o segmento é 0... Isso permite que o código acesse a área
; da BIOS (0x0040:0) sem muito esforço, no entanto, causa alguns problema para 
; nós...
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
num_sectors_after_mbr:  db  (_end - loader) / 512

          ; Strings
loading_str:            db  "Loading Heisenberg OS...",13,10,0
disk_read_error_str:    db  "Error reading loader. System halted!", 13, 10, 0

; O código do setor de boot começa aqui!
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
  cld                           ; Certifica-se que SI ou DI sejam incrementados.
  mov   ax,_MBRSEG
  mov   es,ax
  xor   si,si
  mov   di,si
  mov   cx,256
  rep   movsw
  jmp   _MBRSEG:mbr_real_start  ; Salta para a nova cópia.

mbr_real_start:
  mov   ds,ax       ; Ajusta DS.

  mov   [drive_no],dl ; Guarda o nº do drive fornecido pela BIOS.

  ; Mostra a string "Loading Heisenberg OS...".
  mov   si,loading_str
  call  puts

  ; Usa a BIOS para carregar o loader...
  ; É necessário adequar o valor de CX...
  mov   ax,ds
  mov   es,ax
  mov   bx,loader
  call  chs_cylinder_sector_encode
  mov   al,[num_sectors_after_mbr]
  mov   dh,[head]
  ; OBS: A BIOS fornece o drive em DL!
  ;      Note que não mexemos com DL até agora!
  int   0x13
  jnc   disk_read_ok

  ; Se chegou aqui, teve erro de leitura...
error_loading_loader:
  mov   si,disk_read_error_str
  call  puts

  ; Pára tudo e deixa parado (mesmo se ouver uma interrupção!).
halt:
  cli           ; Desabilita interrupções.
  hlt
  jmp   halt    ; Isto é apenas uma precaução... HLT "pára" o processador,
                ; mas uma interrupção NMI pode tirá-lo desse estado de
                ; "sonolência"... Não quero ter que mascarar NMIs aqui, agora.

disk_read_ok:
  ; Calcula e verifica o checksum do loader.
  mov   si,loader
  mov   cx,loader_cksum - loader
  call  calc_cksum
  and   ax,[loader_cksum]
  jnz   error_loading_loader

  ; Se tudo deu certo, salta para o loader.
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
; que estará contido em "loader_cksum", abaixo, o valor deve ser 0.
;
; Entrada: DS:SI endereço inicial do bloco.
;          CX tamanho do bloco em bytes.
; Saída:   AX crc.
;
; Rotina equivalente (só que menor!) em C:
;
;   short calc_cksum(char *buffer, size_t size)
;   {
;      unsigned short sum = 0;
;
;      while (size--)
;        sum += *(unsigned char *)buffer++;
;      if (sum >> 16) sum = ((sum >> 16) + sum) & 0xffff;
;      return ~sum;
;   }
;----------------------------
calc_cksum:
  xor   ax,ax
  xor   dx,dx
  test  cx,cx
.calc_cksum_loop:
  jz   .calc_cksum_end
  lodsb
  add   dx,ax
  adc   dx,0
  dec   cx
  jmp   .calc_cksum_loop  
.calc_cksum_end:
  mov   ax,dx
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
  rol   cl,6              ; Coloca os 2 bits superiores do cilindro na parte 
                          ; superior de CL.
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
;******************************************************************************
;--------------------
; O codigo e dados contidos no restante dessa listagem pertencem aos
; setores adjacentes ao MBR...
;--------------------

loader:         ; Início do loader.

; Coloquei o loader num arquivo separado porque:
; 1. Um pequeno pedaço é em modo real e...
; 2. Um outro pedaço é em modo protegido.
%include "loader.asm"

;----------------------------
; Mesmo artifício usado para o final do setor de boot,
; Só que, agora, garante que nosso arquivo terá tamanho exato de múltiplos de 
; 512 bytes.
;----------------------------
  times 510 - (($ - $$) % 512) db 0
loader_cksum: dw    0     ; Apenas um checksum para determinar se
                          ; o código do MBR conseguiu ler todos os setores
                          ; corretamente. Vai ser preenchido por um utilitário
                          ; externo depois...

; Quero que esse loader (mais o bootsector) tenham, no máximo, 8 kB.
; Ou seja, 16 setores.
%if ($ - $$) > 8192
  %error "Loader muito grande!"
%endif
_end:           ; Fim do loader.
