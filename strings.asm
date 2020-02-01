strPrompt:
	.asciz	">"
strCRLF:
	.ascii	13,10,0

HelloWorld:
	.ascii	"Hello Z80!",13,10,0

strYouEntered:
	.asciz	"You entered: "

strDbgCmd:
    .asciz  "Command: "

strDbgArg:
    .asciz  "    Arg: "