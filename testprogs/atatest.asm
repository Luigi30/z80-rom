    OUTPUT  "testprogs/out/atatest.bin"

	DEFPAGE 1, 09000h, *    ; CODE
    DEFPAGE 2, *, *         ; DATA

    incdir  ".."
    include "procapi.inc"
    include "rc2014.inc"
    include "ata.inc"
    include "fat16.inc"

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

    ld		de,strATAFieldSectors
	ld		c,B_STROUT
	DoBIOS
    ld      hl,bufATACmdResponse
    call    PrintSectorCount
    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

    ld      hl,bufATASectorBuffer
    ld      (ATA_DataBuffer),hl
    ld      a,1
    ld      (ATA_SectorsToRead),a
    ld      a,0
    ld      (ATA_LBA_Lo),a
    ld      (ATA_LBA_Mid),a
    ld      (ATA_LBA_Hi),a
    call    ATA_ReadLBASector

    call    PrintBPBInfo

    ei

    ret

;;;;;;;;;;;;;;;;

strBPBHeader:   db  " B P B    I N F O ",0
strBPBLabel:    db  "           Label: ",0
strBPBSectors:  db  "  No. of Sectors: ",0
strBPBbps:      db  "Bytes per Sector: ",0
strBPBmd:       db  "Media Descriptor: ",0
strBPBfsType:   db  "Reported FS Type: ",0

PrintBPBInfo:
    ld		de,strBPBHeader
	ld		c,B_STROUT
	DoBIOS
    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

.volumeLabel:
    ld      de,strBPBLabel
    ld      c,B_STROUT
    DoBIOS

    ld      hl,bufATASectorBuffer
    ld      bc,Fat12BPB.volumeLabel
    add     hl,bc

    ld      b,11
.vlLoop:
    push    bc
    push    hl
    ld		e,(hl)
	ld		c,B_CONOUT
	DoBIOS
    pop     hl
    pop     bc
    inc     hl
    djnz    .vlLoop

    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

.bytesPerSector:
    ld      de,strBPBbps
    ld      c,B_STROUT
    DoBIOS

    ld      hl,bufATASectorBuffer
    ld      bc,Fat12BPB.bytesPerSector
    add     hl,bc
    ld      c,(hl)
    inc     hl
    ld      b,(hl)
    push    bc
    pop     hl
    call    B2D16
    push    hl
    pop     de
	ld		c,B_STROUT
	DoBIOS  

    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS  

.fsType:
    ld      de,strBPBfsType
    ld      c,B_STROUT
    DoBIOS

    ld      hl,bufATASectorBuffer
    ld      bc,Fat12BPB.fsType
    add     hl,bc

    ld      b,8
.fsTypeLoop:
    push    bc
    push    hl
    ld		e,(hl)
	ld		c,B_CONOUT
	DoBIOS
    pop     hl
    pop     bc
    inc     hl
    djnz    .fsTypeLoop

    ld		de,strCRLF
	ld		c,B_STROUT
	DoBIOS

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
    push    hl

    ld      bc,120
    add     hl,bc

    ld      a,(hl)
    push    af      ;8
    inc     hl
    ld      a,(hl)
    push    af      ;16
    inc     hl
    ld      a,(hl)
    push    af      ;24
    inc     hl
    ld      a,(hl)
    
    ld      d,a
    pop     af
    ld      e,a
    pop     af
    ld      h,a
    pop     af
    ld      l,a
    call    B2D32
 	push    hl
    pop     de
	ld		c,B_STROUT
	DoBIOS   

    ;;
    ld		e," "
	ld		c,B_CONOUT
	DoBIOS
    ld		e,"("
	ld		c,B_CONOUT
	DoBIOS
    ld		e,"$"
	ld		c,B_CONOUT
	DoBIOS

    pop     hl
    ld      bc,123
    add     hl,bc

    push    hl
    ld      a,(hl)
	ld		(HEXTOSTRING_SRC),a
    PROCYON B_HEX8TOSTR

	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS
    pop     hl
    dec     hl    
    push    hl
    ld      a,(hl)
	ld		(HEXTOSTRING_SRC),a
	PROCYON B_HEX8TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS
    pop     hl
    dec     hl    
    push    hl
    ld      a,(hl)
	ld		(HEXTOSTRING_SRC),a
	PROCYON B_HEX8TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS
    pop     hl
    dec     hl    
    push    hl
    ld      a,(hl)
	ld		(HEXTOSTRING_SRC),a
	PROCYON B_HEX8TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS
    pop     hl
    dec     hl 

    ld		e,")"
	ld		c,B_CONOUT
	DoBIOS


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

    include "hex2ascii.z80"

;;;;;;;;;;;;;;;;

strCRLF:
	db  13,10,0

strATADetect:   db "* Attempting to detect ATA drive at I/O $10.",13,10,0
strATAIdent:    db  "* Retrieving IDENTIFY data...",13,10,0

strATAFieldModel:   db  " Model number: ",0
strATAFieldFW:      db  " Firmware ver: ",0
strATAFieldSerial:  db  "Serial number: ",0
strATAFieldSectors: db  "      Sectors: ",0

bufStringBuffer:    ds  64

; ATA driver variables.
ATA_DataBuffer:     dw  0   ; Pointer to where data is read/written.
ATA_LBA_Lo:         db  0   ; LBA low 8 bits
ATA_LBA_Mid:        db  0   ; LBA mid 8 bits
ATA_LBA_Hi:         db  0   ; LBA high 8 bits
ATA_SectorsToRead:  db  0   ; Number of sectors to read.

    org $A000
bufATACmdResponse:  ds  512
bufATASectorBuffer: ds  512