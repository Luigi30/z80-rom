strPrompt:
	.asciz	">"
strCRLF:
	.ascii	13,10,0

HelloWorld:
	.ascii	"Procyon/80 ROM Monitor - RC2014 SIO/2 64K",13,10,0

strYouEntered:
	.asciz	"You entered: "

strDbgCmd:
    .asciz  "Command: "

strDbgArg:
    .asciz  "    Arg: "

strCmdUnknown:
    .asciz  "*** Unrecognized command"