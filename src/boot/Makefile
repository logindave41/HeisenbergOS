# Regra para criação do loader... Crio o mbr.lst para ver o código gerado!
../../bin/mbr.bin: mbr.asm loader.asm
	nasm -f bin -o $@ mbr.asm -l mbr.lst

.PHONY: clean
clean:
	rm *.lst
