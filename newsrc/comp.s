;
; TTL   COMPONENT ROUTINES FOR DISPATCH
; NAM COMP
;
; LINKING LOADER DEFINITIONS
;
; XDEF	RTAR1,RTAR2,RTNAN,RTDNAN,RTZERO,RTINF
; XDEF	RTNAR2,MOVXOR,CLRES,CLTBL,MOVE
; XDEF	INFIN,ZERO,NAN,LARGE,NAN1,NAN4
; XDEF	NAN9,NAN10,IOPSUB,ISDNRM,DNMTBL,IOPSET
;
; XREF	FPMOVE,UNFLNT,CHKUNF
;
; REVISION HISTORY:
;   DATE	PROGRAMMER     REASON
;
;  28.MAY.80	G. STEVENS     ORIGINAL
;  30.MAY.80	G. STEVENS     REWRITE CLRES
;  06.JUN.80	G. STEVENS     REWORK CLRES & CLEAN UP DOC.
;  01.JUL.89	G. STEVENS     REMOVE DUPLICATE TABLES
;  17.JUL.80	G. STEVENS     ADD NAN__ PROCEDURES
;  29.JUL.80	G. WALKER      'CLRES' CLEARS ENTIRE FRACTION
;  04.AUG.80	G. STEVENS     'CLRES' HANDLES DOUBLE CORRECTLY
;  07.AUG.80	G. STEVENS     REMOVE NAN3 AND REPLACE LBSR'S
;  14.AUG.80	G. STEVENS     ADD UNDEFLOW ADJUST TO COMP
;  14.AUG.80	G. STEVENS     ADD ISDNRM FUNCTION
;  14.AUG.80	G. STEVENS     CHANGE PARAMETERS OF ISDNRM
;  27.AUG.80	J. BONEY       ADD IOPSET
;  26.JUN.22    @thorpej       Updated for asm6809.  New comments
;                              are in mixed-case.
;
;*****************************************************************
;
; NOW HERE ARE SOME REGULARLY USED CONSTANTS
;
; INFINITY
;
INFIN	FCB	00,$7F,$FF,00,00,00
	FCB	00,00,00,00,00,00
	FCB	TYINF
;
; ZERO
;
ZERO	FCB	00,$80,00,00,00,00
	FCB	00,00,00,00,00,00
	FCB	TYINF

;
; NOT A NUMBER( NAN )
;
NAN	FCB	00,$7F,$FF,00,00,00
	FCB	00,00,00,00,00,00
	FCB	TYNAN

;
; LARGE NUMBER
;
LARGE	FCB	00,00,00,$FF,$FF,$FF
	FCB	$FF,$FF,$FF,$FF,$FF,$FF
	FCB	00

;
; TABLE OF DENORMALIZED EXPONENTS
;
DNMTBL	FDB	SMINEX+1
	FDB	DMINEX+1
	FDB	EMINEX
	FDB	EMINEX
	FDB	EMINEX

;*****************************************************************
;
; SUBROUTINE  RTNAN
;
;   THIS ROUTINE BUILDS A "NAN". THAT IS
; IT COPIES A "NAN" CONSTANT INTO THE
; RESULT ADN THEN GRABS THE "NAN" ADDRESS
; AND PUTS THIS INTO THE RESULT. THE CALLER
; PC CONTAINED IN THE STACVK FRAME IS
; CONSIDERED THE "NAN" ADDRESS.
;
; ON ENTRY: U - STACK FRAME POINTER
;
; ON EXIT: STACK FRAME RESULT CONTAINS A NAN
;	   CC DESTROYED
;
RTNAN
	; SET UP THE MOVE
	PSHS	X,Y,D		; SAVE CALLER'S REGS
	LEAX	NAN,PCR		; POINT X TO NAN CONST.
	LEAY	RESULT,U	; POINT Y TO RESULT

	; MOVE NAN CONSTANT TO RESULT
	LBSR	FPMOVE

	; GET PC FROM STACK FRAME
	LDD	CALLPC,U

	;
	; PUT ADDRESS INTO THE 16 BITS JUST
	; TO THE RIGHT OF THE T-BIT
	;
	LEAX	FRACTR,U	; POINT X TO FRACTION

	;
	; LEAST SIG. TWO BITS INTO BYTE 3 OF
	; FRACTION
	;
	SRD1
	ROR	2,X
	SRD1
	ROR	2,X

	;
	; MOST SIG. 14 BITS OF ADDRESS RIGHT
	; JUSTIFIED INTO BYTES 1&2 OF FRACTION.
	;
	STD	0,X

	PULS	X,Y,D,PC	; RESTORE AND RETURN

;
; HERE ARE THE INVALID OPERATION HANDLERS. THEY NEED TO
; BE DEFINED WITH UNIQUE ENTRY POINTS FOR THESE CASES
; SINCE THESE ROUTINES ARE ENTRIES IN THE DISPATCH
; TABLES.
;
; PROCEDURES NAN__
;
;      SIGNALS INVALID OPERATION OF THE TYPE SPECIFIED
; BY THE NUMERAL IN THE PROCEDURE NAME AND RETURNS
; A NAN.
;
NAN1
	LDA	#01
	BSR	IOPSUB		; SIGNAL INVALID OPERATION
	RTS

NAN4
	LDA	#04
	BSR	IOPSUB		; SIGNAL INVALID OPERATION
	RTS

NAN9
	LDA	#09
	BSR	IOPSUB		; SIGNAL INVALID OPERATION
	RTS

NAN10
	LDA	#10
	BSR	IOPSUB		; SIGNAL INVALID OPERATION
	RTS

;
; PROCEDURE IOPSUB
;
;     IOPSUB IS THE PROCEDURE INVOKED BY THE IOP MACRO
; TO DO THE WORK OF SETTING THE IOP CODE IN THE SECONDARY
; STATUS BYTE AND THE INVALID OPERATION BIT IN THE
; PRIMARY STATUS BYTE. ADDITIONALLY SINCE A NAN IS RETURNED
; EVERY TIME IOP IS INVOKED THE CALL IS PLACED HERE.
;
; ON ENTRY: A - REG. CONTAINS THE IOP CODE
;
; ON EXIT: SECONDARY STATUS CONTAINS THE IOP CODE &
;	   MAIN STATUS HAS ITS IOP BIT SET AND THE
;	   STACK FRAME RESULT CONTAINS A NAN.
;
; PROCEDURE IOPSET
;
; IOPSET DOES THE SAME THING AS IOPSUB EXCEPT IT
; DOES NOT RETURN A NAN.
;
IOPSUB
	BSR	RTNAN		; RETURN A NAN

IOPSET
	STA	TSTAT+1,U	; SET INVALID OPERATION CODE
	LDA	TSTAT,U		; SET IOP BIT IN MAIN STATUS
	ORA	#ERRIOP
	STA	TSTAT,U
	RTS			; RETURN

;*****************************************************************
;
; PROCEDURE CLRES
;
;    CLRES ZEROS OUT THE BYTES BEYOND THE PRECISION
; OF A F. P. NUMBER SO THAT FALSE SIGNIFICANCE
; WILL NOT BE INTRODUCED UPON NORMALIZATION.
;
;  ON ENTRY:
;	    X POINTS TO THE F.P. VALUE
;	    B CONTAINS THE PRECISION INDEX
;  ON EXIT: F.P. VALUE HAS ALL ZEROES BEYOND IT'S
;	    PRECISION.
;
;
CLRES
	PSHS	X,D		; SAVE CALLERS REGS
	LEAY	CLTBL,PCR
	LSRB			; HALVE PREC. OFFSET
	LDA	B,Y		; GET OFFSET

	;
	; IF THE PRECISION IS DOUBLE FIX UP THE
	; UNUSUAL BYTE
	;
	LSLB			; RESTORE OFFSET
	CMPB	#DBL		; Double precision?
	BNE	1F		; Nope...
	BRA	2F		; Yup...
1
	CMPB	#EFD		; Extended w/ force-to-double?
	BNE	1F		; Nope...
2
	LDB	A,X
	ANDB	#BIT7+BIT6+BIT5+BIT4+BIT3
	STB	A,X
	INCA

	;
	; ZERO THE NECESSARY # OF BYTES
	;
1	CMPA	#(ARGSIZ-1)
	BGE	1F
	CLR	A,X
	INCA
1
	PULS	X,D,PC		; RESTORE AND RETURN

;
; TABLE OF BYTE BOUNDARY OFFSETS
; XXXJRT asm6809 will interpret these numbers as octal.  Verify
; that is correct!
;
CLTBL	FCB	06		; SINGLE
	FCB	09		; DOUBLE
	FCB	11		; EXTENDED
	FCB	06		; EXTND (ROUND SING.)
	FCB	09		; EXTND (ROUND DBL.)
	FCB	03		; CLEAR ENTIRE FRACTION (INDEXED BY 'CLRFRC')
	FCB	00		; CLEAR ENTIRE STACK FRAME ARGUMENT

;*****************************************************************
;
;  SUBROUTINE  RTAR1
;
; THIS ROUTINE MOVES A 13 BYTE
; BLOCK OF CODE FROM LOCATION#
; ARG1 TO LOCATION RESULT. ALL
; ADDRESSING IS DONE RELATIVE TO
; STACK POINTER, U .
;
; ON ENTRY: U - STACK FRAME POINTER
;
; ON EXIT: STACK FRAME RESULT CONTAINS THE
;	   FLOATING VALUE RESIDING IN ARG1.
;	   X,Y,B,CC - DESTROYED
;
RTAR1
	; SET UP THE MOVE
	LEAX	ARG1,U		; POINT TO ARG1
	LEAY	RESULT,U	; POINT Y TO RESULT

	LBSR	FPMOVE		; MOVE ARG1 TO RESULT ( 13 BYTES )
	BSR	ADJUST		; ADJUST POSSIBLE APPARENT UNDERFLOW
	RTS			; RETURN

;*****************************************************************
;
; SUBROUTINE RTAR2
;
; THIS ROUTINE MOVES A 23 BYTE
; BLOCK OF CODE FROM LOCATION#
; ARG2 TO LOCATION RESULT. ALL
; ADDRESSING IS DONE RELATIVE TO
; STACK POINTER, U .
;
; ON ENTRY: U - STACK FRAME POINTER
;
; ON EXIT: STACK FRAME RESULT CONTAINS THE FLOATING
;	   VALUE RESIDING IN ARG2.
;	   X,Y,B,CC - DESTROYED
;
RTAR2
	; SET UP THE MOVE
	LEAX	ARG2,U		; POINT X TO ARG2
	LEAY	RESULT,U	; POINT Y TO RESULT

	LBSR	FPMOVE		; MOVE ARG2 TO RESULT ( 13 BYTES )
	BSR	ADJUST		; ADJUST POSSIBLE APPARENT UNDERFLOW
	RTS			; RETURN

;*****************************************************************
;
; PROCEDURE  ADJUST
;
;    CHECKS AND ADJUSTS FOR AN APPARENT UNDEFLOW CONDITION
; THAT CAN ARRISE WHEN DENORMALIZED VALUES ARE NORMALIZED
; UPON ENTRY TO THE PACKAGE AND THEN JUST RETURNED TO THE
; USER THROUGH ONE OF THE COMPONENT ROUTINES. ADDITIONALLY
; IF THE VALUE IN QUESTION IS AN TRUE DENORMALIZED NUMBER
; THEN THE EXPONENT IS ADJUSTED BY ONE IN THE CASE OF SINGLE
; AND DOUBLE.
;
; ON ENTRY: FP. VALUE IS IN THE RESULT
;	    U - STACK FRAME POINTER
;
; ON EXIT: FP. VALUE IS ADJUSTED IF NECCESSARY
;	   U,S - UNCHANGED
;	   X,Y,D,CC - DESTROYED
;
ADJUST
	LBSR	CHKUNF		; CHECK FOR UNDERFLOW
	BNE	1F		; Underflow condition does not exist.
	LBSR	UNFLNT		; DENORMALIZE RESULT
	LDA	TSTAT,U
	ANDA	#$FF-ERRUNF	; CLEAR UNDERFLOW FLAG
	STA	TSTAT,U
	BRA	2F
1
	LEAX	RESULT,U
	LDA	RPREC,U		; GET PRECISION
	BSR	ISDNRM
	BNE	2F		; Value not denormalized
	CMPA	#DBL		; Single or double?
	BNE	2F		; Nope...
	LDD	EXPR,U
	SUBD	#01		; ADJUST EXPONENT
	STD	EXPR,U
2
	RTS			; RETURN

;*****************************************************************
;
;  FUNCTION  ISDNRM
;
;     CHECKS TO SEE IF A FLOATING VALUE DENORMALIZED
; OR NOT.
;
; ON ENTRY: X - POINTS AT THE STACK FRAME ARGUMENT
;	    A - CONTAINS THE PRECISION INDEX
;	    U - STACK FRAME POINTER
;
; ON EXIT: Z BIT SET IF DENORMALIZED IS TRUE
;	   Z BIT CLEARED IF DENORMALIZED IS FALSE
;	   D,X,Y - UNCHANGED
;
ISDNRM
	PSHS	D,X,Y		; SAVE CALLERS REGS.
	LDB	FRACT,X		; CHECK FOR UNORMALIZED FRACTION
	BLT	1F		; Not unnormalized...
	LEAY	DNMTBL,PCR	; DENORMALIZED EXPONENT TABLE
	LDD	A,Y
	CMPD	EXP,X		; Exponent checks?
	BNE	2F		; No, not denormalized.
	ORCC	#Z		; Denormalized.
	BRA	1F
2
	ANDCC	#NZ		; NOT DENORMALIZED
1
	PULS	D,X,Y,PC	; RESTORE AND RETURN

;*****************************************************************
;
;  SUBROUTINE  RTDNAN
;
;    THIS ROUTINE MOVES ARG2, IN "NAN" FORM
; TO THE RESULT WITH THE D BIT SET TO SIGNIFY
; THAT THE "NAN" HAS MET ANOTHER "NAN" WHILE
; PERFORMING SOME OPERATION.
;
; ON ENTRY: ARG2 CONTAINS A NAN
;	    U - STACK FRAME POINTER
;
; ON EXIT: RESULT CONTAINS THE NAN RESIDING IN ARG2
;	   WITH THE D BIT SET.
;	   X,Y,A,CC - DESTROYED
;	   U - UNCHANGED
;
; LOCAL EQUATE
;
DSET EQU $80

RTDNAN
	BSR	RTAR2		; MOVE ARG2 (NAN) TO THE RESULT
	LDA	#DSET		; GET DSET MASK
	STA	RESULT,U	; OR THE MASK IN
	RTS			; RETURN

;*****************************************************************
;
;  SUBROUTINE RTZERO
;
;   THIS ROUTINE MOVES THE VALUE ZERO TO
; THE RESULT WITH THE SIGN OF RESULT SET
; TO THE EXCLUSIVE-OR OF THE SIGNS OF ARG1
; AND ARG2. ALL ADRESSING IS DONE RELATIVE
; TO STACK POINTER, U .
;
RTZERO
	LEAX	ZERO,PCR	; POINT TO CONSTANT ZERO

	;
	; MOVE THE CONSTANT ZERO TO RESULT WITH
	; THE SIGN OF THE RESULT BEING SET TO THE
	; EXCLUSIVE-OR OF THE SIGNS OF ARG1 AND ARG2.
	;
	BSR MOVXOR
	RTS			; RETURN

;*****************************************************************
;
;  SUBROUTINE  RTINF
;
;    THIS ROUTINE MOVES THE VALUE INFINITY
; TO THE RESULT WITH THE SIGN OF THE RESULT
; SET TO THE EXCLUSIVE-OR OF THE SIGNS OF
; ARG1 AND ARG2. ALL ADDRESSING IS DONE
; RELATIVE TO THE STACK POINTER, U .
;
; ON ENTRY: U - STACK FRAME POINTER
;
; ON EXIT: STACK FRAME RESULT CONTAINS ZERO WITH THE
;	   SIGN SET TO THE X-OR OF SIGN OF ARG1 & ARG2.
;	   X,Y,CC,A - DESTROYED
;	   U - UNCHANGED
;
RTINF
	LEAX	INFIN,PCR	; POINT TO CONSTANT INFINITY

	;
	; MOVE THE CONSTANT INFINITY TO THE RESULT WITH
	; THE SIGN SET TO THE EXCLUSIVE-OR OF THE SIGNS
	; OF ARG1 AND ARG2.
	;
	BSR	MOVXOR
	RTS			; RETURN

;*****************************************************************
;
;  SUBROUTINE  RTNAR2
;
;   THIS ROUTINE MOVES THE NEGATIVE OF
; ARG2 TO RESULT. ALL ADDRESSING IS DONE
; RELATIVE TO STACK POINTER, U .
;
; ON ENTRY: U - STACK FRAME POINTER
;
; ON EXIT: STACK FRAME CONTAINS THE NEGATIVE OF THE
;	   FLOATING VALUE RESIDING IN ARG2.
;	   X,Y,CC,A - DESTROYED
;	   U - UNCHANGED
;
RTNAR2
	BSR	RTAR2		; MOVE ARG2 TO THE RESULT
	LDA	SIGNR,U
	EORA	#$80		; COMPLEMENT SIGN OF RESULT
	STA	SIGNR,U
	RTS			; RETURN

;*****************************************************************
;
;  SUBROUTINE  MOVXOR
;
;   THIS ROUTINE MOVES A BLOCK OF DATA , WHOSE
; LOCATION IS POINTED TO BY THE X-REG. TO THE
; RESULT AND REPLACES THE SIGN OF THE RESULT
; WITH THE EXCLUSIVE-OR OF THE SIGNS OF ARG1
; AND ARG2.
;
MOVXOR
	LEAY	RESULT,U
	LBSR	FPMOVE		; MOVE THE VALUE

	;
	; PERFORM X-OR OF THE SIGNS OF ARG1 & ARG2
	;
	LDA	SIGN1,U		; GET SIGN OF ARG1
	EORA	SIGN2,U		; X-OR WITH SIGN ARG2
	STA	SIGNR,U		; STORE AT RESULT
	RTS			; RETURN

;*****************************************************************
;
;  SUBROUTINE  MOVE
;
;   THIS ROUTINE MOVES A BLOCK OF DATA,WHOSE
; LOCATION IS POINTED TO BY THE X-REG., TO
; A LOCATION POINTED TO BY THE Y-REG.. THE
; NO. OF BYTES TO BE MOVED IS CONTAINED IN
; REG. B.
;
; ON ENTRY:
;	   X-REG. POINTS TO THE START OF THE
;	  BLOCK TO BE MOVED.
;
;	   Y-REG. POINTS TO THE START OF THE
;	  DESTINATION TO WHICH THE BLOCK IS BEING
;	  MOVED.
;
;	   B-REG. CONTAINS THE NO. OF BYTES TO BE
;	  MOVED.
;
MOVE
	LDA	,X+		; LOAD FROM SOURCE
	STA	,Y+		; STORE AT DESTINATION
	DECB			; CHECK BYTE COUNT
	BGT	MOVE		; BRANCH TILL DONE
	RTS			; RETURN