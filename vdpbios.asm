    PAGE 1
    
    include "vdpbios.inc"

VDP_B_ColdStart:
    ; Copy the table from VDP_B_FnTable to the public table in RAM.
    ld  bc,256
    ld  de,VDP_FnTable_Public
    ld  hl,VDP_B_FnTable
    ldir

    ret
    
;;; ;;;;;;;;;;;;;;;;;
;;; VDP functions
;;;
;;; API:
;;;		All VDP BIOS functions are prefixed with VDP_B_
;;; 	Input is A, BC, DE, HL
;;;		Output bytes are in A
;;;		Output words are in HL (todo: ?)
;;;
;;;		Do not assume any registers are preserved.
VDP_B_Dispatch:
	;; Dispatch to the function number C.
    ex      af
    ld      iyl,c
    exx
    ld      c,iyl
	ld		hl,VDP_FnTable_Public	; grab the jump table address
	ld		d,0		; clear D
	
	sla		c		; shift C to produce a table offset
	ld		e,c		; E <- C
	add		hl,de	; Apply the offset.

	ld		a,(hl)	; Get the destination address. 
	ld		e,a
	inc		hl
	ld		d,(hl)

	push    de
    pop     ix

    exx
    ex      af
	jp		(ix)	; Jump to the BIOS function, which RETs back to where we started.
	ret				; Unnecessary unless something breaks

; copy a null-terminated string to VRAM
;       HL = ram source address
VDP_B_StringOut:
    ld      a, (hl)                 ; get the current byte from ram
    cp      0                       ; return when NULL is encountered
    ret     z
    out     (VDP_PORT_VRAM), a             ; send it to vram
    defs    14/tmswait, 0         ; nops to waste time
    inc     hl                      ; next byte
    jr      VDP_B_StringOut

VDP_B_VRAMBlockCopy:
; copy bytes from ram to vram
;       HL = ram source address
;       DE = vram destination address
;       BC = byte count
    call    VDP_B_SetVRAMAddress      ; set the starting address
.copyloop:
    ld      a, (hl)                 ; get the current byte from ram
    out     (VDP_PORT_VRAM), a           ; send it to vram
    defs    14/tmswait, 0         ; nops to waste time
    inc     hl                      ; next byte
    dec     bc                      ; continue until count is zero
    ld      a, b
    or      c
    jr      nz, .copyloop
    ret

VDP_B_SetRegister:
    ; A is the value
    ; E is the register number

    ld      hl,VDP_ShadowRegs
    ld      d,0
    add     hl,de   ; Add offset to shadow register.
    ld      (hl),a  ; Update shadow value.
    out     (VDP_PORT_REGS),a    ; send a byte of data
    ld      a,VDP_REG_WRITE ; select register to write it to
    or      e
    out     (VDP_PORT_REGS),a

    ret

VDP_B_SetRegistersFromArray:
    ; HL is an array of registers.
    ld      de, VDP_ShadowRegs      ; start of shadow area
	ld      c, 8                    ; 8 registers
.regloop:
  	ld      a, (hl)                 ; get register value from table
	out     (VDP_PORT_REGS), a      ; send it to the TMS
	ld      a, 8                    ; calculate current register number
	sub     c
	or      VDP_REG_WRITE           ; set high bit to indicate a register
    ldi                             ; shadow, then inc pointers and dec counter
	out     (VDP_PORT_REGS), a           ; send it to the TMS
    xor     a                       ; continue until count reaches 0
    or      c
	jr      nz, .regloop
	ret

; set the next address of vram to write
;   DE = address
VDP_B_SetVRAMAddress:
    ld      a, e                    ; send lsb
    out     (VDP_PORT_REGS), a
    ld      a, d                    ; mask off msb to max of 16KB
    and     $3F
    or      $40                     ; set second highest bit to indicate write
    out     (VDP_PORT_REGS), a           ; send msb
    ret

VDP_B_Reset:
    ; Set up blank mode.
    ld      hl,VDP_DefaultRegisters
    call    VDP_B_SetRegistersFromArray

    ld      de,0
    call    VDP_B_SetVRAMAddress

    ld      de, $4000               ; write 16KB
    ld      bc, VDP_PORT_VRAM       ; writing 0s to vram
.clearloop:
    out     (c), b                  ; send to vram
    dec     de                      ; continue until counter is 0
    ld      a, d
    or      e
    jr      nz, .clearloop

    ret

VDP_B_GoTextMode:
    ld      a,0
    or      d
    or      e
    cp      0   ; If DE is 0, use the default font.
    jr      nz,.copyfont
    ld      de,VDP_ASCIIFont

.copyfont
    ex      de,hl
    push    hl                      ; save address of font
    call    VDP_B_Reset
    pop     hl                      ; load font into pattern table
    ld      de, $0800
    ld      bc, $0800
    call    VDP_B_VRAMBlockCopy
    ld      hl,VDP_Regs_Text
    call    VDP_B_SetRegistersFromArray
    ret

VDP_B_GoGraphics1:
    call    VDP_B_Reset
    ld      hl,VDP_Regs_Graphics1
    call    VDP_B_SetRegistersFromArray
    ret

VDP_B_GoGraphics2:
    call    VDP_B_Reset
    ld      hl,VDP_Regs_Graphics2
    call    VDP_B_SetRegistersFromArray
    ret

; set the address to place text at X/Y coordinate
;       A = X
;       E = Y
VDP_B_SetTextPosition:
    ld      d, 0
    ld      hl, 0
    add     hl, de                  ; Y x 1
    add     hl, hl                  ; Y x 2
    add     hl, hl                  ; Y x 4
    add     hl, de                  ; Y x 5
    add     hl, hl                  ; Y x 10
    add     hl, hl                  ; Y x 20
    add     hl, hl                  ; Y x 40
    ld      e, a
    add     hl, de                  ; add column for final address
    ex      de, hl                  ; send address to TMS
    call    VDP_B_SetVRAMAddress
    ret

VDP_B_GoBitmapMode:
    ; Set up Graphics II for a pixel-addressable bitmap.
    ld      c,VDP_GoGraphics2
    DoVDPBIOS

    call    VDP_BI_SetupGraphicsIIColorTable
    call    VDP_BI_SetupGraphicsIINameTable
    ret

; calculate address byte containing X/Y coordinate
;       B = Y position
;       C = X position
;       returns address in DE
VDP_B_GetPixelAddress:
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

VDP_BI_SetupGraphicsIIColorTable:
    ; Set up the color table.
    ld      de,$2000
    ld      c,VDP_SetVRAMAddress
    DoVDPBIOS

    ; Fill the color table.
    ld      d,$18   ; outer loops
    ld      b,0     ; 256 inner loops
    ld      a,$F2   ; fg white, bg green
.loop:
    out     (VDP_PORT_VRAM),a
    VRAMWait
    djnz    .loop
    dec     d
    jr      nz,.loop
    
    ret

VDP_BI_SetupGraphicsIINameTable:
    ; Fill the nametable.
    ; Write $00-$FF sequentially to VRAM 3 times.
    ; Now the pattern table is a bitmap. Magic!

    ld      de,$3800
    ld      c,VDP_SetVRAMAddress
    DoVDPBIOS

    ld      d,3 ; outer loops
    ld      b,0 ; 256 inner loops
    ld      a,0 ; fg white, bg green
.drawLoop1:
    out     (VDP_PORT_VRAM),a
    inc     a
    defs    14/tmswait, 0         ; nops to waste time
    djnz    .drawLoop1

    ret
	
VDP_ASCIIFont:
    include "tms/tmsfont.asm"

VDP_Regs_Text:
    db      %00000000               ; text mode, no external video
    db      %11010000               ; 16K, Enable Display, Disable Interrupt
    db      $00                     ; name table at $0000
    db      $00                     ; color table not used
    db      $01                     ; pattern table at $0800
    db      $00                     ; sprite attribute table not used
    db      $00                     ; sprite pattern table not used
    db      $F2                     ; white text on black background

VDP_Regs_Graphics1:
    db      %00000000               ; tilemap mode, no external video
    db      %11000000               ; 16K, enable display, disable interrupt
    db      $05                     ; name table at $1400
    db      $80                     ; color table at $2000
    db      $01                     ; pattern table at $800
    db      $20                     ; sprite attribute table at $1000
    db      $00                     ; sprite pattern table at $0
    db      $01                     ; black background

VDP_Regs_Graphics2:
    db      %00000010               ; bitmap mode, no external video
    db      %11000010               ; 16KB ram; enable display
    db      $0e                     ; name table at $3800
    db      $ff                     ; color table at $2000
    db      $03                     ; pattern table at $0
    db      $76                     ; sprite attribute table at $3B00
    db      $03                     ; sprite pattern table at $1800
    db      $01                     ; black background

VDP_DefaultRegisters:
    ; Blanking, 16KB VRAM
    db      $00, $80, $00, $00, $00, $00, $00, $00

VDP_B_FnTable:
	dw  VDP_B_Reset		            ; C = 0
    dw  VDP_B_GoTextMode            ; C = 1
    dw  VDP_B_GoGraphics1           ; C = 2
    dw  VDP_B_GoGraphics2           ; C = 3
    dw  VDP_B_SetVRAMAddress        ; C = 4
    dw  VDP_B_SetRegistersFromArray ; C = 5
    dw  VDP_B_SetRegister           ; C = 6
    dw  VDP_B_VRAMBlockCopy         ; C = 7
    dw  VDP_B_StringOut             ; C = 8
    dw  VDP_B_SetTextPosition       ; C = 9
    dw  VDP_B_GoBitmapMode          ; C = 10
    dw  VDP_B_GetPixelAddress       ; C = 11

    PAGE 2
VDP_ShadowRegs: ds 8   ; 8 bytes of shadow registers

    org $8400
VDP_FnTable_Public: ds 256

