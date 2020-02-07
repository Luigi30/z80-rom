SJASM 	= ../sjasm/sjasm.exe
PYTHON	= python
BIN2HEX = ./bin2hex.py

test: test.rom hextest.hex

test.rom: test.asm rc2014.asm strings.asm bios.inc commands/memory.asm commands/go.asm commands/upload.asm
#	zasm test.asm -u -o test.rom
	$(SJASM) test.asm

hextest.hex: hextest.asm
#	zasm hextest.asm -x -o hextest.hex
	$(SJASM) hextest.asm
	$(BIN2HEX) out/hextest.bin out/hextest.hex

clean:
	-rm test.rom hextest.hex
