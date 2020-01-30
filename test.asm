#target rom

;; SIO equates
SIOA_D	.EQU $81
SIOA_C	.EQU $80
SIOB_D	.EQU $83
SIOB_C	.EQU $82
	
#code	_ROM0,0,2000h

	;;  see rc2014init.asm
	
RST00:	di			; interrupts off
	jp	Start
	nop
	nop
	nop
	nop			

RST08:	jp	TX
	nop
	nop
	nop
	nop
	nop

RST10:	jp	rc2014_getc
	nop
	nop
	nop
	nop
	nop

RST18:	jp	rc2014_pollc
	nop
        nop
	nop
	nop
	nop

RST20:	nop
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
	
Start:
	ld	hl,$FFF9	; initialize stack
	ld	sp,hl

	di
	call	SIO_Init

Greet:	
	ld	a,$41
	rst	$08

Loopback:
	rst	$10
	ld	a,l
	rst	$08
	jp	Loopback

;;; ;;;;;;;;;;;;;;;;;

;;; SIO_Init
;;; Set up the SIO channel A for UART transmit/receive.
SIO_Init:
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
TX:    	push af
txbusy: in a,($80)          ; read serial status
        bit 2,a             ; check status bit 2
        jr z, txbusy        ; loop if zero (serial is busy)
        pop af
        out ($81), a        ; transmit the character
        ret
;;
;;
;;
#end
