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
; SRD N
;   MACRO TO LOGICALLY SHIFT D-REG N BITS OO
;   THE RIGHT. (1 <= N <= 8)
;
;   CALL: SRD N
;
;**********************************************
;
SRD1	macro
	LSRA
	RORB
	endm

SRD2	macro
	SRD1
	SRD1
	endm

SRD4	macro
	SRD2
	SRD2
	endm

;
;**********************************************
;
; SLD N
;   MACRO TO LOGICALLY SHIFT D-REG N BITS OO
;   THE LEFT. (1 <= N <= 8)
;
;   CALL: SLD N
;
;**********************************************
;
SLD1	macro
	LSLB
	ROLA
	endm

SLD2	macro
	SLD1
	SLD1
	endm

SLD4	macro
	SLD2
	SLD2
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

;
;**********************************************
;
;  IOP N
;
;    MACRO TO SET INVALID OPERATION STATUS BITS IN
;    THE TEMPORARY STATUS BYTES ON THE STACK FRAME
;    SETS IOP BIT AND INVALID OPERATION CODE.
;
;  CALL: IOP N
;    WHERE N IS A VALID INVALID OPERATION NUMBER
;   USES A REGISTER
;
; USES A-REGISTER
;
;**********************************************
;
IOP		macro
		LDA	#\1
		LBSR	IOPSUB	; SET IOP CODE,IOP BIT & RETURN A NAN
		endm

;
;**********************************************
;
;    XPLUSY --
;
;        THIS MACRO EFFICIENTLY ADDS THE 9-BYTE
;    FRACTION POINTED TO BY XREG TO THAT POINTED
;    TO BY YREG, LEAVING THE RESULT IN FRACTION
;    POINTED TO BY XREG.  CARRY OUT OF HIGH-ORDER
;    BIT IS IN CARRY FLAG.
;
;**********************************************
;
XPLUSY		macro
		LDD	7,X
		ADDD	7,Y
		STD	7,X
		LDD	5,X

		; ADCD	(5,Y)
		ADCB	1+5,Y
		ADCA	5,Y

		STD	5,X
		LDD	3,X

		; ADCD	(3,Y)
		ADCB	1+3,Y
		ADCA	3,Y

		STD	3,X
		LDD	1,X

		; ADCD	(1,Y)
		ADCB	1+1,Y
		ADCA	1,Y

		STD	1,X
		LDB	0,X
		ADCB	0,Y
		STB	0,X
		endm

;
;**********************************************
;
;    XSBTRY --
;
;        MACRO TO SUBTRACT 9-BYTE FRACTION POINTED
;    TO BY Y-REG FROM THAT AT X-REG, RESULT STORED
;    X-REG.  IT IS EFFICIENT.
;
;**********************************************
;
XSBTRY		macro
		LDD	7,X
		SUBD	7,Y

		STD	7,X
		LDD	5,X

		; SBCD (5,Y)
		SBCB	1+5,Y
		SBCA	5,Y

		STD	5,X
		LDD	3,X

		; SBCD (3,Y)
		SBCB	1+3,Y
		SBCA	3,Y

		STD	3,X
		LDD	1,X

		; SBCD (1,Y)
		SBCB	1+1,Y
		SBCA	1,Y

		STD	1,X
		LDB	0,X
		SBCB	0,Y
		STB	0,X
		endm
