P_STRTOHEX8		= 0
P_STRTOHEX16	= 1
P_HEX8TOSTR		= 2
P_HEX16TOSTR	= 3
P_PRINTF        = 4
P_B2D8          = 5
P_B2D16         = 6
P_B2D32         = 7

; Function table base address.
PROCYON_PUBLIC_API_BASE = $F100

; Variable base address.
PROCAPI_DATA_BASE = $8300

; Offsets for public ProcAPI data values.
STRINGTOHEX_SRC     = PROCAPI_DATA_BASE     ; +0
STRINGTOHEX_DEST    = STRINGTOHEX_SRC+16    ; +16
HEXTOSTRING_SRC     = STRINGTOHEX_DEST+8    ; +24
HEXTOSTRING_DEST    = HEXTOSTRING_SRC+4     ; +28

; Calls the function ID.
MACRO PROCYON cmd
    call    (PROCYON_PUBLIC_API_BASE+(3*cmd))
ENDMACRO
