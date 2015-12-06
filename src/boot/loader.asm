; Este é o código que começa a inicialização da carga do kernel...
bits 16

  hlt     ; temporário, enquanto não codifico coisa alguma, ainda...

;------------------------
; Aqui começa a inicialização do modo protegido.
; Nosso trabalho aqui é deixar o ambiente pronto para a carga do kernel
; à partir do endereço físico 0x100000 (logo acima do primeiro megabyte de memória).
; Mas é só o começo... o ambiente vai ser ajustado mesmo é pelo código do kernel!
; A partir deste ponto não podemos usar quaisquer rotinas da BIOS!
;------------------------
bits 32
