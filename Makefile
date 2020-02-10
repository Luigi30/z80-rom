SJASM 	= ../sjasm/sjasm.exe
PYTHON	= python
BIN2HEX = ./bin2hex.py

monitor: z80bios.rom hextest.hex

z80bios.rom: z80bios.asm rc2014.asm strings.asm bios.inc commands/memory.asm commands/go.asm commands/upload.asm
	$(SJASM) z80bios.asm

hextest.hex: hextest.asm
	$(SJASM) hextest.asm
	$(BIN2HEX) out/hextest.bin out/hextest.hex

clean:
	-rm z80bios.rom hextest.hex
