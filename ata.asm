    PAGE 1

    include "ata.inc"

ATA_FnTable:
	jp	_ATA_Set8BitMode        ; 0
    jp  _ATA_DoIdentify         ; 1
    jp  _ATA_PollDriveNotBusy   ; 2
    jp  _ATA_PollDriveHasData   ; 3
    jp  _ATA_ReadLBASector      ; 4
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_ATA_Set8BitMode:
    ; Send an ATA command to the device.
    ; Sets the device to 8-bit transfer mode.
    ld      a,$01
    out     (ATA_REG_FEATURES),a

    ld      a,ATA_CMD_SET_FEATURE   ; SET-FEATURE
    out     (ATA_REG_COMMAND),a
    ret

_ATA_PollDriveNotBusy:
    ; Poll the status port until BSY is clear.
    in      a,(ATA_REG_STATUS)
    and     ATA_STATUS_BSY
    jr      nz,_ATA_PollDriveNotBusy
    ret

_ATA_PollDriveHasData:
    ; Poll the status port until DRQ is set.
    in      a,(ATA_REG_STATUS)
    and     ATA_STATUS_DRQ
    jr      z,_ATA_PollDriveHasData
    ret    

_ATA_DoIdentify:
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

    call    _ATA_PollDriveNotBusy
    call    _ATA_PollDriveHasData

    ld		de,strATAIdent
	ld		c,B_STROUT
	DoBIOS

    ; Read 512 bytes into (HL).
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;

_ATA_DrainBuffer:
    in      a,(ATA_REG_STATUS)
    cp      ATA_STATUS_DRQ
    ret     nz
    in      a,(ATA_REG_DATA)
    jr      _ATA_DrainBuffer

_ATA_ReadLBASector:
    ; Read a sector.
    ; The sector number is set with the ATA_LBA_Lo/Mid/Hi variables.
    ; Consecutive sectors are read into ATA_DataBuffer.

    ; HL is a pointer to an ATA_LBA_Control structure.
    push    hl
    pop     ix

    ; TODO: only supports one sector at a time.
    call    _ATA_DrainBuffer

    ld      a,ATA_DRIVE_MASTER
    out     (ATA_REG_DRIVESELECT),a

    ; One sector
    ld      a,(ix+ATA_LBA_Control.sectorsToRead)
    out     (ATA_REG_SECTORCOUNT),a

    ; Write LBA value
    ; for now, just read sector 0
    ld      a,(ix+ATA_LBA_Control.LBA_Lo)
    out     (ATA_REG_LBALO),a
    ld      a,(ix+ATA_LBA_Control.LBA_Mid)
    out     (ATA_REG_LBAMID),a
    ld      a,(ix+ATA_LBA_Control.LBA_Hi)
    out     (ATA_REG_LBAHI),a

    ld      a,ATA_CMD_READ_SECTORS
    out     (ATA_REG_COMMAND),a

    ATADRV  A_DRIVENOTBUSY
    ATADRV  A_DRIVEHASDATA

    ; Read 512 bytes into the sector buffer
    ld      l,(ix+ATA_LBA_Control.dataBuffer)
    ld      h,(ix+ATA_LBA_Control.dataBuffer+1)
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

    PAGE 2

bufATACmdResponse:  ds  512 ; One sector buffer for command responses.
