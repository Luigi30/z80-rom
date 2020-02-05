test: test.rom

test.rom: test.asm rc2014.asm strings.asm bios.inc commands/memory.asm commands/go.asm commands/upload.asm
	zasm test.asm -u -o test.rom

clean:
	-rm test.rom
