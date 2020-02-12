    OUTPUT  "out/hextest.bin"

    org $9000

    include "vdpbios.inc"
    include "rc2014.inc"

START:
    ld		de,HelloWorld
	ld		c,B_STROUT
	DoBIOS

    di

    ld      c,VDP_Reset
    DoVDPBIOS
    ld      c,VDP_GoTextMode
    DoVDPBIOS
	
	ld		a,5
	ld		e,5
    ld      c,VDP_SetTextPosition
    DoVDPBIOS
	ld		hl,strBanner1
	ld      c,VDP_StringOut
    DoVDPBIOS

	ld		a,9
	ld		e,6
    ld      c,VDP_SetTextPosition
    DoVDPBIOS
	ld		hl,strBanner2
	ld      c,VDP_StringOut
    DoVDPBIOS

	ld		a,0
	ld		e,20
    ld      c,VDP_SetTextPosition
    DoVDPBIOS
	ld		hl,strBanner3
	ld      c,VDP_StringOut
    DoVDPBIOS

    ld		a,10
	ld		e,22
    ld      c,VDP_SetTextPosition
    DoVDPBIOS
	ld		hl,strBanner4
	ld      c,VDP_StringOut
    DoVDPBIOS

    ; ld      c,VDP_Reset
    ; DoVDPBIOS
    ; ld      c,VDP_GoBitmapMode
    ; DoVDPBIOS

    ; ; Set address...
    ; ld      b,16
    ; ld      c,$20
    ; call    VDP_GetPixelAddress
    ; ld      c,VDP_SetVRAMAddress
    ; DoVDPBIOS
    ; ; Draw a vertical strip...
    ; ld      b,8
    ; ld      a,%11110000
    ; call    VDP_DrawVerticalStrip
    ; ; Set address...
    ; ld      b,24
    ; ld      c,$20
    ; call    VDP_GetPixelAddress
    ; ld      c,VDP_SetVRAMAddress
    ; DoVDPBIOS
    ; ; Draw a vertical strip...
    ; ld      b,8
    ; ld      a,%11110000
    ; call    VDP_DrawVerticalStrip
    ; ; Set address...
    ; ld      b,32
    ; ld      c,$20
    ; call    VDP_GetPixelAddress
    ; ld      c,VDP_SetVRAMAddress
    ; DoVDPBIOS
    ; ; Draw a vertical strip...
    ; ld      b,8
    ; ld      a,%11110000
    ; call    VDP_DrawVerticalStrip

    ei

    ret

;;;;;;;;;;;;;;;;

VDP_DrawVerticalStrip:
    ; Graphics II mode vertical strip.
    ; VRAM address should be set before calling this function.
    ; Inputs:
    ; A - pixel mask to use
    ; B - height
    out     (VDP_PORT_VRAM),a
    VRAMWait
    djnz    VDP_DrawVerticalStrip
    ret

VDP_GetPixelAddress:
        ld      a, b                    ; d = (y / 8)
        rrca
        rrca
        rrca
        and     1fh
        ld      d, a

        ld      a, c                    ; e = (x & f8)
        and     0f8h
        ld      e, a

        ld      a, b                    ; e += (y & 7)
        and     7
        or      e
        ld      e, a
        ret

VDP_B_StringOut:
    ld      a, (hl)                 ; get the current byte from ram
    cp      0                       ; return when NULL is encountered
    ret     z
    out     (VDP_PORT_VRAM), a             ; send it to vram
    defs    14/tmswait, 0         ; nops to waste time
    inc     hl                      ; next byte
    jr      VDP_B_StringOut

strBanner1:
	dz	"Procyon/80 ROM BIOS and Monitor"

strBanner2:
	dz	"Software by LuigiThirty"

strBanner3:
	dz	"Revision 02/12/1979"

strBanner4:
	dz	"here, it's always 1979"

HelloWorld:
	db	    "TMS9918 ASCII Thingy",13,10,0

BannerData:
    db      "****************************************"
    db      "* P R O C Y O N / 8 0    M O N I T O R *"
    db      "*                                      *"
    db      "*  Official Operating System of 1979!  *"
    db      "*                                      *"
    db      "*      VDP Routine Test Program 1      *"
    db      "****************************************"
    db      0
