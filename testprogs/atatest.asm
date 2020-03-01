    OUTPUT  "testprogs/out/atatest.bin"

	DEFPAGE 1, 09000h, *    ; CODE
    DEFPAGE 2, *, *         ; DATA

    incdir  ".."
    include "procapi.inc"
    include "rc2014.inc"

    PAGE 1
Entry:
    CODE @ 9000h
    jp      START

    include "ata.asm"
    PAGE 1
    include "fat16.asm"
    PAGE 1

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

;;;
MultU32:
    ; http://map.grauw.nl/articles/mult_div_shifts.php#mult
    ; BC * DE = BC:HL
    ; Unsigned 16-bit multiply, 32-bit result.
    ld a,c
    ld c,b
    ld hl,0
    ld b,16
.Mult32_Loop:
    add hl,hl
    rla
    rl c
    jr nc,.Mult32_NoAdd
    add hl,de
    adc a,0
    jp nc,.Mult32_NoAdd
    inc c
.Mult32_NoAdd:
    djnz .Mult32_Loop
    ld b,c
    ld c,a
    ret

;;;;;;;;;;;;;;;;;;;;;

teststr: db "result %ld",13,10,0

strDir_fsize: db "%ld",0
strDir_isdir: db "<DIR>",0

strDir_firstCluster:    db "%x",0

START:
    ld		de,strATADetect
	ld		c,B_STROUT
	DoBIOS

    di

    ; ld      bc,1000
    ; ld      de,1000
    ; call    MultU32
    ; push    bc
    ; push    hl
    ; ld      hl,teststr
    ; push    hl
    ; PROCYON P_PRINTF
    ; pop     hl
    ; pop     hl
    ; pop     hl

    ; TODO: Check for a valid response so we can fail if no controller
    ATADRV  A_8BITMODE

    ; TODO: Check for a valid response so we can fail if no drive
    ld      hl,bufATACmdResponse
    ATADRV  A_DOIDENTIFY

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

    ; Read the first partition's info.
    FAT16   F16_INITPARTDATA

    cp      a,0
    jp      nz,.hdError

    ; Populate some fields.
    ld      ix,driveA.bufBPB
    ld      l,(ix+Fat16BPB.reservedSectors)
    ld      h,(ix+Fat16BPB.reservedSectors+1)
    ld      (driveA.sectorFATStart),hl

    call    PrintBPBInfo

    ld      a,0
    FAT16   F16_FIRSTFILEINROOT

    ; ld      iy,lbaControlBlock
    ; ld      (iy+ATA_LBA_Control.dataBuffer),(low bufATASectorBuffer)
    ; ld      (iy+ATA_LBA_Control.dataBuffer+1),(high bufATASectorBuffer)
    ; ld      a,1
    ; ld      (iy+ATA_LBA_Control.sectorsToRead),a
    ; ; todo: determine this programmatically.
    ; ld      a,$2D
    ; ld      (iy+ATA_LBA_Control.LBA_Lo),a
    ; ld      a,$02
    ; ld      (iy+ATA_LBA_Control.LBA_Mid),a
    ; ld      a,$00
    ; ld      (iy+ATA_LBA_Control.LBA_Hi),a

    ; ld      hl,lbaControlBlock
    ; ATADRV  A_READLBASECTOR

    ; Get a directory entry.
    call    PrintRootDirectory

    ei

    ret

.hdError:
    ld      bc,0
    ld      c,a
    push    bc
    ld      hl,strHDDError
    push    hl
    PROCYON P_PRINTF
    pop     hl
    pop     hl

    ret

;;;;;;;;;;;;;;;;
dir_PrintFileName:
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

    ret

;;;;;;;;;;;;;;;;
DIR_PrintFileSize:
    push    ix

    ; print the file size at ix+$1C
    ld      l,(ix+$1C)
    ld      h,(ix+$1D)
    ld      c,(ix+$1E)
    ld      b,(ix+$1F)
    push    hl
    push    bc
    ld      hl,strDir_fsize
    push    hl
    PROCYON P_PRINTF
    pop     hl
    pop     hl
    pop     hl

    pop     ix
    ret

DIR_PrintDirectorySymbol:
    push    ix

    ; directories have <DIR> instead
    ld      hl,strDir_isdir
    push    hl
    PROCYON P_PRINTF
    pop     hl
    pop     ix

    push    ix
    ld      e," "
    ld      c,B_CONOUT
    DoBIOS
    pop     ix

    ret

;;;;;;;;;;;;;;;;
PrintRootDirectory:
    ld      ix,bufATASectorBuffer
.printDirectory:
    ld      a,(ix+0)
    cp      DIR_ENTRY_IS_AVAILABLE
    jr      z,.advance
    cp      DIR_ENTRY_END_OF_TABLE
    jr      z,.done

    ; Do we show this file in a DIR?
    ld      a,(ix+$0B)
    bit     DIR_ATTRIB_BIT_HIDDEN,a
    jr      nz,.advance
    bit     DIR_ATTRIB_BIT_SYSTEM,a
    jr      nz,.advance
    bit     DIR_ATTRIB_BIT_VOLUMELABEL,a
    jr      nz,.advance
    cp      DIR_ATTRIB_IS_VFAT_LFN  ; combo of flags
    jr      z,.advance

    push    ix
    call    dir_PrintFileName
    pop     ix

    push    ix
    ld      e," "
    ld      c,B_CONOUT
    DoBIOS
    pop     ix

    ; Is this a folder?
    ld      a,(ix+$0B)
    bit     DIR_ATTRIB_BIT_SUBDIRECTORY,a
    call    z,DIR_PrintFileSize
    ld      a,(ix+$0B)
    bit     DIR_ATTRIB_BIT_SUBDIRECTORY,a
    call    nz,DIR_PrintDirectorySymbol

    push    ix
    ld      e," "
    ld      c,B_CONOUT
    DoBIOS
    pop     ix

.firstCluster:
    push    ix
    ld      l,(ix+$1A)
    ld      h,(ix+$1B)
    push    hl
    ld      hl,strDir_firstCluster
    push    hl
    PROCYON P_PRINTF
    pop     hl
    pop     hl
    pop     ix

.newline:
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
    ld      hl,driveA.bufBPB
    ld      bc,Fat16BPB.volumeLabel
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
    ld      hl,driveA.bufBPB
    ld      bc,Fat16BPB.bytesPerSector
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
    ld      hl,driveA.bufBPB
    ld      bc,Fat16BPB.fsType
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

;;;;;;;;;;;;;;;;

strCRLF:
	db  13,10,0

strATADetect:   db "* Attempting to detect ATA drive at I/O $10.",13,10,0
strATAIdent:    db  "* Retrieving IDENTIFY data...",13,10,0

strHDDError:  db  "*** Error %d reading fixed disk."

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

lbaControlBlock     ATA_LBA_Control

bufATASectorBuffer: ds  512 ; ATA sector buffer.