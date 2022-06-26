;
;*************************************************************
;
;
;     G L O B A L   M A C R O S
;
;
;*************************************************************
;

; These macros were not in the original FP09 package.  asm6809
; cannot directly handle these constructs from the original:
;
; ALL    REG   D,CC,X,Y,U
; ALLPC  REG   D,CC,X,Y,U,PC
;
;        PSHS  #ALL
;        PULS  #ALLPC
;
; These macros provide a convenient replacement.
PSHS_ALL	macro
		PSHS	D,CC,X,Y,U
		endm

PULS_ALL	macro
		PULS	D,CC,X,Y,U
		endm

PULS_ALLPC	macro
		PULS	D,CC,X,Y,U,PC
		endm
