    OUTPUT  "out/hextest.bin"

    org $9000

    include "procapi.inc"
    include "vdpbios.inc"
    include "rc2014.inc"
    include "ata.inc"

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

    ; VDPBIOS VDP_Reset
    ; VDPBIOS VDP_GoTextMode
	
    ; VDPBIOS VDP_Reset
    ; VDPBIOS VDP_GoBitmapMode

    ei

    ret

;;;;;;;;;;;;;;;;

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

    ld      bc,123
    add     hl,bc

    push    hl
    ld      a,(hl)
	ld		(HEXTOSTRING_SRC),a
    PROCYON P_HEX8TOSTR

	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS
    pop     hl
    dec     hl    
    push    hl
    ld      a,(hl)
	ld		(HEXTOSTRING_SRC),a
	PROCYON P_HEX8TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS
    pop     hl
    dec     hl    
    push    hl
    ld      a,(hl)
	ld		(HEXTOSTRING_SRC),a
	PROCYON P_HEX8TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS
    pop     hl
    dec     hl    
    push    hl
    ld      a,(hl)
	ld		(HEXTOSTRING_SRC),a
	PROCYON P_HEX8TOSTR
	ld		de,HEXTOSTRING_DEST
	ld		c,B_STROUT
	DoBIOS
    pop     hl
    dec     hl 

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

    ; Poll the status port until DRQ is set.
.loop:
    in      a,(ATA_REG_STATUS)
    and     $08
    jr      z,.loop

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

;;;;;;;;;;;;;;;;

DrawVerticalLine:
    ; inputs:   (C,B) is (X,Y)
    ;           A is length in px
.loop:
    push    af
    push    bc
    call    VDP_PlotPixel
    pop     bc
    pop     af
    inc     b
    cp      b
    ret     z
    jr      .loop

; set the next address of vram to read
;       DE = address
tmsreadaddr:
        ld      a, e                    ; send lsb
        out     (VDP_PORT_REGS), a
        ld      a, d                    ; mask off msb to max of 16KB
        and     $3F
        out     (VDP_PORT_REGS), a             ; send msb
        ret

; set operation for VDP_PlotPixel to perform
;       HL = pixel operation (tmsclearpixel, tmssetpixel)
VDP_SelectPixelOp:
    ld      (maskop), hl
    ret

; set or clear pixel at X, Y position
;       B = Y position
;       C = X position
VDP_PlotPixel:
        ld      a, b                    ; don't plot Y coord > 191
        cp      192
        ret     nc
        VDPBIOS VDP_GetPixelAddress     ; get address for X/Y coord
        call    tmsreadaddr             ; set read within pattern table
        ld      hl, masklookup          ; address of mask in table
        ld      a, c                    ; get lower 3 bits of X coord
        and     7
        ld      b, 0
        ld      c, a
        add     hl, bc
        ld      a, (hl)                 ; get mask in A
        ld      c, VDP_PORT_VRAM        ; get previous byte in B
        in      b, (c)
maskop:
        or      b                       ; mask bit in previous byte
        ld      b, a
        VDPBIOS VDP_SetVRAMWriteAddress ; set write address within pattern table
        out     (c), b
        ret
masklookup:
        defb 80h, 40h, 20h, 10h, 8h, 4h, 2h, 1h

VDP_DrawVerticalStrip:
    ; Graphics II mode vertical strip.
    ; VRAM address should be set before calling this function.
    ; Inputs:
    ; A - pixel mask to use
    ; B - height
    out     (VDP_PORT_VRAM),a
    VRAMWait
    djnz    VDP_DrawVerticalStrip
    ret

VDP_B_StringOut:
    ld      a, (hl)                 ; get the current byte from ram
    cp      0                       ; return when NULL is encountered
    ret     z
    out     (VDP_PORT_VRAM), a             ; send it to vram
    defs    14/tmswait, 0         ; nops to waste time
    inc     hl                      ; next byte
    jr      VDP_B_StringOut

strBanner1:
	dz	"Procyon/80 ROM BIOS and Monitor"

strBanner2:
	dz	"Software by LuigiThirty"

strBanner3:
	dz	"Revision 02/12/1979"

strBanner4:
	dz	"here, it's always 1979"

strCRLF:
	db  13,10,0

HelloWorld:
	db	    "TMS9918 ASCII Thingy",13,10,0

BannerData:
    db      "****************************************"
    db      "* P R O C Y O N / 8 0    M O N I T O R *"
    db      "*                                      *"
    db      "*  Official Operating System of 1979!  *"
    db      "*                                      *"
    db      "*      VDP Routine Test Program 1      *"
    db      "****************************************"
    db      0

strATADetect:   db "* Attempting to detect ATA drive at I/O $10.",13,10,0
strATAIdent:    db  "* Retrieving IDENTIFY data...",13,10,0

strATAFieldModel:   db  " Model number: ",0
strATAFieldFW:      db  " Firmware ver: ",0
strATAFieldSerial:  db  "Serial number: ",0
strATAFieldSectors: db  "      Sectors: $",0

bufATACmdResponse:  ds  512

bufStringBuffer     ds  64

LHexToString_Source:	ds 4
LHexToString_Dest:		ds 4