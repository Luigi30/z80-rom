test: test.rom

test.rom: test.asm
	zasm test.asm -o test.rom

clean:
	rm test.rom
