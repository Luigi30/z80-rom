    PAGE 1
    include "fat16.inc"

    ; Equivalent of "LD DE,(IY+LOCATION)"
MACRO   LD_DE_IX_PLUS location
    ld      e,(ix+location)
    ld      d,(ix+location+1)
ENDMACRO

    ; Equivalent of "LD DE,(IY+LOCATION)"
MACRO   LD_DE_IY_PLUS location
    ld      e,(iy+location)
    ld      d,(iy+location+1)
ENDMACRO

    ; Merge with Procyon API once integrated.
FAT16_FnTable:
    jp      FAT16_OpenFile                      ; 0 
    jp      FAT16_CloseFile                     ; 1
    jp      FAT16_InitPartitionData             ; 2
    jp      FAT16_FindFirstFileInRootDirectory  ; 3

FAT16_InitPartitionData:
    ; TODO: Drives B:, C:, D:

    ; Read in the MBR.
    ld      iy,lbaControlBlock

    ld      (iy+ATA_LBA_Control.dataBuffer),(low bufATASectorBuffer)
    ld      (iy+ATA_LBA_Control.dataBuffer+1),(high bufATASectorBuffer)
    ld      a,1
    ld      (iy+ATA_LBA_Control.sectorsToRead),a
    ld      a,0
    ld      (iy+ATA_LBA_Control.LBA_Lo),a
    ld      (iy+ATA_LBA_Control.LBA_Mid),a
    ld      (iy+ATA_LBA_Control.LBA_Hi),a

    ld      hl,lbaControlBlock
    ATADRV  A_READLBASECTOR

    ; Is this an MBR at all?
    ld      ix,bufATASectorBuffer+$1FE
    ld      a,(ix+0)
    cp      $55
    jp      nz,.noMBR
    ld      a,(ix+1)
    cp      $AA
    jp      nz,.noMBR

    ; All we need out of the MBR is the LBA sector of the first partition.
    ; We can use that to get the BPB.
    ld      ix,bufATASectorBuffer+$1C6
    ld      iy,driveA

    ; Load the start of the partition into the drive structure.
    ld      a,(ix+0)
    ld      (iy+DRIVE_FS_DATA.sectorPtnStart+0),a
    ld      a,(ix+1)
    ld      (iy+DRIVE_FS_DATA.sectorPtnStart+1),a
    ld      a,(ix+2)
    ld      (iy+DRIVE_FS_DATA.sectorPtnStart+2),a 
    ld      a,(ix+3)
    ld      (iy+DRIVE_FS_DATA.sectorPtnStart+3),a
    
    ; Read the BPB.
    ld      iy,lbaControlBlock
    ld      (iy+ATA_LBA_Control.dataBuffer),(low bufATASectorBuffer)
    ld      (iy+ATA_LBA_Control.dataBuffer+1),(high bufATASectorBuffer)
    ld      a,1
    ld      (iy+ATA_LBA_Control.sectorsToRead),a
    ld      a,(driveA.sectorPtnStart+0)
    ld      (iy+ATA_LBA_Control.LBA_Lo),a
    ld      a,(driveA.sectorPtnStart+1)
    ld      (iy+ATA_LBA_Control.LBA_Mid),a
    ld      a,(driveA.sectorPtnStart+2)
    ld      (iy+ATA_LBA_Control.LBA_Hi),a

    ld      hl,lbaControlBlock
    ATADRV  A_READLBASECTOR

    ; Copy sector to the BPB buffer.
    ld      hl,bufATASectorBuffer
    ld      de,driveA.bufBPB
    ld      bc,512
    ldir

    ld      a,0
    ret

.noMBR:
    ld      a,$FF
    ret

;;;;;
    ; File and directory functions here.
FAT16_OpenFile:
    ; Input: HL is a ptr to a filename
    ; Output: Returns a ptr to a fileStruct in DE
    ld  (tmpPtr),HL

    ; Read in the root directory structure from the disk.

    ; Iterate through the files looking for a matching file.

    ; Set up a FILE_STRUCT.

    ; Return a pointer to a FILE_STRUCT.

    ret

FAT16_CloseFile:
    ; Input: HL is a ptr to a fileStruct
    ; Output: n/a
    ld  (tmpPtr),HL

    ; Close the file in the fileStruct.

    ret

FAT16_FindFirstFileInRootDirectory:
    ; Input: A - drive number (0-3)

    ld      ix,driveBase
    ld      de,DRIVE_FS_DATA    ; length of structure
.loop:
    cp      a
    jr      z,.calculateRootDirSector
    add     ix,de
    dec     a
    jp      .loop

    ; IX is now the base of the drive data.

    ; On FAT12 and FAT16 volumes, the root directory must immediately follow the last file allocation table. 
    ; The location of the first sector of the root directory is computed as below: FirstRootDirSecNum = BPB_ResvdSecCnt + (BPB_NumFATs * BPB_FATSz16) 
    ; The size of the root directory on FAT12 and FAT16 volumes is computed using the contents of the BPB_RootEntCnt field.

.calculateRootDirSector:
    ld      iy,driveA.bufBPB
    ld      hl,0
    LD_DE_IY_PLUS Fat16BPB.sectorsPerFAT
    ld      b,(iy+Fat16BPB.numberOfFATs)
.addFATLength:
    add     hl,de
    djnz    .addFATLength
    ; HL = (sectorsPerFAT * numberOfFATs)

    LD_DE_IY_PLUS Fat16BPB.reservedSectors
    add     hl,de   ; HL = (sectorsPerFAT * numberOfFATs) + reservedSectors
    LD_DE_IX_PLUS DRIVE_FS_DATA.sectorPtnStart
    add     hl,de   ; HL = partitionBase + (sectorsPerFAT * numberOfFATs) + reservedSectors

.getRootDir:
    ld      iy,lbaControlBlock
    ld      (iy+ATA_LBA_Control.dataBuffer),(low bufATASectorBuffer)
    ld      (iy+ATA_LBA_Control.dataBuffer+1),(high bufATASectorBuffer)
    ld      a,1
    ld      (iy+ATA_LBA_Control.sectorsToRead),a
    ld      (iy+ATA_LBA_Control.LBA_Lo),l
    ld      (iy+ATA_LBA_Control.LBA_Mid),h
    ld      a,$00   ; TODO: root directory can't be past sector 65535.
    ld      (iy+ATA_LBA_Control.LBA_Hi),a

    ld      hl,lbaControlBlock
    ATADRV  A_READLBASECTOR

    ret

    PAGE 2

fatDriver_lbaControlBlock     ATA_LBA_Control

; TODO: most functions assume operation on A:
driveBase:
driveA:         DRIVE_FS_DATA
driveB:         DRIVE_FS_DATA
driveC:         DRIVE_FS_DATA
driveD:         DRIVE_FS_DATA

tmpPtr: dw  0

; A pointer to this structure is returned by FindFirstFile/FindNextFile functions.
fileStruct_tmp: FILE_STRUCT

; Room for 4 file structs.
fileStruct0:    FILE_STRUCT
fileStruct1:    FILE_STRUCT
fileStruct2:    FILE_STRUCT
fileStruct3:    FILE_STRUCT