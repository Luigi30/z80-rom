VDP_PORT_VRAM  = $98
VDP_PORT_REGS  = $99

; Command bits
VDP_VRAM_WRITE  = $40
VDP_REG_WRITE   = $80

tmswait:        equ 4      ; wait divisor

_VDPClearPixel:  equ $A02F ; cpl, and b
_VDPSetPixel:    equ $00B0 ; nop, or b

; Function table names.
VDP_Reset                   equ 0
VDP_GoTextMode              equ 1
VDP_GoGraphics1             equ 2
VDP_GoGraphics2             equ 3
VDP_SetVRAMWriteAddress     equ 4
VDP_SetRegistersFromArray   equ 5
VDP_SetRegister             equ 6
VDP_VRAMBlockCopy           equ 7
VDP_StringOut               equ 8
VDP_SetTextPosition         equ 9
VDP_GoBitmapMode            equ 10
VDP_GetPixelAddress         equ 11
VDP_SetVRAMReadAddress      equ 12

VDP_JUMPTABLE_PUBLIC = $F000

MACRO	VDPBIOS cmd
    call    (VDP_JUMPTABLE_PUBLIC+(3*cmd))
ENDMACRO

MACRO   VRAMWait
        defs    14/tmswait, 0         ; nops to waste time
ENDMACRO