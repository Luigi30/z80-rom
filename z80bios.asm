; Memory map for Procyon/80 and RC2014 64K
;
;	$0000-$7FFF - ROM region - currently uses $0000-$1FFF
;	$8000-$8FFF - Kernel private RAM
;	$9000-$FFFF - Transient Program Area (load programs here)

	OUTPUT "out/z80bios.rom"

	DEFPAGE	0, 0000h, 0200h		; Boot vectors and stuff
	DEFPAGE 1, 0200h, *	; Kernel code
	DEFPAGE 3, 1000h, 1000h	; VDP driver
	DEFPAGE 2, 8000h, 1000h ; Kernel data

include "bios.inc"

	;; SIO equates
SIOA_D	EQU $81
SIOA_C	EQU $80
SIOB_D	EQU $83
SIOB_C	EQU $82
	
		page 0
	;;  see rc2014init.asm
		org 0
	
RST00:	di					; interrupts off
		jp	Start
		nop
		nop
		nop
		nop			

RST08:	jp	rc2014_sio_TX	; 0x08
		nop
		nop
		nop
		nop
		nop

RST10:	jp	rc2014_getc		; 0x10
		nop
		nop
		nop
		nop
		nop

RST18:	jp	rc2014_pollc	; 0x18
		nop
		nop
		nop
		nop
		nop

RST20:	jp	B_Dispatch		; 0x20
		nop
		nop
		nop
		nop
		nop

RST28:	jp	VDP_B_Dispatch	; 0x28
		nop
		nop
		nop
		nop
		nop
	
RST30:	ret
		nop
		nop
		nop
		nop
		nop

RST38:	reti
		nop
		nop
		nop
		nop
		nop

		org 66h
NMI:
		reti
	
;;; ;;;;;;;;;;;;;;;;
	PAGE 1
	org	200h

	include	"rc2014.asm"
	include	"strings.asm"
	include "vdpbios.asm"

Start:
	ld		hl,$FFF9	; initialize stack
	ld		sp,hl

	; Clear $9000
	ld		b,0
	ld		de,$0000
	ld		hl,$9000
	ld		a,0
ClearSRAM:
	ld		(hl),a
	inc		hl
	inc		a
	djnz	ClearSRAM	

	di
	call	rc2014_sio_init
	
	; Set up the VDP
	call	VDP_B_ColdStart
	call    VDP_B_Reset

Greet:
	ld		de,HelloWorld
	ld		c,B_STROUT
	rst		$20

GetInputString:
	; reset offset
	ld		de,strPrompt
	ld		c,B_STROUT
	DoBIOS

	call	ClearInputBuffer
	ld		de,buffer_base
	ld		c,B_STRIN
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

	; Take the first two bytes of buffer_Input and put them in the command register.
	ld		de,(buffer_Input)
	ld		(MON_Command),de

CheckCmdLength:
	; Assume argument starts at buffer_Input+3
	ld		a,3
	ld		(MON_ArgStartsAt),a

	; Is the second byte of the command register 0x20? 
	; If so, the argument starts at buffer_Input+2.
	ld		a,(MON_Command+1)
	cp		$20
	jr		nz,GotCmdLength
	ld		a,2
	ld		(MON_ArgStartsAt),a

GotCmdLength:
	ld		b,10
	call	GetArgument
	call	CmdDebugOutput

	call	Monitor_InterpretCommand

; Loop...
InputLoopEnd:
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
	jp		GetInputString

;;;;;;;;

ConvertStringToHex8:
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

;;;;;;;;
ConvertStringToHex16:
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

;;;;;;;;
ConvertHex16ToString:
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

;;;
ConvertHex8ToString:
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

;;;;;;;;
CmdDebugOutput:
	ld		de,strDbgCmd
	ld		c,B_STROUT
	DoBIOS
	ld		ix,(MON_Command)
	ld		e,ixl
	ld		c,B_CONOUT
	DoBIOS
	ld		e,ixh
	ld		c,B_CONOUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

	ld		de,strDbgArg
	ld		c,B_STROUT
	DoBIOS
	ld		de,MON_Argument1
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
	ld		de,strDbgArg
	ld		c,B_STROUT
	DoBIOS
	ld		de,MON_Argument2
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
	ld		de,strDbgArg
	ld		c,B_STROUT
	DoBIOS
	ld		de,MON_Argument3
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
	ld		de,strDbgArg
	ld		c,B_STROUT
	DoBIOS
	ld		de,MON_Argument4
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

	ret

;;;;;;;;;;;;;;;;;;
GetArgument:
	; Clear the 4 argument buffers.
	ld		b,16*4
	ld		a,0
	ld		hl,MON_Argument1
.loop:
	ld		(hl),0
	inc		hl
	djnz	.loop

	; Copy from buffer_Input+MON_ArgStartsAt into the argument buffers.
	; Max 4 space-delimited arguments.
	ld		de,MON_Argument1	; <-- MUST BE PAGE ALIGNED FOR POINTER MATH TO WORK!
	ld		hl,buffer_Input
	ld		ix,MON_Argument1

	ld		a,(MON_ArgStartsAt)
	ld		c,a
	ld		b,0		; BC is now ArgStartsAt
	add		hl,bc	; And HL is now the beginning of the arguments.

	; HL is now the beginning of the argument.
	; DE is now the destination address.
.ArgumentCopyLoop:
	; Copy until we find a SPC. A CR/LF advances to the next argument buffer.
	; Only 4 arguments are supported.
	ld		a,(hl)
	inc		hl
	cp		$0D
	jr		z,.done
	cp		$20
	jr		nz,.copychar
	
	; Advance to the next argument.
	ld		a,ixl
	add		a,16
	ld		e,a
	add		a,16
	ld		ixl,a

	jr		.ArgumentCopyLoop

.copychar:
	ld		(de),a
	inc		de
	djnz	.ArgumentCopyLoop

.done:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ClearInputBuffer:
	ld		a,0
	ld		hl,buffer_Input
.clear:
	ld		(hl),0
	inc		hl
	inc		a
	cp		$FF
	jr		nz,.clear
	ret

	include "commands/memory.asm"
	include "commands/go.asm"
	include "commands/upload.asm"

	PAGE 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Monitor_InterpretCommand:
	; The Z80 version of a switch statement?
	ld		a,(MON_Command)

	; JP to the command that matches. 
	; If no command matches, fall through to an error.
	; The command's RET will return to *this function's caller*
	; i.e. the command loop.

	; Command: Memory
	cp		"M"
	jp		z,Monitor_CMD_Memory

	cp		"G"
	jp		z,Monitor_CMD_Go

	cp		"U"
	jp		z,Monitor_CMD_Upload

	ld		de,strCmdUnknown
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	PAGE 2	; Data section in RAM. Assume 32K of RAM on an RC2014.

buffer_base:
buffer_len:				db 0
buffer_inputsize:		db 0
buffer_Input:			ds 255	; 255 bytes of input storage

;;;
StringToHex_Source:		ds 16
StringToHex_Dest:		ds 8

HexToString_Source:		ds 4
HexToString_Dest:		ds 4

;;;
MemoryOutputStartAddr:	dw 0
MemoryOutputCurAddr:	dw 0
MemoryOutputEndAddr:	dw 0
MemoryOutputBytesLeft:	dw 0

;;;
HEX_DestinationAddr:	dw 0

;;;;;;;;;;;;;;;;;;;
; ROM monitor data stuff
MON_PreviousCmd:	db		0,0
MON_Command:		db		0,0

MON_ArgDestPtr:		dw		0
MON_ArgStartsAt: 	db		0
	org $8800			; ensure these are page-aligned
MON_Argument1:		ds		16
MON_Argument2:		ds		16
MON_Argument3:		ds		16
MON_Argument4:		ds		16
