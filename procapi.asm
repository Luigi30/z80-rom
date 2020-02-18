    PAGE 1

	include "procapi.inc"

PROCYON_B_FnTable:
	jp	PROCYON_StringToHex8	; C = 0
	jp	PROCYON_StringToHex16	; C = 1
	jp	PROCYON_Hex8ToString	; C = 2
	jp	PROCYON_Hex16ToString	; C = 3
	jp	PROCYON_Printf			; C = 4
	jp	B2D8					; C = 5
	jp	B2D16					; C = 6
	jp	B2D32					; C = 7

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

;;;;;;;;;;;;;;;;;;;;;;;;;
; Printf stuff
PROCYON_Printf:
    ; Inputs:
    ; stack contains
    ;   - top of stack
    ;   - ptr to string to print
    ;   - value of format parameter 1
    ;   - value of format parameter 2
    ;   - value of format parameter 3...
    ;
    ;   supports %s (pointer to string)

    ;   16-bit values:
    ;   supports %d (decimal number)
    ;   supports %x (hex number)
    ;   these are directly in the stack.

    ; Print characters until we hit a format char (%) or a NULL.

    ld      (_printf_params),sp  
    ld      ix,(_printf_params)  
    inc     ix
    inc     ix                  ; IX is the ptr to the parameters
    ld      (_printf_params),ix  ; Saved in printf_params

    ; Using IX as a stack frame pointer,
    ; Grab the string pointer and loop over it calling CONOUT.
    ld      l,(ix+0)
    ld      h,(ix+1)
    ; HL is now the string pointer

PrintF_StringLoop:
    push    hl
    ld		a,(hl)

    ; Check for NULL.
    cp      $00
    jr      z,PrintF_End

    cp      "%"
    jr      z,.getFormatChar

    ld      e,a
	ld		c,B_CONOUT
	DoBIOS

.advance:
    pop     hl
    inc     hl
    jr      PrintF_StringLoop

.getFormatChar:
    ; Advance string pointer to the format character.
    pop     hl
    inc     hl

    ; Determine the format char.
    ld      a,(hl)

    cp      "s"     ; %s
    jp      z,PrintF_FChar_s
    cp      "x"     ; %x
    jp      z,PrintF_FChar_x
    cp      "d"     ; %d
    jp      z,PrintF_FChar_d
    cp      "l"     ; %l...
    jp      z,PrintF_FChar_l

PrintF_FormatDone:  ; Entry point when returning from a format char.
    inc     hl
    jr      PrintF_StringLoop

PrintF_End:         ; PrintF is completely finished.
    ; Fix the stack before returning.
    pop     hl
    ret

;;;
PrintF_FChar_l:
    ; 32-bit (Long) versions of D and X.
    inc     hl
    ld      a,(hl)

    cp      "x"     ; %lx
    jp      z,PrintF_FChar_lx
    cp      "d"     ; %ld
    jp      z,PrintF_FChar_ld  

    jp      PrintF_FormatDone

;;;
PrintF_FChar_ld:
    ; Input: (_printf_params) is a stack frame.
    push    hl  ; save the string pointer

    ; 32-bit value in the stack
    ; B2D32 expects the value to be in DE:HL
    call    PrintF_AdvanceParamsFrame
    ld      e,(hl)
    inc     hl
    ld      d,(hl)
    inc     hl
    ld      c,(hl)
    inc     hl
    ld      b,(hl)
    push    bc
    pop     hl
    call    B2D32
    ex      de,hl
	ld		c,B_STROUT
	DoBIOS

    pop     hl
    jp      PrintF_FormatDone

;;;
PrintF_FChar_lx:
    ; Input: (_printf_params) is a stack frame.
    push    hl  ; save the string pointer

    ; 32-bit value in the stack
    ; 0 1 2 3
    call    PrintF_AdvanceParamsFrame
    call    PrintF_AdvanceParamsFrame

    ld      a,(hl)
    ld      e,a
    inc     hl
    ld      a,(hl)
    ld      d,a   
    ld		(HEXTOSTRING_SRC),de
	PROCYON P_HEX16TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS

    call    PrintF_StepBackParamsFrame
    ld      a,(hl)
    ld      e,a
    inc     hl
    ld      a,(hl)
    ld      d,a   
    ld		(HEXTOSTRING_SRC),de
	PROCYON P_HEX16TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS

    call    PrintF_AdvanceParamsFrame

    pop     hl
    jp      PrintF_FormatDone
;;;
PrintF_FChar_x:
    ; Input: (_printf_params) is a stack frame.
    push    hl  ; save the string pointer
    call    PrintF_AdvanceParamsFrame

    ld      a,(hl)
    ld      e,a
    inc     hl
    ld      a,(hl)
    ld      d,a   
    ld		(HEXTOSTRING_SRC),de
	PROCYON P_HEX16TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS

    pop     hl
    jp      PrintF_FormatDone

;;;
PrintF_FChar_s:
    ; Input: (_printf_params) is a stack frame.
    push    hl  ; save the string pointer
    call    PrintF_AdvanceParamsFrame

    ; Fetch the string pointer and print.
    ld      a,(hl)
    ld      e,a
    inc     hl
    ld      a,(hl)
    ld      d,a    
    ld      c,B_STROUT
    DoBIOS

    pop     hl
    jp      PrintF_FormatDone

;;;
PrintF_FChar_d:
    ; Input: (_printf_params) is a stack frame.
    push    hl  ; save the string pointer
    call    PrintF_AdvanceParamsFrame

    ; Fetch the 16-bit decimal value
    ld      c,(hl)
    inc     hl
    ld      b,(hl)
    push    bc
    pop     hl
    call    B2D16
    ex      de,hl
	ld		c,B_STROUT
	DoBIOS   

    pop     hl
    jp      PrintF_FormatDone

;;;
PrintF_AdvanceParamsFrame:
    ; Advances the printf params stack frame by one word,
    ; then saves it back to printf_params.
    ld      hl,(_printf_params)
    inc     hl
    inc     hl
    ld      (_printf_params),hl
    ret

PrintF_StepBackParamsFrame:
    ; Steps back in the printf params stack frame by one word,
    ; then saves it back to printf_params.
    ld      hl,(_printf_params)
    dec     hl
    dec     hl
    ld      (_printf_params),hl
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Combined routine for conversion of different sized binary numbers into
; directly printable ASCII(Z)-string
; Input value in registers, number size and -related to that- registers to fill
; is selected by calling the correct entry:
;
;  entry  inputregister(s)  decimal value 0 to:
;   B2D8             A                    255  (3 digits)
;   B2D16           HL                  65535   5   "
;   B2D24         E:HL               16777215   8   "
;   B2D32        DE:HL             4294967295  10   "
;   B2D48     BC:DE:HL        281474976710655  15   "
;   B2D64  IX:BC:DE:HL   18446744073709551615  20   "
;
; The resulting string is placed into a small buffer attached to this routine,
; this buffer needs no initialization and can be modified as desired.
; The number is aligned to the right, and leading 0's are replaced with spaces.
; On exit HL points to the first digit, (B)C = number of decimals
; This way any re-alignment / postprocessing is made easy.
; Changes: AF,BC,DE,HL,IX
; P.S. some examples below

; by Alwin Henseler

    PAGE 1

B2D8:    LD H,0
         LD L,A
B2D16:   LD E,0
B2D24:   LD D,0
B2D32:   LD BC,0
B2D48:   LD IX,0          ; zero all non-used bits
B2D64:   LD (B2DINV),HL
         LD (B2DINV+2),DE
         LD (B2DINV+4),BC
         LD (B2DINV+6),IX ; place full 64-bit input value in buffer
         LD HL,B2DBUF
         LD DE,B2DBUF+1
         LD (HL)," "
B2DFILC: EQU $-1         ; address of fill-character
         LD BC,18
         LDIR            ; fill 1st 19 bytes of buffer with spaces
         LD (B2DEND-1),BC ;set BCD value to "0" & place terminating 0
         LD E,1          ; no. of bytes in BCD value
         LD HL,B2DINV+8  ; (address MSB input)+1
         LD BC,#0909
         XOR A
B2DSKP0: DEC B
         JR Z,B2DSIZ     ; all 0: continue with postprocessing
         DEC HL
         OR (HL)         ; find first byte <>0
         JR Z,B2DSKP0
B2DFND1: DEC C
         RLA
         JR NC,B2DFND1   ; determine no. of most significant 1-bit
         RRA
         LD D,A          ; byte from binary input value
B2DLUS2: PUSH HL
         PUSH BC
B2DLUS1: LD HL,B2DEND-1  ; address LSB of BCD value
         LD B,E          ; current length of BCD value in bytes
         RL D            ; highest bit from input value -> carry
B2DLUS0: LD A,(HL)
         ADC A,A
         DAA
         LD (HL),A       ; double 1 BCD byte from intermediate result
         DEC HL
         DJNZ B2DLUS0    ; and go on to double entire BCD value (+carry!)
         JR NC,B2DNXT
         INC E           ; carry at MSB -> BCD value grew 1 byte larger
         LD (HL),1       ; initialize new MSB of BCD value
B2DNXT:  DEC C
         JR NZ,B2DLUS1   ; repeat for remaining bits from 1 input byte
         POP BC          ; no. of remaining bytes in input value
         LD C,8          ; reset bit-counter
         POP HL          ; pointer to byte from input value
         DEC HL
         LD D,(HL)       ; get next group of 8 bits
         DJNZ B2DLUS2    ; and repeat until last byte from input value
B2DSIZ:  LD HL,B2DEND    ; address of terminating 0
         LD C,E          ; size of BCD value in bytes
         OR A
         SBC HL,BC       ; calculate address of MSB BCD
         LD D,H
         LD E,L
         SBC HL,BC
         EX DE,HL        ; HL=address BCD value, DE=start of decimal value
         LD B,C          ; no. of bytes BCD
         SLA C           ; no. of bytes decimal (possibly 1 too high)
         LD A,"0"
         RLD             ; shift bits 4-7 of (HL) into bit 0-3 of A
         CP "0"          ; (HL) was > 9h?
         JR NZ,B2DEXPH   ; if yes, start with recording high digit
         DEC C           ; correct number of decimals
         INC DE          ; correct start address
         JR B2DEXPL      ; continue with converting low digit
B2DEXP:  RLD             ; shift high digit (HL) into low digit of A
B2DEXPH: LD (DE),A       ; record resulting ASCII-code
         INC DE
B2DEXPL: RLD
         LD (DE),A
         INC DE
         INC HL          ; next BCD-byte
         DJNZ B2DEXP     ; and go on to convert each BCD-byte into 2 ASCII
         SBC HL,BC       ; return with HL pointing to 1st decimal
         RET

;      EXAMPLES
;      --------

; (In these examples, it is assumed there exists a subroutine PRINT, that
; prints a string (terminated by a 0-byte) starting at address [HL] )


; Print 1 byte, as follows:
;  20
;   7
; 145  etc.
; by:   LD A,byte
;       CALL B2D8
;       LD HL,B2DEND-3
;       CALL PRINT


; Print a 24-bit value, as follows:
; 9345
; 76856366
; 534331
; by:   LD E,bit23-16
;       LD HL,bit15-0
;       CALL B2D24
;       CALL PRINT


; Print a 48-bit value, like
;     14984366484
;              49
; 123456789012345
;         3155556 etc.
; by:
;       LD BC,bit47-32
;       LD DE,bit31-16
;       LD HL,bit15-0
;       CALL B2D48
;       LD HL,B2DEND-15
;       CALL PRINT

	PAGE 2
	
	org	PROCAPI_DATA_BASE
;;;
_StringToHex_Source:	ds 16	; 0
_StringToHex_Dest:		ds 8	; 16
_HexToString_Source:	ds 4	; 24
_HexToString_Dest:		ds 4	; 28
_printf_params:			ds 2	; 32
B2DINV:  				DS 8    ; 34 ; space for 64-bit input value (LSB first)
B2DBUF:  				DS 20   ; 42 ; space for 20 decimal digits
B2DEND:  				DS 1    ; 62 ; space for terminating 0


    org PROCYON_PUBLIC_API_BASE
PROCYON_FnTable_Public: ds 256
