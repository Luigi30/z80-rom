    PAGE 1

    include "fat16.inc"

    PAGE 2
bufBPB:         ds  512
sectorFATStart: dw  0       ; What sector does the FAT start in?