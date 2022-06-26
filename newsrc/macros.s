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

;
;**********************************************
;
;  INCREMENT AND DECREMENT 16 BIT REGISTERS
;
;**********************************************
;
INCX		macro
		LEAX 1,X
		endm

DECX		macro
		LEAX -1,X
		endm

INCY		macro
		LEAY 1,Y
		endm

DECY		macro
		LEAY -1,Y
		endm

INCU		macro
		LEAU 1,U
		endm

DECU		macro
		LEAU -1,U
		endm

INCS		macro
		LEAS 1,S
		endm

DECS		macro
		LEAS -1,S
		endm

INCD		macro
		INCB
		BNE	666F
		INCA
666
		endm

DECD		macro
		TSTB
		BNE	668F
		DECA
668		DECB
		endm
