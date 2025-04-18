all: caesar-cipher

caesar-cipher.o: ./caesar-cipher.asm
	nasm -f elf64 -o $@ $^

caesar-cipher: caesar-cipher.o
	ld -m elf_x86_64 -o $@ $^

clean:
	rm -f *.o caesar-cipher

test: caesar-cipher
	./caesar-cipher 1 "abcABC"

.PHONY: clean test
