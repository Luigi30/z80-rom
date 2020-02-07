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