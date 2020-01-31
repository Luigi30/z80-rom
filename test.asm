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

RST20:	jp	BIOS_Dispatch	; 0x20
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
	
#include "rc2014.asm"
	
Start:
	ld		hl,$FFF9	; initialize stack
	ld		sp,hl

	di
	call	rc2014_sio_init

Greet:
	ld		de,HelloWorld
	ld		c,C_STROUT
	rst		$20

	call	ClearInputBuffer

GetInputString:
	; reset offset
	ld		de,strPrompt
	ld		c,C_STROUT
	DoBIOS

	ld		ix,buffer_Input_offset
	ld		(ix),0
	ld		iy,buffer_Input

1$:
	rst		$10		; Get an input character.
	ld		(iy),l	; copy the character to the input buffer
	inc		iy		; advance it

	push	iy
	push	hl
	ld		e,l
	ld		c,C_CONOUT
	DoBIOS
	pop		hl
	pop		iy

	; Is the character 0x0A?
	ld		a,l
	cp		$0D	; LF
	jr		nz,1$		; loop if no

	; Yes. Write a CRLF.
	ld		e,$0D
	ld		c,C_CONOUT
	DoBIOS
	ld		e,$0A
	ld		c,C_CONOUT
	DoBIOS

	; Write string in buffer_Input if yes.
	ld		de,strYouEntered
	ld		c,C_STROUT
	DoBIOS

	ld		de,buffer_Input
	ld		c,C_STROUT
	DoBIOS

	ld		e,$0D
	ld		c,C_CONOUT
	DoBIOS
	ld		e,$0A
	ld		c,C_CONOUT
	DoBIOS

	jp		GetInputString

HelloWorld:
	.ascii	"Hello Z80!",13,10,0
strYouEntered:
	.ascii	"You entered: ",0
strPrompt:
	.ascii	">",0

;;
;;
;;

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

#data DATA,0x8000,0x8000	; Data section in RAM. Assume 32K of RAM on an RC2014.
buffer_Input:			.ds	255	; 255 bytes of input storage
buffer_Input_offset:	.db 0	; current offset into input storage

#end
