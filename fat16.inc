; http://read.pudn.com/downloads77/ebook/294884/FAT32%20Spec%20%28SDA%20Contribution%29.pdf

    struct Fat12BPB
jump                ds  3
oemName             ds  8
bytesPerSector      dw  
sectorsPerCluster   db  
reservedSectors     dw  
numberOfFATs        db  
maxRootDirEntries   dw  
numLogicalSectors16 dw  
mediaDescriptor     db  
sectorsPerFAT       dw
sectorsPerTrack     dw
numHeads            dw
hiddenSectors       dd
numLogicalSectors32 dd
driveNum            db
reserved            db
bootSignature       db
volumeID            dd
volumeLabel         ds  11
fsType              ds  8
padding             ds  448
bsignature          dw
    endstruct