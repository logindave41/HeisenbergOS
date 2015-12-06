# Regra para criação do loader... Crio o mbr.lst para ver o código gerado!
mbr.bin: mbr.asm
	nasm -f bin -o $@ $< -l mbr.lst

.PHONY: clean
clean:
	rm *.lst *.bin
