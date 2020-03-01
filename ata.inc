; Function table
A_8BITMODE		    = 0     ; Set drive to 8-bit transfer mode.
A_DOIDENTIFY        = 1     ; Execute an IDENTIFY command.
A_DRIVENOTBUSY      = 2     ; Spin until the drive is not busy.
A_DRIVEHASDATA      = 3     ; Spin until the drive has data to send.
A_READLBASECTOR     = 4     ; Read LBA sectors into memory.

;;;;;;;;;;;;;;;;;;;;;;;;;
; Register bits
ATA_IO_BASE         = $10
ATA_REG_DATA        = ATA_IO_BASE+0 ; R/W
ATA_REG_ERROR       = ATA_IO_BASE+1 ; R
ATA_REG_FEATURES    = ATA_IO_BASE+1 ; W
ATA_REG_SECTORCOUNT = ATA_IO_BASE+2 ; R/W
ATA_REG_LBALO       = ATA_IO_BASE+3 ; R/W
ATA_REG_LBAMID      = ATA_IO_BASE+4 ; R/W
ATA_REG_LBAHI       = ATA_IO_BASE+5 ; R/W
ATA_REG_DRIVESELECT = ATA_IO_BASE+6 ; R/W
ATA_REG_STATUS      = ATA_IO_BASE+7 ; R
ATA_REG_COMMAND     = ATA_IO_BASE+7 ; W

ATA_ERROR_AMNF      = $01
ATA_ERROR_TKZNF     = $02
ATA_ERROR_ABRT      = $04
ATA_ERROR_MCR       = $08
ATA_ERROR_IDNF      = $10
ATA_ERROR_MC        = $20
ATA_ERROR_UNC       = $40
ATA_ERROR_BBK       = $80

ATA_STATUS_ERR      = $01
ATA_STATUS_IDX      = $02
ATA_STATUS_CORR     = $04
ATA_STATUS_DRQ      = $08   ; Drive Request
ATA_STATUS_SRV      = $10
ATA_STATUS_DF       = $20
ATA_STATUS_RDY      = $40   ; Ready
ATA_STATUS_BSY      = $80   ; Busy

ATA_DRIVE_MASTER    = $E0
ATA_DRIVE_SLAVE     = $F0

; Command bytes
ATA_CMD_READ_SECTORS= $20
ATA_CMD_IDENTIFY    = $EC
ATA_CMD_SET_FEATURE = $EF

    struct  ATA_LBA_Control
dataBuffer      dw  ; Pointer to where data is read/written.
LBA_Lo          db  ; LBA low 8 bits
LBA_Mid         db  ; LBA mid 8 bits
LBA_Hi          db  ; LBA high 8 bits
sectorsToRead   db  ; Number of sectors to read.
    endstruct

; Low-level ATA driver doesn't have a public API.
MACRO ATADRV cmd
    call    (ATA_FnTable+(3*cmd))
ENDMACRO