; http://read.pudn.com/downloads77/ebook/294884/FAT32%20Spec%20%28SDA%20Contribution%29.pdf

    struct Fat12BPB
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