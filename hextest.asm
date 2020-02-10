    OUTPUT  "out/hextest.bin"

    org $9000

    include "vdpbios.inc"
    include "bios.inc"

START:
    ld		de,HelloWorld
	ld		c,B_STROUT
	DoBIOS

    di

    ld      c,VDP_Reset
    DoVDPBIOS

    ld      hl,0
    ld      c,VDP_GoTextMode
    DoVDPBIOS

    ld      de,40
    ld      c,VDP_SetVRAMAddress
    DoVDPBIOS

    ld      hl,BannerData
    call    VDP_B_StringOut

    ei

    ret

    ; di


    ; ld      de,40
    ; call    VDP_SetVRAMAddress

    ; ld      a, 0                          ; put title at (1,0)
    ; ld      e, 1
    ; call    VDP_TextPosition
    ; ld      hl,BannerData                  ; output title
    ; call    VDP_StringOut
    ; ei
    ; ret

;;;;;;;;;;;;;;;;

VDP_B_StringOut:
    ld      a, (hl)                 ; get the current byte from ram
    cp      0                       ; return when NULL is encountered
    ret     z
    out     (VDP_PORT_VRAM), a             ; send it to vram
    defs    14/tmswait, 0         ; nops to waste time
    inc     hl                      ; next byte
    jr      VDP_B_StringOut

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

VDP_DefaultRegisters:
    ; Blanking, 16KB VRAM
    db      $00, $80, $00, $00, $00, $00, $00, $00

VDP_ShadowRegs: ds 8   ; 8 bytes of shadow registers