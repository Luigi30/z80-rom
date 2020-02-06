#target bin

#include "bios.inc"

#code 	CODE,0x8400,0x1000

START:
    ld		de,HelloWorld
	ld		c,B_STROUT
	DoBIOS
    ret

HelloWorld:
	.ascii	"Hi!",13,10,0,1