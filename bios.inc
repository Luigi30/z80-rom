; Function code equates.
B_CONOUT        = 0
B_STROUT        = 1
B_CONIN         = 2
B_CONSTAT       = 3
B_STRIN         = 4

; Device IDs for BIOS functions
DEV_AUX			= 1 ; RS-232.
DEV_CON			= 2	; Console. Can be redirected.
DEV_SCREEN		= 5	; Screen.

MACRO	DoBIOS	
		rst	$20
ENDMACRO