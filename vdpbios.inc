VDP_PORT_VRAM  = $98
VDP_PORT_REGS  = $99

; Command bits
VDP_VRAM_WRITE  = $40
VDP_REG_WRITE   = $80

tmswait:        equ 4                   ; wait divisor

; Function table names.
VDP_Reset                   equ 0
VDP_GoTextMode              equ 1
VDP_GoGraphics1             equ 2
VDP_GoGraphics2             equ 3
VDP_SetVRAMAddress          equ 4
VDP_SetRegistersFromArray   equ 5
VDP_SetRegister             equ 6
VDP_VRAMBlockCopy           equ 7
VDP_StringOut               equ 8
VDP_SetTextPosition         equ 9
VDP_GoBitmapMode            equ 10
; VDP_GetPixelAddress         equ 11

MACRO	DoVDPBIOS	
		rst	$28
ENDMACRO

MACRO   VRAMWait
        defs    14/tmswait, 0         ; nops to waste time
ENDMACRO