    OUTPUT  "out/hextest.bin"

    org $9000

    include "bios.inc"

VDP_DATA    = $BE
VDP_STATUS  = $BF
VDP_REGS    = $BF

; Command bits
VDP_VRAM_WRITE  = $40
VDP_REG_WRITE   = $80

START:
    ld		de,HelloWorld
	ld		c,B_STROUT
	DoBIOS

    di

    ; Reset the VDP
    call VDP_Reset

    ei
    ret

HelloWorld:
	db	    "TMS9918 ASCII Thingy",13,10,0,1

VDP_SetRegister:
    ; A is the value
    ; E is the register number

    ; ld      hl,VDP_ShadowRegs
    ; ld      d,0
    ; add     hl,de   ; Add offset to shadow register.
    ; ld      (hl),a  ; Update shadow value.
    ; out     (VDP_REGS),a    ; send a byte of data
    ; ld      a,VDP_REG_WRITE ; select register to write it to
    ; or      e
    ; out     (VDP_REGS),a

    out     (VDP_REGS),a
    ld      a,e
    or      $80
    out     (VDP_REGS),a

    ret

VDP_Reset:
    ld      a,0
    ld      ix,VDP_ShadowRegs
    ld      (ix+0),a
    ld      (ix+1),a
    ld      (ix+2),a
    ld      (ix+3),a
    ld      (ix+4),a
    ld      (ix+5),a
    ld      (ix+6),a
    ld      (ix+7),a

    ; TODO: Clear VRAM

    ; Set up graphics mode.
    ld      a,%00000010
    ld      e,0
    call    VDP_SetRegister
    ld      a,%11000010
    ld      e,1
    call    VDP_SetRegister
    ld      a,%00001110
    ld      e,2
    call    VDP_SetRegister
    ld      a,%11111111
    ld      e,3
    call    VDP_SetRegister
    ld      a,%00000011
    ld      e,4
    call    VDP_SetRegister
    ld      a,%01110110
    ld      e,5
    call    VDP_SetRegister
    ld      a,%00000011
    ld      e,6
    call    VDP_SetRegister
    ld      a,%00001111
    ld      e,7
    call    VDP_SetRegister

    ret

VDP_ShadowRegs: ds 8   ; 8 bytes of shadow registers

VDP_TextDefaults:
    db      %00000000               ; text mode, no external video
    db      %11010000               ; 16K, Enable Display, Disable Interrupt
    db      $00                     ; name table at $0000
    db      $00                     ; color table not used
    db      $01                     ; pattern table at $0800
    db      $00                     ; sprite attribute table not used
    db      $00                     ; sprite pattern table not used
    db      $F2                     ; white text on black background