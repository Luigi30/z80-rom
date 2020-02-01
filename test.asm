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
	jr		nz,GetArgument
	ld		a,2
	ld		(MON_ArgStartsAt),a

GetArgument:
#local
	; Copy 10 characters from buffer_Input+MON_ArgStartsAt into MON_Argument
	ld		b,10
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
#endlocal

	; Debug output
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

; Loop...
InputLoopEnd:
	jp		GetInputString

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

#data DATA,0x8000,0x8000	; Data section in RAM. Assume 32K of RAM on an RC2014.

buffer_base:
buffer_len:				.db 0
buffer_inputsize:		.db 0
buffer_Input:			.ds	255	; 255 bytes of input storage

;;;;;;;;;;;;;;;;;;;
; ROM monitor data stuff
MON_Command:		.dw		0
MON_Argument:		.ds		10
MON_ArgStartsAt: 	.db		0

#end
