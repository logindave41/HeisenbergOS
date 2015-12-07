test: test.o cksum.o
	gcc -o $@ $^

%.o: %.c
	gcc -c -o $@ $<

%.o: %.asm
	nasm -f elf64 -o $@ $<

.PHONY: clean
clean:
	rm *.o test
