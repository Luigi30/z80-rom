	include "procapi.inc"

    PAGE 1

PROCYON_B_FnTable:
	dw	PROCYON_StringToHex8	; C = 0
	dw	PROCYON_StringToHex16	; C = 1
	dw	PROCYON_Hex8ToString	; C = 2
	dw	PROCYON_Hex16ToString	; C = 3

PROCYON_B_ColdStart:
    ; Copy the table from PROCYON_B_FnTable to the public table in RAM.
    ld  bc,256
    ld  de,PROCYON_FnTable_Public
    ld  hl,PROCYON_B_FnTable
    ldir

    ret
    
;;; ;;;;;;;;;;;;;;;;;
;;; Procyon API functions
;;;
;;; API:
;;;		All Procyon API functions are prefixed with PROCYON_B_
;;; 	Input is A, BC, DE, HL
;;;		Output bytes are in A
;;;		Output words are in HL (todo: ?)
;;;
;;;		Do not assume any registers are preserved.
PROCYON_B_Dispatch:
	;; Dispatch to the function number C.
    ex      af
    ld      iyl,c
    exx
    ld      c,iyl
	ld		hl,PROCYON_FnTable_Public	; grab the jump table address
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

;;;;;;;;;;;;;;;;;;;;

PROCYON_StringToHex8:
; Convert the string in StringToHex_Source to a 8-bit hex value.
	ld		ix,StringToHex_Source
	ld		iy,StringToHex_Dest

.DoConversion:
.Digit0:
	; Less than $40? Subtract $30.
	; More than $40? Subtract $40.
	ld		a,(ix+0)
	cp		$40
	jp		m,.Digit0_IsNumber

.Digit0_IsAlpha:
	add		a,-$37
	sla		a
	sla		a
	sla		a
	sla		a
	ld		(iy+0),a
	jr		.Digit1

.Digit0_IsNumber:
	add		a,-$30
	sla		a
	sla		a
	sla		a
	sla		a
	ld		(iy+0),a
	jr		.Digit1

.Digit1:
	; Less than $40? Subtract $30.
	; More than $40? Subtract $40.
	ld		a,(ix+1)
	cp		$40
	jp		m,.Digit1_IsNumber

.Digit1_IsAlpha:
	add		a,-$37
	or		(iy+0)
	ld		(iy+0),a
	jr		.Done

.Digit1_IsNumber:
	add		a,-$30
	or		(iy+0)
	ld		(iy+0),a

.Done:
	ret

;;;;;;;;;;;
PROCYON_StringToHex16:
; Convert the string in StringToHex_Source to a 16-bit hex value.
	ld		ix,StringToHex_Source
	ld		iy,StringToHex_Dest

	; Right-justify the value and add leading zeroes.
.JustifyLoop:
	ld		a,(ix+3)
	cp		0
	jr		nz,.DoConversion
	ld		a,(ix+2)
	ld		(ix+3),a
	ld		a,(ix+1)
	ld		(ix+2),a
	ld		a,(ix+0)
	ld		(ix+1),a
	ld		a,$30		; ASCII 0
	ld		(ix+0),a
	jr		.JustifyLoop

.DoConversion:
.Digit0:
	; Less than $40? Subtract $30.
	; More than $40? Subtract $40.
	ld		a,(ix+0)
	cp		$40
	jp		p,.Digit0_IsAlpha
	jp		m,.Digit0_IsNumber

.Digit0_IsAlpha:
	add		a,-$37
	sla		a
	sla		a
	sla		a
	sla		a
	ld		(iy+1),a
	jr		.Digit1

.Digit0_IsNumber:
	add		a,-$30
	sla		a
	sla		a
	sla		a
	sla		a
	ld		(iy+1),a
	jr		.Digit1

.Digit1:
	; Less than $40? Subtract $30.
	; More than $40? Subtract $40.
	ld		a,(ix+1)
	cp		$40
	jp		p,.Digit1_IsAlpha
	jp		m,.Digit1_IsNumber

.Digit1_IsAlpha:
	add		a,-$37
	or		(iy+1)
	ld		(iy+1),a
	jr		.Digit2

.Digit1_IsNumber:
	add		a,-$30
	or		(iy+1)
	ld		(iy+1),a
	jr		.Digit2

.Digit2:
	; Less than $40? Subtract $30.
	; More than $40? Subtract $40.
	ld		a,(ix+2)
	cp		$40
	jp		p,.Digit2_IsAlpha
	jp		m,.Digit2_IsNumber

.Digit2_IsAlpha:
	add		a,-$37
	sla		a
	sla		a
	sla		a
	sla		a
	ld		(iy+0),a
	jr		.Digit3

.Digit2_IsNumber:
	add		a,-$30
	sla		a
	sla		a
	sla		a
	sla		a
	ld		(iy+0),a
	jr		.Digit3

.Digit3:
	; Less than $40? Subtract $30.
	; More than $40? Subtract $40.
	ld		a,(ix+3)
	cp		$40
	jp		p,.Digit3_IsAlpha
	jp		m,.Digit3_IsNumber

.Digit3_IsAlpha:
	add		a,-$37
	or		(iy+0)
	ld		(iy+0),a
	jr		.Done

.Digit3_IsNumber:
	add		a,-$30
	or		(iy+0)
	ld		(iy+0),a
	jr		.Done

.Done:
	ret

;;;;;;;;
PROCYON_Hex8ToString:
	; Convert the value in HexToString_Source to ASCII characters.
	; A
	ld		iy,HexToString_Dest
	ld		ix,HexToString_Source

	ld		hl,0
	ld		(iy+0),l
	ld		(iy+1),h
	ld		(iy+2),l
	ld		(iy+3),h

	ld		a,(ix)
	and		$F0		; now we only have A
	srl		a	
	srl		a
	srl 	a
	srl 	a
	add  	a,$90
	daa
	adc  	a,$40
	daa
	ld		(iy+0),a

	; B
	ld		a,(ix)
	and		$0F		; now we only have B
	add  	a,$90
	daa
	adc  	a,$40
	daa
	ld		(iy+1),a

	ld		a,0
	ld		(iy+2),a

	ret

;;;
PROCYON_Hex16ToString:
	; Convert the value in HexToString_Source to ASCII characters.
	ld		ix,HexToString_Source
	ld		iy,HexToString_Dest

	ld		hl,0
	ld		(iy+0),l
	ld		(iy+1),h
	ld		(iy+2),l
	ld		(iy+3),h

	; A
	ld		a,(ix+1)
	and		$F0		; now we only have A
	srl		a
	srl		a
	srl		a
	srl		a
	add  	a,$90
	daa
	adc  	a,$40
	daa
	ld		(iy+0),a

	; B
	ld		a,(ix+1)
	and		$0F		; now we only have B
	add  	a,$90
	daa
	adc  	a,$40
	daa
	ld		(iy+1),a

	; C
	ld		a,(ix)
	and		$F0		; now we only have C
	srl		a	
	srl		a
	srl 	a
	srl 	a
	add  	a,$90
	daa
	adc  	a,$40
	daa
	ld		(iy+2),a

	; D
	ld		a,(ix)
	and		$0F		; now we only have D
	add  	a,$90
	daa
	adc  	a,$40
	daa
	ld		(iy+3),a

	ld		a,0
	ld		(iy+4),a

	ret

	PAGE 2
;;;
StringToHex_Source:		ds 16
StringToHex_Dest:		ds 8

HexToString_Source:		ds 4
HexToString_Dest:		ds 4

    org $8500
PROCYON_FnTable_Public: ds 256
