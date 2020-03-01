	PAGE 1

Monitor_CMD_In:
	; If MON_Argument1 is NULL, abort with an error.
	ld		a,(MON_Argument1)
	cp		0
	jr		z,.argerror

    ld		hl,(MON_Argument1+0)
	ld		(STRINGTOHEX_SRC+0),hl
	call	PROCYON_StringToHex8
    ld      a,(STRINGTOHEX_DEST)    ; port to use
	ld		c,a
    in      a,(c)

    ld      (HEXTOSTRING_SRC),a
    call    PROCYON_Hex8ToString
    
    ld		a,(HEXTOSTRING_DEST)
	ld		e,a
	ld		c,B_CONOUT
	DoBIOS								
	ld		a,(HEXTOSTRING_DEST+1)
	ld		e,a
	ld		c,B_CONOUT
	DoBIOS

	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

    ret

.argerror:
	ld		de,strCmdArgumentError
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
	ret