; Este é o código que começa a inicialização da carga do kernel...
bits 16

;------------------------
; Neste ponto temos certeza que DS=CS=0x0060 e a pilha está no topo da memória RAM baixa...
;------------------------

;------------------------
; Liga e verifica o sinal gateA20.
;------------------------
enableA20:
  ; Tenta usar a BIOS:
  mov ax,0x2401
  int 0x15
  jnc testA20

  ; Se não conseguiu, tenta usar o método "fast".
  in  al,0x92
  or  al,2
  out 0x92,al

;--------------------------
; Testa se o gateA20 foi habilitado.
;--------------------------
testA20:
  push  ds

  xor   ax,ax
  mov   ds,ax
  dec   ax
  mov   es,ax

  mov   si,0x510
  mov   di,0x520

  ; Salva os valores obtidos nos segmentos.
  mov   bl,[si]
  mov   bh,[es:di]

  mov   byte [si],0
  mov   byte [es:di],0xff

  cmp   byte [si],0
  ; ZF=1 se gateA20 estiver funcionando!

  ; Recupera os valores originais.
  mov   [es:di],bh
  mov   [si],bl

  pop   ds
  jnz   error_enabling_a20

  hlt     ; temporário, enquanto não codifico coisa alguma, ainda...

error_enabling_a20:
  mov   si,error_enabling_a20_str
  call  puts
  hlt
error_enabling_a20_str:
  db    "Error enabling gate A20!", 13, 10, 0

;------------------------
; Aqui começa a inicialização do modo protegido.
; Nosso trabalho aqui é deixar o ambiente pronto para a carga do kernel
; à partir do endereço físico 0x100000 (logo acima do primeiro megabyte de memória).
; Mas é só o começo... o ambiente vai ser ajustado mesmo é pelo código do kernel!
; A partir deste ponto não podemos usar quaisquer rotinas da BIOS!
;------------------------
bits 32
