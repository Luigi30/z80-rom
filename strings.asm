	PAGE 1

strPrompt:
	dz	">"
strCRLF:
	db  13,10,0

HelloWorld:
	db	"Procyon/80 ROM Monitor - RC2014 SIO/2 64K",13,10,0

strYouEntered:
	dz	"You entered: "

strDbgCmd:
    dz  "Command: "

strDbgArg:
    dz  "    Arg: "

strCmdUnknown:
    dz  "*** Unrecognized command"

strCmdArgumentError:
	dz  "*** Argument error"

strBanner1:
	dz	"Procyon/80 ROM BIOS and Monitor"

strBanner2:
	dz	"Software by LuigiThirty"

strBanner3:
	dz	"Revision 02/13/1979"

strBanner4:
	dz	"here, it's always 1979"