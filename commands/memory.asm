	PAGE 1

; Monitor's M command - memory output
Monitor_CMD_Memory:
	; Load the arguments into MemoryOutputStartAddr/MemoryOutputEndAddr.
    
    ; Beginning address
	ld		hl,(MON_Argument1+0)
	ld		(STRINGTOHEX_SRC+0),hl
	ld		hl,(MON_Argument1+2)
	ld		(STRINGTOHEX_SRC+2),hl
	call	PROCYON_StringToHex16
	ld		hl,(STRINGTOHEX_DEST)
	ld		(MemoryOutputStartAddr),hl

	; Ending address
	; If MON_Argument2 is NULL, abort with an error.
	ld		a,(MON_Argument2)
	cp		0
	jr		z,.argerror

	ld		hl,(MON_Argument2)
	ld		(STRINGTOHEX_SRC+0),hl
	ld		hl,(MON_Argument2+2)
	ld		(STRINGTOHEX_SRC+2),hl
	call	PROCYON_StringToHex16

	ld		hl,(STRINGTOHEX_DEST)
	ld		(MemoryOutputEndAddr),hl

	call	Monitor_DoMemoryOutput
	ret

.argerror:
	ld		de,strCmdArgumentError
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
	ret

Monitor_DoMemoryLabel:
	; Formatting: start address
	ld		hl,(MemoryOutputCurAddr)
	ld		(HEXTOSTRING_SRC),hl
	PROCYON	P_HEX16TOSTR

	ld		de,HEXTOSTRING_DEST
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
	ld		(HEXTOSTRING_SRC),a		
	push	ix
	; PROCYON	P_HEX8TOSTR
	call	PROCYON_Hex8ToString

	; Print two characters of output and a space
	ld		a,(HEXTOSTRING_DEST)
	ld		e,a
	ld		c,B_CONOUT
	DoBIOS								
	ld		a,(HEXTOSTRING_DEST+1)
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
	jp		m,.Done	; End if we're out of memory to write.
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

.Done:
	ret
