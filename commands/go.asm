; Monitor's G command - Go
; JP to an address.
Monitor_CMD_Go:
    ; Beginning address
	ld		hl,(MON_Argument1+0)
	ld		(StringToHex_Source+0),hl
	ld		hl,(MON_Argument1+2)
	ld		(StringToHex_Source+2),hl

	call	ConvertStringToHex16
	ld		hl,(StringToHex_Dest)
    jp      (hl)

	ret