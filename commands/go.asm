	PAGE 1

; Monitor's G command - Go
; JP to an address.
Monitor_CMD_Go:
	; If MON_Argument2 is NULL, abort with an error.
	ld		a,(MON_Argument1)
	cp		0
	jr		z,.argerror

    ; Beginning address
	ld		hl,(MON_Argument1+0)
	ld		(STRINGTOHEX_SRC+0),hl
	ld		hl,(MON_Argument1+2)
	ld		(STRINGTOHEX_SRC+2),hl
	PROCYON	P_STRTOHEX16

	ld		hl,(STRINGTOHEX_DEST)
    jp      (hl)

	ret

.argerror:
	ld		de,strCmdArgumentError
	ld		c,B_STROUT
	DoBIOS
	ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
	ret