;
;TTL ROUTINES TO CHECK SPECIAL CASES AND INVALID OPS.
;NAM CHECK
;
; LINKING LOADER DEFINTIONS
;
; XDEF	CKINVD,CHKZER,CHKINF,DIVZER
;
; XREF	RTAR1,IOPSUB,RTINF,ISDNRM
;
; REVISION HISTORY:
;   DATE	PROGRAMMER     REASON
;
;  23.MAY.80	G. STEVENS     ORIGINAL
;  28.MAY.80	G. STEVENS     REWRITE CKINVD
;  03.JUNE.80	G. STEVENS     MAKE CKINVD HANDLE NAN,ZEROS
;			       AND INFINITIES CORRECTLY
;  21.AUG.80	G. STEVENS     REMOVE IOP 17 FROM DIVZER
;  28.JUN.22    @thorpej       Updated for asm6809.  New comments
;                              are in mixed-case.
;
;*****************************************************************
;
;  HERE ARE SOME OF THE COMPONENT ROUTINES
; FOR THE FP09. THEY INCLUDE CHKZER, CHECK
; ZERO AGAINST THE ROUNDING MODES; CHECK
; CHECK INFINITY AGAINST A/P MODES OF
; CLOSURE; DIVZER, HANDLES DIVISION BY ZERO;
; RTNAN, BUILD UP A "NAN" WITH PROPER
; NAN ADDRES INSERTED.
;
;*****************************************************************
;
;  PROCEDURE CHKZER
;
;  THIS ROUTINE CHECKS ZERO AGAINST ROUNDING
; MODES IN A FLP ADDITION WHEN BOTH OPERANDS
; ARE ZERO IN ORDER TO RETURN A ZERO RESULT
; OF THE CORRECT SIGN. IF SIGNS ARE THE SAME
; A ZERO OF THAT SIGN IS RETURNED. IF THE
; SIGN ARE OPPOSITE THEN +0 IS RETURNED
; IN ROUDING MODES RN,RZ,RP AND -O IS
; RETURNED IN ROUNDING MODE RM.
;
; RETURN A ZERO TO RESULT
;
CHKZER
	LBSR RTAR1
	;
	; NOW CHECK TO SEE IF THE SIGN NEEDS
	; MODIFYING.
	;
	LDA	ARG1,U
	EORA	ARG2,U
	;
	; IF THE SIGNS ARE NOT EQUAL, CHECK THE ROUNDING
	; MODE TO DETERMINE THE PROPER SIGN.
	;
	BGE	1F
	LDA	[PFPCB,U]
	ANDA	#CTLRND		; GET ROUNDING MODE INFO.
	CMPA	#RM
	BLT	2F		; Not #RM
	LDA	#BIT7
	STA	RESULT,U	; RETURN -0
	RTS
2
	CLR	RESULT,U	; RETURN +0
1	RTS

;*****************************************************************
;
;  PROCEDURE  CHKINF
;
;   THIS ROUTINE CHECKS INFINITY AGAINST
; CLOSURE MODES IN A FLP ADDITION WHEN
; BOTH OPERANDS ARE INFINITY TO DETERMINE
; WHETHER TO RETURN INFINITY OR A NAN
; WITH PROPER INVALID OPERATION CODE
;
;
; CHECK FOR A/P MODES
;
CHKINF
	LDA	[PFPCB,U]
	ANDA	#BIT0

	BLE	1F		; Branch if not in Affine Mode.
	LDA	ARG1,U
	EORA	ARG2,U
	*
	* IF SIGNS THE SAME RETURN INFINITY
	* OF THAT SIGN.
	*
	BLE	2F		; Branch if signs differ.
	LBSR	RTAR1
	RTS
2
	;
	; IF SIGNS DIFFER RETURN "NAN" AND
	; SET IOP = 2
	;
	IOP	2		; (+INF)+(-INF); AFFINE MODE
	RTS
1
	;
	; IN THE PROTECTIVE MODE RETURN NAN
	; AND SET IOP = 8
	;
	IOP	8		; +/- INF; PROTECTIVE MODE
	RTS			; RETURN

;*****************************************************************
;
; PROCEDURE  DIVZER
;
;  THIS ROUTINE HANDLES THE CASE OF DIVISION
; BY ZERO.
;
; ON ENTRY: ARG2 CONTAINS A TRUE ZERO
;	    U - STACK FRAME POINTER
;
; ON EXIT: RESULT CONTAINS AN INFINITY W/
;	   SIGN OF THE INPUT ARGUMENT.
;	   U, S - UNCHANGED
;	   X,Y,D,CC - DESTROYED
;
; OPERATION: THE DIVISION BY ZERO FLAG IN TSTAT IS SET
; AND AN INFINITY OF THE SIGN OF THE INPUT ARGUMENT IS
; RETURNED IN THE STACK FRAME RESULT.
;
;
; CHECK DIVISION BY ZERO TRAP ENABLE
;
DIVZER
	LDA	TSTAT,U
	ORA	#ERRDZ
	STA	TSTAT,U
	LBSR	RTINF
	RTS			; RETURN

;*****************************************************************
;
; PROCEDURE  CKINVD
;
;     CKINVD CHECKS FOR AN INVALID RESULT OF AN ARITHMETIC
; OPERATION. IF THE RESULT IS UNORMALIZED AND THE DESTINATION
; IS SINGLE OR DOUBLE THEN SIGNAL IOP. = 16 AND RETURN A
; NON TRAPPING NAN.
;
; XXXJRT The logic here matches the old code, but the comments
; are a mess.
;
CKINVD
	;
	; CHECK FOR ZERO OR NAN OR INFINITY
	;
	LDD	EXPR,U
	CMPD	#INFEX		; Infinity (or NaN)?
	BEQ	1F
	CMPD	#ZEROEX		; Zero?
	BEQ	1F
	;
	; CHECK THE PRECISION OF THE RESULT
	;
	LDA	RPREC,U
	CMPA	#DBL		; Single or double?
	BGT	1F		; Nope, must be extended.
	LBSR	ISDNRM		; CHECK FOR DENORMALZED
	BNE	2F		; Branch if not denormalized.

	; RESULT IS DENORMALIZD
	LDD	EXPR,U		; SUBTRACT BIAS FROM EXPONENT
	SUBD	#01
	STD	EXPR,U
	RTS
2
	LDA	FRACTR,U
	BLT	1F
	IOP	16		; Not normalized, signal invalid operation.
1
	RTS
