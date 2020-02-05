; Monitor's U command
; Upload a HEX file somewhere in memory
#local
Monitor_CMD_Upload::
    ; Each HEX record contains the destination address.
	ld		de,STR_HEX_ReadyToReceive
	ld		c,B_STROUT
	DoBIOS

    ; Receive one record.
    call    HEX_ReceiveRecord

    ; Is it an EOF?
    ld      a,(HEX_RecordType)
    cp      1    
    jr      z,Done

    ; Copy it to its destination.
    call    HEX_CopyRecord
    jr      Monitor_CMD_Upload

Done:
	ret
#endlocal

HEX_CopyRecord:
    ld      hl,HEX_RecordData
    ld      de,(HEX_Address)
    ld      a,(HEX_BytesInRecord)
    ld      c,a
    ld      b,0
    ldir
    ret

HEX_GetASCIIByteValue:
    ; Get two ASCII characters, convert them to a byte value, and return it in A.
    ld		c,B_CONIN
    DoBIOS
	ld		(StringToHex_Source+0),a
    ld		c,B_CONIN
    DoBIOS
	ld		(StringToHex_Source+1),a

	call	ConvertStringToHex8
	ld		a,(StringToHex_Dest)
    ret

HEX_AwaitStartCode:
    ; Listen for the start code.
    ld		c,B_CONIN
    DoBIOS

    cp      ":"
    jr      nz,HEX_AwaitStartCode

    ; Got the start code of a HEX.
    ret

HEX_ReceiveRecord:
    ; Receive a HEX record.

    ; Set up our variables.
    ld      a,0
    ld      (HEX_GotStartCode),a
    ld      (HEX_BytesInRecord),a

    call    HEX_AwaitStartCode
    ld      hl,HEX_GotStartCode
    inc     (hl)

    ld		de,STR_HEX_Debug_GotStart
	ld		c,B_STROUT
	DoBIOS

    ; Next up is the number of bytes contained in this record.
    call    HEX_GetASCIIByteValue
    ld      (HEX_BytesInRecord),a

	ld		de,STR_HEX_Debug_GotLength
	ld		c,B_STROUT
	DoBIOS

    ; Then a big-endian address.
    call    HEX_GetASCIIByteValue
    ld      h,a
    push    hl
    call    HEX_GetASCIIByteValue
    pop     hl
    ld      l,a
    ld      (HEX_Address),hl

    ld		de,STR_HEX_Debug_GotAddr
	ld		c,B_STROUT
	DoBIOS

    ; Then the record type.
    call    HEX_GetASCIIByteValue
    ld      (HEX_RecordType),a

	ld		de,STR_HEX_Debug_GotType
	ld		c,B_STROUT
	DoBIOS

    ; Then the record data itself.
    ld      a,(HEX_BytesInRecord)
    cp      0
    jr      z,HEX_GetChecksum

    ld      b,a
    ld      hl,HEX_RecordData

ReceiveLoop:
    push    bc
    push    hl

    call    HEX_GetASCIIByteValue
    
    pop     hl 
    pop     bc

    ld      (hl),a
    inc     hl          ; Advance receive buffer
    djnz    ReceiveLoop ; Loop until receive count is 0

	ld		de,STR_HEX_Debug_GotData
	ld		c,B_STROUT
	DoBIOS

HEX_GetChecksum:
    ; And finally the checksum.
    call    HEX_GetASCIIByteValue
    ld      (HEX_Checksum),a

	ld		de,STR_HEX_Debug_GotChecksum
	ld		c,B_STROUT
	DoBIOS

    ret

#data DATA
HEX_GotStartCode:   .db 0   ; Did we get the start code?
HEX_BytesInRecord:  .db 0   ; How many bytes does this record contain?

; The record itself.
HEX_Address:        .dw 0   ; WORD  - Destination address, always big-endian.
HEX_RecordType:     .db 0   ; BYTE  - Record type.
HEX_RecordData:     .ds 64  ; ARRAY - The record's contents.
HEX_Checksum:       .db 0   ; BYTE  - Checksum of the record.

#code _CODE
STR_HEX_ReadyToReceive: .ascii "Ready to receive HEX.",13,10,0
STR_HEX_Debug_GotStart: .ascii "Got start code",13,10,0
STR_HEX_Debug_GotLength: .ascii "Got rec length",13,10,0
STR_HEX_Debug_GotAddr: .ascii "Got rec address",13,10,0
STR_HEX_Debug_GotType: .ascii "Got rec type",13,10,0
STR_HEX_Debug_GotData: .ascii "Got rec data",13,10,0
STR_HEX_Debug_GotChecksum: .ascii "Got rec checksum",13,10,0
