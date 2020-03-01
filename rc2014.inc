; Function code equates.
B_RESET			= 0
B_CONOUT        = 1
B_STROUT        = 2
B_CONIN         = 3
B_CONSTAT       = 4
B_STRIN         = 5

; Device IDs for BIOS functions
DEV_AUX			= 1 ; RS-232.
DEV_CON			= 2	; Console. Can be redirected.
DEV_SCREEN		= 5	; Screen.

MACRO	DoBIOS	
		rst	$20
ENDMACRO

	;; SIO equates
SIOA_C	EQU $80
SIOA_D	EQU $81
SIOB_C	EQU $82
SIOB_D	EQU $83