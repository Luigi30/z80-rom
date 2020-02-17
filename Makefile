SJASM 	= ../sjasm/sjasm.exe
PYTHON	= python
BIN2HEX = ./bin2hex.py

monitor: z80bios.rom atatest.hex

z80bios.rom: z80bios.asm rc2014.asm rc2014.inc strings.asm commands/memory.asm commands/go.asm commands/upload.asm
	$(SJASM) z80bios.asm

atatest.hex: testprogs/atatest.asm
	$(SJASM) testprogs/atatest.asm
	$(BIN2HEX) testprogs/out/atatest.bin testprogs/out/atatest.hex

clean:
	-rm z80bios.rom hextest.hex testprogs/out/*
