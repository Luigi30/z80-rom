DoBIOS	.macro
		rst	$20
		.endm

;;; rc2014_getc
;;; Wait for the UART to receive a character.
;;; Return the character in HL.
rc2014_getc:
        push 	af
waitch:	in 	a,(SIOA_C)
        bit 	0,a
        jr 	z,waitch
        in 	a,(SIOA_D)
        ld 	h,0
        ld 	l,a
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
#local
	push af
txbusy: in a,($80)          ; read serial status
        bit 2,a             ; check status bit 2
        jr z, txbusy        ; loop if zero (serial is busy)
        pop af
        out ($81), a        ; transmit the character
        ret
#endlocal

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

	;;;;;;;;;;;;;;;
	; BIOS functions
;;; ;;;;;;;;;;;;;;;;;
;;; BIOS functions
;;;
BIOS_Dispatch:
	;; Dispatch to the function number C.
	push	de
	push	af
	ld		hl,BIOS_FnTable	; grab the jump table address
	ld		d,0		; clear D
	
	sla		c		; shift C to produce a table offset
	ld		e,c		; E <- C
	add		hl,de	; Apply the offset.
	ld		de,(hl)	; Get the destination address.
	ld		hl,de	; Move it into HL so we can jump to it.

	pop		af		; Restore AF and DE.
	pop		de
	jp		(hl)	; Jump to the BIOS function, which RETs back to where we started.
	ret				; Unnecessary unless something breaks
	
C_Conout:
	;; CONsole OUTput.
	;; 
	;; Input:
	;; E - character
	ld		a,e
	call	rc2014_sio_TX
	ret

C_Strout:
	;; STRing OUTput.
	;; Input:
	;; DE - string address

#local
	;; Perform C_Conout until a 0 is found in the string.
1$:	
	ld		a,(de)
	cp		#0
	jr		z,2$
	push	de
	ld		e,a
	call	C_Conout
	pop		de
	inc		de
	jr		1$

2$:
	ret	
#endlocal	

BIOS_FnTable:
	.dw C_Conout	; C = 0
	.dw	C_Strout	; C = 1