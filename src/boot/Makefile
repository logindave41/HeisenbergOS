# Regra para criação do loader... Crio o mbr.lst para ver o código gerado!
CFLAGS=-Os -m32 -I../kernel/include -nostdlib -ffreestanding -fno-align-functions -fomit-frame-pointer
objectfiles=mbr.o loader.o main.o pmbios.o

../../bin/mbr.bin: $(objectfiles)
	ld -s -T ./linker.ld $^ -o $@

%.o: %.c
	gcc $(CFLAGS) -c -o $@ $<

%.o: %.asm
	nasm -f elf32 -o $@ $< 

.PHONY: clean
clean:
	rm *.o

distclean: clean
	rm ../../bin/mbr.bin
