	include "procapi.inc"

    PAGE 1

PROCYON_B_FnTable:
	jp	PROCYON_StringToHex8	; C = 0
	jp	PROCYON_StringToHex16	; C = 1
	jp	PROCYON_Hex8ToString	; C = 2
	jp	PROCYON_Hex16ToString	; C = 3

PROCYON_B_ColdStart:
    ; Copy the table from PROCYON_B_FnTable to the public table in RAM.
    ld  bc,256
    ld  de,PROCYON_FnTable_Public
    ld  hl,PROCYON_B_FnTable
    ldir

    ret
    
;;;;;;;;;;;;;;;;;;;;

PROCYON_StringToHex8:
; Convert the string in StringToHex_Source to a 8-bit hex value.
	ld		ix,_StringToHex_Source
	ld		iy,_StringToHex_Dest

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
	ld		ix,_StringToHex_Source
	ld		iy,_StringToHex_Dest

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
	ld		iy,_HexToString_Dest
	ld		ix,_HexToString_Source

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
	ld		ix,_HexToString_Source
	ld		iy,_HexToString_Dest

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

	org	PROCAPI_DATA_BASE
;;;
_StringToHex_Source:	ds 16	; 0
_StringToHex_Dest:		ds 8	; 16
_HexToString_Source:	ds 4	; 24
_HexToString_Dest:		ds 4	; 28

    org PROCYON_PUBLIC_API_BASE
PROCYON_FnTable_Public: ds 256
