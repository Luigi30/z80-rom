test: test.rom hextest.hex

test.rom: test.asm rc2014.asm strings.asm bios.inc commands/memory.asm commands/go.asm commands/upload.asm
	zasm test.asm -u -o test.rom

hextest.hex: hextest.asm
	zasm hextest.asm -x -o hextest.hex

clean:
	-rm test.rom hextest.hex
