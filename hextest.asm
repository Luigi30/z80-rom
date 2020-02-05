#target bin

#include "bios.inc"

#code 	CODE,0x9000,0x1000

START:
    ld		de,HelloWorld
	ld		c,B_STROUT
	DoBIOS
    ret

HelloWorld:
	.ascii	"Uploaded HEX works!",13,10,0