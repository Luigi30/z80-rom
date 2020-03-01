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

	include "rc2014.inc"
	
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

RST20:	jp	BIOS_Dispatch	; 0x20
		nop
		nop
		nop
		nop
		nop

RST28:	nop	; 0x28
		nop
		nop
		nop
		nop
		nop
	
RST30:	nop	; 0x30
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
	include "procapi.asm"

	PAGE 1

Start:
	ld		hl,$FFF9	; initialize stack
	ld		sp,hl

    ; Clear RAM
	ld		hl,$8000
    ld      d,$7F   ; outer loops
    ld      b,0     ; 256 inner loops
    ld      a,$00   ; fg white, bg black
.loop:
	ld		(hl),a
	inc		hl
    djnz    .loop
    dec     d
    jr      nz,.loop

	di
	call	rc2014_sio_init

	; Initialize the Procyon API
	call	PROCYON_B_ColdStart
	
	; Set up the VDP
	call	VDP_B_ColdStart

	VDPBIOS	VDP_Reset
    VDPBIOS VDP_GoTextMode	
	
	call	BOOT_WriteBanner

Greet:
	ld		de,HelloWorld
	push	de
	PROCYON P_PRINTF
	pop		hl

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
	; call	CmdDebugOutput

	call	Monitor_InterpretCommand

; Loop...
InputLoopEnd:
	ld		de,strCRLF
	ld		c,B_STROUT
	jp		GetInputString

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
	include "commands/in.asm"
	include "commands/out.asm"

	PAGE 1

BOOT_WriteBanner:
	ld		a,5
	ld		e,5
    VDPBIOS	VDP_SetTextPosition
    
	ld		hl,strBanner1
	VDPBIOS VDP_StringOut
    

	ld		a,9
	ld		e,6
    VDPBIOS	VDP_SetTextPosition
    
	ld		hl,strBanner2
	VDPBIOS	VDP_StringOut
    

	ld		a,0
	ld		e,20
    VDPBIOS	VDP_SetTextPosition
    
	ld		hl,strBanner3
	VDPBIOS	VDP_StringOut
    

    ld		a,10
	ld		e,22
    VDPBIOS	VDP_SetTextPosition
    
	ld		hl,strBanner4
	VDPBIOS	VDP_StringOut
    
	ret

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

	cp		"I"
	jp		z,Monitor_CMD_In

	cp		"O"
	jp		z,Monitor_CMD_Out

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
