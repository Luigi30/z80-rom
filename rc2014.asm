	page 1

BIOS_FnTable:
	dw	BIOS_Reset			; C = 0
	dw  BIOS_Conout			; C = 1
	dw	BIOS_Strout			; C = 2
	dw	BIOS_Conin			; C = 3
	dw	BIOS_Constat		; C = 4
	dw	BIOS_Strin			; C = 5

;;; rc2014_getc
;;; Wait for the UART to receive a character.
;;; Return the character in HL.
rc2014_getc:
        push 	af
waitch:	in 		a,(SIOA_C)
        bit 	0,a
        jr 		z,waitch
        in 		a,(SIOA_D)
        ld 		h,0
        ld 		l,a
        pop 	af
        ret

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; rc2014_putc
;;; Output the byte in L to the SIO.
;;;
rc2014_putc:
	ld	a,l
	rst	$08
	ret

;;; rc2014_pollc
;;; Poll the UART receive buffer.
;;; L <- 1 if data available
;;; L <- 0 if no data available
rc2014_pollc:
	ld	l,0
	in	a,(SIOA_C)
	bit	0,a
	ret	z
	ld	l,1
	ret

;;; ;;;;;;;;;;;;;
rc2014_sio_TX:
		push af
.txb: 	in a,($80)          ; read serial status
        bit 2,a             ; check status bit 2
        jr z, .txb        	; loop if zero (serial is busy)
        pop af
        out ($81), a        ; transmit the character
        ret

;;; ;;;;;;;;;;;;;
rc2014_sio_init:
;;; Set up the SIO channel A for UART transmit/receive.
	ld	a,00110000b	; WR0: error reset, select WR0
	out	(SIOA_C),a
	ld	a,018h		; WR0: reset
	out	(SIOA_C),a

	ld	a,04h		; WR0: select WR4
	out	(SIOA_C),a
	ld	a,11000100b	; WR4: CLK/64, 1 stop, N parity (at 2.4MHz, 38400bps)
	out	(SIOA_C),a

	ld	a,05h		; WR0: select WR5
	out	(SIOA_C),a
	ld	a,11101000b	; DTR, TX 8bit, no BRK, TX on, no RTS
	out	(SIOA_C),a

	ld	a,01h		; WR0: select WR1
	out	(SIOB_C),A
	ld	a,00000100b	; No CH B interrupt

	ld	a,01h		; WR0: Select WR1
	out	(SIOA_C),A	
	ld	a,00h		; WR1: All interrupts off
	out	(SIOA_C),A

	;; Enable SIO RX on channel A.
	ld	a,03h
	out	(SIOA_C),a
	ld	a,0C1h		; RX 8bit, RX on, auto enable off
	out	(SIOA_C),a

	ret

;;; ;;;;;;;;;;;;;;;;;
;;; BIOS functions
;;;
;;; API:
;;;		All BIOS functions are prefixed with B_
;;; 	Input is DE
;;;		Output bytes are in A
;;;		Output words are in HL (todo: ?)
;;;
;;;		Do not assume any registers are preserved.
BIOS_Dispatch:
	;; Dispatch to the function number C.
	push	de
	push	af
	ld		hl,BIOS_FnTable	; grab the jump table address
	ld		d,0		; clear D
	
	sla		c		; shift C to produce a table offset
	ld		e,c		; E <- C
	add		hl,de	; Apply the offset.

	ld		a,(hl)	; Get the destination address. 
	ld		e,a
	inc		hl
	ld		d,(hl)

	push	de		; Move it into HL so we can jump to it.
	pop		hl

	pop		af		; Restore AF and DE.
	pop		de
	jp		(hl)	; Jump to the BIOS function, which RETs back to where we started.
	ret				; Unnecessary unless something breaks

;;
BIOS_Reset:
	rst 	$00

;;
BIOS_Conout:
	;; CONsole OUTput.
	;; 
	;; Input:
	;; D - device code for output
	;; E - character
	ld		a,e
	call	rc2014_sio_TX
	ret

;;
BIOS_Strout:
	;; STRing OUTput.
	;; Input:
	;; DE - string address
	;;
	;; Perform BIOS_Conout until a 0 is found in the string.
.loop1:
	ld		a,(de)
	cp		#0
	jr		z,.loop2
	push	de
	ld		e,a
	call	BIOS_Conout
	pop		de
	inc		de
	jr		.loop1

.loop2:
	ret	
;;

BIOS_Conin:
	;; CONsole INput.
	;;
	;; Blocks until a character is available on the console.
	;; Output:
	;; A = character received
	call	rc2014_getc	; returns char in L
	ld		a,l			; copy it to A and return
	ret
	;;

BIOS_Constat:
	;; CONsole STATus.
	;;
	;; Output:
	;; A  = 0 if no characters are waiting to be read
	;; A != 0 if character is waiting
	call	rc2014_pollc
	ld		a,l
	ret

BIOS_Strin:
	;; Read string into buffer.
	;; Buffer structure is as follows:
	;;	db buffer_size		- how many characters are allowed
	;;	db input_length 	- populated after input is complete
	;;	byte[buffer_size] 	- the input string
	;;
	;; Buffer address is placed in DE.
	push	de
	pop		iy		; Copy buffer base address to IY.
	inc		iy
	inc		iy		; advance 2 bytes to start of the string buffer

	ld		ix,0	; clear input length

.begin:
	rst		$10		; Get an input character.

	ld		a,l
	cp		$80
	jp		p,.begin

	; Check for Ctrl+H
	ld		a,l
	cp		$08
	jr		z,.handlebs

.check2:
	; Check for 0x7F (some terminals use this instead)
	ld		a,l
	cp		$7F	
	jr		nz,.charout	; Any other character bypasses

.handlebs:
	;; Handle the backspace.
	ld		a,ixl	; is the input length already 0? if so, ignore and go back to waiting for input
	cp		0
	jr		z,.begin

	; Reset the write pointer and length.
	dec		iy
	dec		ix

	push	de
	push	hl
	push	ix
	push	iy
	ld		e,$08
	ld		c,B_CONOUT
	DoBIOS		; console BS
	ld		e,$20
	ld		c,B_CONOUT
	DoBIOS		; console SPC
	ld		e,$08
	ld		c,B_CONOUT
	DoBIOS		; console BS
	pop		iy
	pop		ix
	pop		hl
	pop		de
	jr		.begin	; And we're done.

.charout:
	; write character to buffer
	ld		(iy),l	; copy the character to the input buffer
	inc		iy		; advance buffer
	inc		ix		; length++

	; TODO: Length == buffer size? If so, don't allow more characters.

.write:	
	; write character to console
	push	de
	push	hl
	push	ix
	push	iy
	ld		e,l
	ld		c,B_CONOUT
	DoBIOS
	pop		iy
	pop		ix
	pop		hl
	pop		de

	; Is the character 0x0D?
	ld		a,l
	cp		$0D	; CR
	jr		z,.done		; loop if no

	; Is the character 0x0D?
	ld		a,l
	cp		$0A	; LF
	jr		z,.done		; loop if no

	jr		.begin

.done:
	; add a null
	ld		l,0
	ld		(iy),l	; copy the character to the input buffer
	inc		iy		; advance buffer
	inc		ix		; length++

	; Write the length to the buffer struct
	ld		a,ixl
	push	de
	pop		iy
	ld		(iy+1),a

	ret
