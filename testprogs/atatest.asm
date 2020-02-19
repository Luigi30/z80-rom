    OUTPUT  "testprogs/out/atatest.bin"

	DEFPAGE 1, 09000h, *    ; CODE
    DEFPAGE 2, *, *         ; DATA

    incdir  ".."
    include "procapi.inc"
    include "rc2014.inc"
    include "ata.inc"

    PAGE 1
Entry:
    jp      START

Math_OperandA   dw  0   ; 16-bit
Math_OperandB   dw  0   ; 16-bit
Math_ResultR    dd  0   ; 32-bit

AddU16:
    ; U16 + U16 = U32
    ; A   + B   = C
    ld      hl,(Math_OperandA)
    ld      de,(Math_OperandB)
    add     hl,de
    jr      c,.carry

.nocarry:
    ld      (Math_ResultR),hl
    ld      hl,0
    ld      (Math_ResultR+2),hl
    ret

.carry:
    ld      (Math_ResultR),hl
    ld      hl,$0100
    ld      (Math_ResultR+2),hl
    ret

;;;

AddS16:
    ; S16 + S16 = S32
    ; A   + B   = C
    ld      hl,(Math_OperandA)
    ld      de,(Math_OperandB)
    add     hl,de
    ld      (Math_ResultR),hl
    ld      hl,$FFFF
    ld      (Math_ResultR+2),hl
    ret

;;;

SubS16:
    ; S16 - S16 = S32
    ; A   - B   = C
    ld      hl,(Math_OperandA)
    ld      de,(Math_OperandB)
    scf
    ccf
    sbc     hl,de
    jr      c,.carry

.nocarry:
    ld      (Math_ResultR),hl
    ld      hl,0
    ld      (Math_ResultR+2),hl
    ret

.carry:
    ld      (Math_ResultR),hl
    ld      hl,$FFFF
    ld      (Math_ResultR+2),hl
    ret

;;;;;;;;;;;;;;;;;;;;;

START:
    ld		de,strATADetect
	ld		c,B_STROUT
	DoBIOS

    di

    call    ATA_Set8BitMode

    ld      hl,bufATACmdResponse
    call    ATA_DoIdentify

    ld		de,strATAFieldSerial
	ld		c,B_STROUT
	DoBIOS
    ld      hl,bufATACmdResponse
    call    PrintSerialNumber
    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS
    
    ld		de,strATAFieldModel
	ld		c,B_STROUT
	DoBIOS
    ld      hl,bufATACmdResponse
    call    PrintModelNumber
    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

    ld      hl,bufATACmdResponse
    call    PrintSectorCount
    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

    ; Read in sector 0 to get the BPB.
    ld      hl,bufATASectorBuffer
    ld      (ATA_DataBuffer),hl
    ld      a,1
    ld      (ATA_SectorsToRead),a
    ld      a,0
    ld      (ATA_LBA_Lo),a
    ld      (ATA_LBA_Mid),a
    ld      (ATA_LBA_Hi),a
    call    ATA_ReadLBASector

    ; Copy sector to the BPB buffer.
    ld      hl,bufATASectorBuffer
    ld      de,bufBPB
    ld      bc,512
    ldir

    ; Populate some fields.
    ld      ix,bufBPB
    ld      l,(ix+Fat12BPB.reservedSectors)
    ld      h,(ix+Fat12BPB.reservedSectors+1)
    ld      (sectorFATStart),hl

    call    PrintBPBInfo

    ld      hl,bufATASectorBuffer
    ld      (ATA_DataBuffer),hl
    ld      a,1
    ld      (ATA_SectorsToRead),a
    ; sector 536
    ld      a,$F8       ; todo: determine this programmatically. I just know this is where the root is on this disk
    ld      (ATA_LBA_Lo),a
    ld      a,$01
    ld      (ATA_LBA_Mid),a
    ld      a,0
    ld      (ATA_LBA_Hi),a
    call    ATA_ReadLBASector

    ; Get a directory entry.
    call    PrintDirectoryEntries

    ei

    ret

;;;;;;;;;;;;;;;;
PrintDirectoryEntries:

    ld      ix,bufATASectorBuffer
.printDirectory:
    ld      a,(ix+0)
    cp      DIR_ENTRY_IS_AVAILABLE
    jr      z,.advance
    cp      DIR_ENTRY_END_OF_TABLE
    jr      z,.done

    ; Get the file attribute and check if this is actually a file.
    ld      a,(ix+$0B)
    cp      $02
    jr      z,.advance
    cp      $08
    jr      z,.advance
    cp      $0F
    jr      z,.advance

    ; TODO: simplify
    push    ix
    pop     iy

    ld      b,8
.nameloop:
    push    bc
    ld      e,(iy)
    ld		c,B_CONOUT
    DoBIOS
    inc     iy
    pop     bc
    djnz    .nameloop

    push    ix
    ld      e," "
    ld      c,B_CONOUT
    DoBIOS
    pop     ix    

    ld      b,3
.extloop:
    push    bc
    ld      e,(iy)
    ld		c,B_CONOUT
    DoBIOS
    inc     iy
    pop     bc
    djnz    .extloop

    push    ix
    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS 
    pop     ix  

.advance:
    push    ix
    pop     hl
    ld      de,32
    add     hl,de
    push    hl
    pop     ix
    jr      .printDirectory

.done:
    ret


;;;;;;;;;;;;;;;;
PrintBPBInfo:
    ld		de,strBPBHeader
	ld		c,B_STROUT
	DoBIOS
    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

.volumeLabel:
    ld      hl,bufBPB
    ld      bc,Fat12BPB.volumeLabel
    add     hl,bc

    ld      bc,11
    ld      de,bufStringBuffer
    ldir    ; Copy label to string buffer

    ld      hl,bufStringBuffer
    push    hl
    ld      hl,strBPBLabel
    push    hl
    PROCYON P_PRINTF
    pop     hl
    pop     hl

.bytesPerSector:
    ld      hl,bufBPB
    ld      bc,Fat12BPB.bytesPerSector
    add     hl,bc
    ld      c,(hl)
    inc     hl
    ld      b,(hl)
    push    bc
    ld      hl,strBPBbps
    push    hl
    PROCYON P_PRINTF
    pop     hl
    pop     hl

.fsType:
    ld      hl,bufBPB
    ld      bc,Fat12BPB.fsType
    add     hl,bc

    ld      bc,8
    ld      de,bufStringBuffer
    ldir    ; Copy label to string buffer

    ld      hl,bufStringBuffer
    push    hl
    ld      hl,strBPBfsType
    push    hl
    PROCYON P_PRINTF
    pop     hl
    pop     hl

    ret

PrintSerialNumber:
    ; Input: HL is a ptr to the IDENTIFY response
    
    ; Serial number is at buf+20 to buf+38 with swapped endianness.
    ld      bc,20
    add     hl,bc

    ld      b,10
.loop:
    push    bc
    inc     hl
    push    hl
    ld		e,(hl)
	ld		c,B_CONOUT
	DoBIOS
    pop     hl
    dec     hl
    push    hl
    ld		e,(hl)
	ld		c,B_CONOUT
	DoBIOS
    pop     hl
    inc     hl
    inc     hl
    pop     bc
    djnz    .loop

    ret

PrintModelNumber:
    ; Input: HL is a ptr to the IDENTIFY response
    ; Serial number is at buf+54 to buf+92 with swapped endianness.
    ld      bc,54
    add     hl,bc

    ld      b,19
.loop:
    push    bc
    inc     hl
    push    hl
    ld		e,(hl)
	ld		c,B_CONOUT
	DoBIOS
    pop     hl
    dec     hl
    push    hl
    ld		e,(hl)
	ld		c,B_CONOUT
	DoBIOS
    pop     hl
    inc     hl
    inc     hl
    pop     bc
    djnz    .loop

    ret

PrintSectorCount:
    ; Input: HL is a ptr to the IDENTIFY response
    ; Sector count is a DWORD at buf+120
    ld      bc,120
    add     hl,bc

    ld      c,(hl)
    inc     hl
    ld      b,(hl)
    inc     hl
    push    bc  ; low 16 bits

    ld      c,(hl)
    inc     hl
    ld      b,(hl)
    
    pop     hl
    push    bc  ; low 16 bits
    push    hl  ; high 16 bits
     
    ld      hl,strATAFieldSectors
    push    hl
    PROCYON P_PRINTF
    pop     hl
    pop     hl
    pop     hl

    ret

ATA_Set8BitMode:
    ld      a,$01
    out     (ATA_REG_FEATURES),a

    ld      a,ATA_CMD_SET_FEATURE   ; SET-FEATURE
    out     (ATA_REG_COMMAND),a
    ret

ATA_DoIdentify:
    ; Send an IDENTIFY command.
    ; Write the 512-byte response to (HL).

    push    hl

    ; Select the master drive.
    ld      a,$A0
    out     (ATA_REG_DRIVESELECT),a
    ; Set sector count and LBA registers to 0
    ld      a,0
    out     (ATA_REG_SECTORCOUNT),a
    out     (ATA_REG_LBAHI),a
    out     (ATA_REG_LBAMID),a
    out     (ATA_REG_LBALO),a
    ld      a,ATA_CMD_IDENTIFY
    out     (ATA_REG_COMMAND),a

    call    ATA_PollDriveNotBusy
    call    ATA_PollDriveHasData

    ld		de,strATAIdent
	ld		c,B_STROUT
	DoBIOS

    ; Read 512 bytes into (HL)
    pop     hl
    ld      b,0
.readloop1:
    in      a,(ATA_REG_DATA)
    ld      (hl),a
    inc     hl
    djnz    .readloop1
.readloop2:
    in      a,(ATA_REG_DATA)
    ld      (hl),a
    inc     hl
    djnz    .readloop2

    ret

ATA_DrainBuffer:
    in      a,(ATA_REG_STATUS)
    cp      ATA_STATUS_DRQ
    ret     nz
    in      a,(ATA_REG_DATA)
    jr      ATA_DrainBuffer

;;;;;;;;;;;;;;;;
ATA_ReadLBASector:
    call    ATA_DrainBuffer

    ld      a,ATA_DRIVE_MASTER
    out     (ATA_REG_DRIVESELECT),a

    ; One sector
    ld      a,(ATA_SectorsToRead)
    out     (ATA_REG_SECTORCOUNT),a

    ; Write LBA value
    ; for now, just read sector 0
    ld      a,(ATA_LBA_Lo)
    out     (ATA_REG_LBALO),a
    ld      a,(ATA_LBA_Mid)
    out     (ATA_REG_LBAMID),a
    ld      a,(ATA_LBA_Hi)
    out     (ATA_REG_LBAHI),a

    ld      a,ATA_CMD_READ_SECTORS
    out     (ATA_REG_COMMAND),a

    call    ATA_PollDriveNotBusy
    call    ATA_PollDriveHasData

    ; Read 512 bytes into the sector buffer
    ld      hl,(ATA_DataBuffer)
    ld      b,0
.readloop1:
    in      a,(ATA_REG_DATA)
    ld      (hl),a
    inc     hl
    djnz    .readloop1
.readloop2:
    in      a,(ATA_REG_DATA)
    ld      (hl),a
    inc     hl
    djnz    .readloop2    

    ret

ATA_PollDriveNotBusy:
    ; Poll the status port until BSY is clear.
    in      a,(ATA_REG_STATUS)
    and     ATA_STATUS_BSY
    jr      z,ATA_PollDriveNotBusy
    ret

ATA_PollDriveHasData:
    ; Poll the status port until DRQ is set.
    in      a,(ATA_REG_STATUS)
    and     ATA_STATUS_DRQ
    jr      z,ATA_PollDriveHasData
    ret    

;;;;;;;;;;;;;;;;
    include "fat16.asm"

    PAGE 1
;;;;;;;;;;;;;;;;

strCRLF:
	db  13,10,0

strATADetect:   db "* Attempting to detect ATA drive at I/O $10.",13,10,0
strATAIdent:    db  "* Retrieving IDENTIFY data...",13,10,0

strATAFieldModel:   db  " Model number: ",0
strATAFieldFW:      db  " Firmware ver: ",0
strATAFieldSerial:  db  "Serial number: ",0
strATAFieldSectors: db  "      Sectors: %lx",13,10,0

strBPBHeader:       db  " B P B    I N F O ",0
strBPBLabel:        db  "           Label: %s",13,10,0
strBPBSectors:      db  "  No. of Sectors: %x",0
strBPBbps:          db  "Bytes per Sector: %d",13,10,0
strBPBmd:           db  "Media Descriptor: %x",0
strBPBfsType:       db  "Reported FS Type: %s",13,10,0

bufStringBuffer:    ds  64
printf_params:      dw  0

; ATA driver variables.
ATA_DataBuffer:     dw  0   ; Pointer to where data is read/written.
ATA_LBA_Lo:         db  0   ; LBA low 8 bits
ATA_LBA_Mid:        db  0   ; LBA mid 8 bits
ATA_LBA_Hi:         db  0   ; LBA high 8 bits
ATA_SectorsToRead:  db  0   ; Number of sectors to read.

    org $A000
bufATACmdResponse:  ds  512
bufATASectorBuffer: ds  512