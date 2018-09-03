CC=nasm

make: main.asm
	$(CC) -f elf32 main.asm
	gcc -m32 -o game main.o
	rm main.o
