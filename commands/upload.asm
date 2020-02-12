; Monitor's U command
; Upload a HEX file somewhere in memory
Monitor_CMD_Upload:
    ; Each HEX record contains the destination address.

    ; Base address of an upload is 9000h.
	ld		de,STR_HEX_ReadyToReceive
	ld		c,B_STROUT
	DoBIOS

HEX_ProcessRecord:
    ; Receive one record.
    call    HEX_ReceiveRecord

    ; Is it an EOF?
    ld      a,(HEX_RecordType)
    cp      1    
    jr      z,.Done
    nop

    ; Copy it to its destination.
    call    HEX_CopyRecord

    ; Check the checksum.
    ld      a,(HEX_RunningChecksum)
    cp      0
    jr      nz,.bad    

    ld		e,"#"
	ld		c,B_CONOUT
    DoBIOS
    jr      .Next

.bad:
    ld		e,"X"
	ld		c,B_CONOUT
    DoBIOS

.Next:
    jr      HEX_ProcessRecord

.Done:
	ret

HEX_CopyRecord:
    ld      hl,(HEX_Address)
    ld      de,$9000
    add     hl,de
    ld      d,h
    ld      e,l
    ld      hl,HEX_RecordData
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

	; call	ConvertStringToHex8

	ld		c,B_STRTOHEX8
	DoProcyon

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
    
    exx 
    ld      b,0     ; The checksum will be in B'
    exx

    call    HEX_AwaitStartCode
    ld      hl,HEX_GotStartCode
    inc     (hl)

    ; Next up is the number of bytes contained in this record.
    call    HEX_GetASCIIByteValue
    ld      (HEX_BytesInRecord),a
    exx
    add     b       ; Checksum calculation
    ld      b,a     ; Store checksum in B
    exx

    ; Then a big-endian address.
    call    HEX_GetASCIIByteValue
    ld      h,a
    exx
    add     b       ; Checksum calculation
    ld      b,a     ; Store checksum in B
    exx


    push    hl
    call    HEX_GetASCIIByteValue
    push    af
    exx
    add     b       ; Checksum calculation
    ld      b,a     ; Store checksum in B
    exx
    pop     af

    pop     hl
    ld      l,a
    ld      (HEX_Address),hl

    ; Then the record type.
    call    HEX_GetASCIIByteValue
    ld      (HEX_RecordType),a
    exx
    add     b       ; Checksum calculation
    ld      b,a     ; Store checksum in B
    exx

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
    ld      (hl),a
    exx
    add     b       ; Checksum calculation
    ld      b,a     ; Store checksum in B
    exx

    pop     bc
    inc     hl          ; Advance receive buffer
    djnz    ReceiveLoop ; Loop until receive count is 0

HEX_GetChecksum:
    ; And finally the checksum.
    call    HEX_GetASCIIByteValue
    ld      (HEX_Checksum),a
    exx
    add     b       ; Checksum calculation
    ld      b,a     ; Store checksum in B
    ld      (HEX_RunningChecksum),a ; Final checksum!
    exx

    ret

    PAGE 2
HEX_GotStartCode:   db 0    ; Did we get the start code?
HEX_BytesInRecord:  db 0    ; How many bytes does this record contain?
HEX_BaseAddress:    dw 0    ; Base address to write to. The record's offset is added to it.
HEX_RunningChecksum:db 0    ; Running checksum total.

; The record itself.
HEX_Address:        dw 0    ; WORD  - Destination address, always big-endian.
HEX_RecordType:     db 0    ; BYTE  - Record type.
HEX_Checksum:       db 0    ; BYTE  - Checksum of the record.
HEX_RecordData:     ds 64   ; ARRAY - The record's contents.

    PAGE 1
STR_HEX_ReadyToReceive:     db "Ready to receive HEX. Ensure 3ms delay per character.",13,10,0
STR_HEX_Debug_GotStart:     db "Got start code",13,10,0
STR_HEX_Debug_GotLength:    db "Got rec length",13,10,0
STR_HEX_Debug_GotAddr:      db "Got rec address",13,10,0
STR_HEX_Debug_GotType:      db "Got rec type",13,10,0
STR_HEX_Debug_GotData:      db "Got rec data",13,10,0
STR_HEX_Debug_GotChecksum:  db "Got rec checksum",13,10,0
