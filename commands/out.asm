	PAGE 1

Monitor_CMD_Out:
	ld		a,(MON_Argument1)
	cp		0
	jr		z,.argerror

    ld		hl,(MON_Argument1+0)
	ld		(STRINGTOHEX_SRC+0),hl
	call	PROCYON_StringToHex8
    ld      a,(STRINGTOHEX_DEST)    ; port to use
    ld      c,a
    push    bc

    ld		hl,(MON_Argument2+0)
	ld		(STRINGTOHEX_SRC+0),hl
	call	PROCYON_StringToHex8
    pop     bc
    ld      a,(STRINGTOHEX_DEST)    ; byte to write
    ld      b,a

    out     (c),b

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