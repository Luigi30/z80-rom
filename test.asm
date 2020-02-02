#target rom

#include "bios.inc"

	;; SIO equates
SIOA_D	.EQU $81
SIOA_C	.EQU $80
SIOB_D	.EQU $83
SIOB_C	.EQU $82
	
#code	_BOOT,0h,200h		; Reset vector, RST vectors, NMI vectors

	;;  see rc2014init.asm
	
RST00:	di			; interrupts off
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

RST10:	jp	rc2014_getc	; 0x10
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

RST20:	jp	B_Dispatch	; 0x20
		nop
		nop
		nop
		nop
		nop

RST28:	ret
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
	
;;; ;;;;;;;;;;;;;;;;

#code	_CODE,0x200,0x1E00	; 8K page total
	
#include 	"rc2014.asm"
#include	"strings.asm"
	
Start:
	ld		hl,$FFF9	; initialize stack
	ld		sp,hl

	di
	call	rc2014_sio_init

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

	ld		de,strYouEntered
	ld		c,B_STROUT
	DoBIOS
	ld		de,buffer_Input
	ld		c,B_STROUT
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

	; debug: preload some values
	ld		hl,$0200
	ld		(MemoryOutputStartAddr),hl
	ld		hl,$023F
	ld		(MemoryOutputEndAddr),hl
	call	Monitor_DoMemoryOutput

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
ConvertHex16ToString:
	; Convert the value in HexToString_Source to ASCII characters.
	ld		ix,HexToString_Source
	ld		iy,HexToString_Dest

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
	ld		de,MON_Argument
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

	ret

;;;;;;;;;;;;;;;;;;
GetArgument:
#local
	; Copy B characters from buffer_Input+MON_ArgStartsAt into MON_Argument
	ld		hl,buffer_Input
	ld		de,MON_Argument

	ld		a,(MON_ArgStartsAt)
	ld		c,a
	ld		b,0		; BC is now ArgStartsAt
	add		hl,bc
	
	; HL is now the beginning of the argument.
	; DE is now the destination address.
ArgumentCopyLoop:
	ld		a,(hl)
	ld		(de),a
	inc		hl
	inc		de
	djnz	ArgumentCopyLoop

	ret
#endlocal

;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ClearInputBuffer:
	ld		a,0
	ld		hl,buffer_Input
1$:
	ld		(hl),0
	inc		hl
	inc		a
	cp		$FF
	jr		nz,1$
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Monitor_DoMemoryLabel:
	; Formatting: start address
	ld		hl,(MemoryOutputCurAddr)
	ld		(HexToString_Source),hl
	call	ConvertHex16ToString
	ld		de,HexToString_Dest
	ld		c,B_STROUT
	DoBIOS
	ld		e,":"
	ld		c,B_CONOUT
	DoBIOS
	ld		e," "
	ld		c,B_CONOUT
	DoBIOS
	ret

Monitor_PrintBytes:
	; Input:
	; B  - how many bytes to dump
	; IX - pointer to start of memory area to dump
	push	bc

	ld		a,(ix)						; A has a memory byte
	ld		(HexToString_Source),a		
	push	ix
	call	ConvertHex8ToString			; Convert it to ASCII

	; Print two characters of output and a space
	ld		a,(HexToString_Dest)
	ld		e,a
	ld		c,B_CONOUT
	DoBIOS								
	ld		a,(HexToString_Dest+1)
	ld		e,a
	ld		c,B_CONOUT
	DoBIOS
	ld		e," "
	ld		c,B_CONOUT
	DoBIOS

	; Advance the memory source pointer. Continue until B == 0.
	pop		ix
	inc		ix

	pop		bc
	djnz	Monitor_PrintBytes

	ret

Monitor_DoMemoryOutput:
#local
	ld		hl,(MemoryOutputStartAddr)
	ld		(MemoryOutputCurAddr),hl

	call	Monitor_DoMemoryLabel

	; Output 16 memory bytes
	ld		hl,(MemoryOutputEndAddr)
	ld		bc,(MemoryOutputStartAddr)
	scf
	ccf		; Clear carry flag to get the proper subtraction result.
	inc		hl	
	sbc		hl,bc
	ld		(MemoryOutputBytesLeft),hl

	ld		ix,(MemoryOutputStartAddr)
	ld		b,16
	call	Monitor_PrintBytes

EndMemoryLine:
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

	ld		hl,(MemoryOutputBytesLeft)
	scf
	ld		bc,16
	sbc		hl,bc	; Subtract the 16 bytes we already read.
	jp		m,Done	; End if we're out of memory to write.
	jp		z,Done	; End if we're out of memory to write.
	ld		(MemoryOutputBytesLeft),hl

	ld		bc,16
	ld		hl,(MemoryOutputCurAddr)
	add		hl,bc						; Advance start pointer
	ld		(MemoryOutputCurAddr),hl	
	call	Monitor_DoMemoryLabel

	ld		b,16						; Another 16 bytes
	ld		ix,(MemoryOutputCurAddr)
	call	Monitor_PrintBytes
	jp		EndMemoryLine

Done:
	ret
#endlocal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#data DATA,0x8000,0x8000	; Data section in RAM. Assume 32K of RAM on an RC2014.

buffer_base:
buffer_len:				.db 0
buffer_inputsize:		.db 0
buffer_Input:			.ds	255	; 255 bytes of input storage

;;;
StringToHex_Source:		.ds 16
StringToHex_Dest:		.ds 8

HexToString_Source:		.ds	4
HexToString_Dest:		.ds 4

;;;
MemoryOutputStartAddr:	.dw 0
MemoryOutputCurAddr:	.dw 0
MemoryOutputEndAddr:	.dw 0
MemoryOutputBytesLeft:	.dw 0

;;;;;;;;;;;;;;;;;;;
; ROM monitor data stuff
MON_Command:		.dw		0
MON_Argument:		.ds		10
MON_ArgStartsAt: 	.db		0

#end
