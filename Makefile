test: test.rom

test.rom: test.asm rc2014.asm bios.inc
	zasm test.asm -u -o test.rom

clean:
	-rm test.rom