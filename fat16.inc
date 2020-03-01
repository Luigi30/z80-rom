; http://read.pudn.com/downloads77/ebook/294884/FAT32%20Spec%20%28SDA%20Contribution%29.pdf

; Function table
F16_OPENFILE		= 0     ;
F16_CLOSEFILE       = 1     ; 
F16_INITPARTDATA    = 2     ;
F16_FIRSTFILEINROOT = 3     ;

    struct Fat16BPB
jump                ds  3
oemName             ds  8
bytesPerSector      dw  
sectorsPerCluster   db  
reservedSectors     dw  ; 16-bit
numberOfFATs        db  
maxRootDirEntries   dw  
numLogicalSectors16 dw  
mediaDescriptor     db  
sectorsPerFAT       dw
sectorsPerTrack     dw
numHeads            dw
hiddenSectors       dd  ; 32-bit
numLogicalSectors32 dd
driveNum            db
reserved            db  ; always 0
bootSignature       db
volumeID            dd
volumeLabel         ds  11
fsType              ds  8
padding             ds  448
bsignature          dw
    endstruct

DIR_ENTRY_END_OF_TABLE  = $00
DIR_ENTRY_IS_DOT        = $2E
DIR_ENTRY_IS_AVAILABLE  = $E5

;;;;;
DIR_ATTRIB_READONLY     = $01
DIR_ATTRIB_HIDDEN       = $02
DIR_ATTRIB_SYSTEM       = $04
DIR_ATTRIB_VOLUMELABEL  = $08
DIR_ATTRIB_SUBDIRECTORY = $10
DIR_ATTRIB_ARCHIVE      = $20
DIR_ATTRIB_DEVICE       = $40
DIR_ATTRIB_RESERVED     = $80

DIR_ATTRIB_BIT_READONLY     = 0
DIR_ATTRIB_BIT_HIDDEN       = 1
DIR_ATTRIB_BIT_SYSTEM       = 2
DIR_ATTRIB_BIT_VOLUMELABEL  = 3
DIR_ATTRIB_BIT_SUBDIRECTORY = 4
DIR_ATTRIB_BIT_ARCHIVE      = 5
DIR_ATTRIB_BIT_DEVICE       = 6
DIR_ATTRIB_BIT_RESERVED     = 7

DIR_ATTRIB_IS_VFAT_LFN  = $0F   ; combo of flags

;;;;;;;;;;;;;;;;;;;;
    struct FILE_STRUCT
open            db 
filename        ds  8   ; Filename
extension       ds  3   ; File extension
curBlock        dw      ; Current blockf
startCluster    dw      ; First cluster of this file.
path            ds  64  ; Full path to this file.
    endstruct

    struct  DRIVE_FS_DATA
sectorPtnStart  dd      ; What sector does this partition start in?
sectorFATStart  dd      ; What sector does the FAT start in?
bytesPerCluster dw      ; How many bytes per cluster?
rootDirSector   dd      ; What sector is the root directory in?
bufBPB          ds  512 ; Buffer for a drive's BPB.
    endstruct

; Calls the function ID.
MACRO FAT16 cmd
    call    (FAT16_FnTable+(3*cmd))
ENDMACRO