;
; TTL  UTILITARIAN ARITHMETIC SUPPORT ROUTINES
; NAM UTIL
;
;      DEFINE EXTERNAL REFERENCES
;
; XDEF	XSUBY,XADDY,NORMQK,NORM1,DNORM1,FPMOVE
; XDEF	VALID,FRCTAB,BITTBL,SHIFTR,COMP2,FILSKY
; XDEF	DENORM
;
; XREF	CKINVD,CHKOVF,CHKUNF,OVFLNT,UNFLNT,ROUND
; XREF	TFRACT,ADBIAS,SUBIAS,GOSET
;
;
;    REVISION HISTORY:
;      DATE	  PROGRAMMER	    REASON
;
;    23.MAY.80	  G.WALKER	    ORIGINAL
;    1.JULY.80	  G.WALKER	    REDUCE SIZE
;    14.JUL.80	  G. STEVENS	    REDUCE SIZE AND
;				    ADD COMP2 ROUTINE
;    30.JUL.80	  G. WALKER	    CORRECT 'VALID' SO 'SUBIAS'
;				      DOES NOT TRIGGER OVF TEST
;    06.AUG.80	  G. WALKER	    'VALID': POINT X TO RSLT FOR ROUND
;    12.AUG.80	  G. STEVENS	     ADD FILSKY & DENORM UTILITIES
;    06.OCT.80	  G. STEVENS	     FIX ADDR. MODE ERROR IN FILSKY
;    09.OCT.80	  G.WALKER	     FIX G-BYTE OFFSET BACK TO ORIG
;    12.DEC.80	  G. STEVENS	     ADD CALL TO ROUND IN 'VALID'
;    19.DEC.80	  G. WALKER	     CHANGE IFCC CS TO IFCC EQ
;				     IN DNORM1.
;    26.JUN.22    @thorpej           Updated for asm6809.  New comments
;                                    are in mixed-case.
;
;*****************************************************************
;
;	 TABLE OF FRACTION SIZES IN BYTES AND BITS.
;
FRCTAB	FCB	4,7,9,4,7	; PRECISION IN BYTES
BITTBL	FCB	26,55,66,26,55	; PRECISION IN BITS + GUARD BIT

;*****************************************************************
;
;    XSUBY --
;	 SUBTRACTS THE 9-BYTE FRACTION POINTED TO BY
;    XREG FROM THE 9-BYTE FRACTION POINTED TO BY
;    THE YREG.	RESULT IS LEFT IN FRACTION POINTED BY
;    THE XREG.
;	 BASHES D AND CC.
;
XSUBY
	XSBTRY			; SUBTRACT 9 BYTES AT X FROM BYTES AT Y
	RTS

;*****************************************************************
;
;    NORMQK --
;	 PERFORMS A QUICK, MULTI-BIT NORMALIZE
;    ON THE INTERNAL FP NUMBER POINTED TO BY X.
;	 BASHES D AND CC.
;
NORMQK
	LBSR TFRACT		; TEST FOR ZERO FRACTION
	BEQ	1F
2
	TST	FRACT,X
	BLE	1F
	CLRA

	; LSHIFT  FRACT,X,9	  SHIFT FRACTION LEFT ONE BIT
	ROL	FRACT+9-1,X
	ROL	FRACT+9-2,X
	ROL	FRACT+9-3,X
	ROL	FRACT+9-4,X
	ROL	FRACT+9-5,X
	ROL	FRACT+9-6,X
	ROL	FRACT+9-7,X
	ROL	FRACT+9-8,X
	ROL	FRACT+9-9,X

	LDD	EXP,X
	SUBD	#1		; DECREMENT EXPONENT TO COMPENSATE
	STD	EXP,X		; FOR LEFT SHIFT OF FRACTION
	BRA	2B
1
	RTS

;*****************************************************************
;
;    NORM1 --
;	 NORMALIZES THE INTERNAL FP NUMBER POINTED TO
;    BY THE X REGISTER ONE BIT TO THE LEFT ONLY.
;	 BASHES D AND CC.
;
NORM1
	CLRA			; CLEAR C BIT

	; LSHIFT FRACT,X,9
	ROL	FRACT+9-1,X
	ROL	FRACT+9-2,X
	ROL	FRACT+9-3,X
	ROL	FRACT+9-4,X
	ROL	FRACT+9-5,X
	ROL	FRACT+9-6,X
	ROL	FRACT+9-7,X
	ROL	FRACT+9-8,X
	ROL	FRACT+9-9,X

	LDD	EXP,X
	SUBD	#1
	STD	EXP,X
	RTS

;*****************************************************************
;
;    DNORM1 --
;	 DENORMALIZES THE INTERNAL FP NUMBER POINTED
;    TO BY THE X-REGISTER ONE BIT TO THE RIGHT.
;    THE CARRY BIT IS SHIFTED INTO THE MSB AND
;    THE EXPONENT IS INCREMENTED TO MAINTAIN THE
;    NUMBER UNCHANGED IN VALUE.
;
DNORM1
	; RSHIFT FRACT,X,9
	ROR	FRACT+0,X
	ROR	FRACT+1,X
	ROR	FRACT+2,X
	ROR	FRACT+3,X
	ROR	FRACT+4,X
	ROR	FRACT+5,X
	ROR	FRACT+6,X
	ROR	FRACT+7,X
	ROR	FRACT+8,X

	INC	EXP+1,X
	BNE	1F		; Carry out?
	INC	EXP,X		; PROPAGATE IT.
1	RTS

;*****************************************************************
;
;    XADDY --
;	 ADDS MANTISSA (9 BYTES LONG) POINTED TO
;    BY X-REGISTER TO MANTISSA POINTED TO BY Y-REGISTER
;    AND REPLACES X-MANTISSA WITH RESULT.  THE CARRY
;    OUT OF THE HIGH-ORDER BYTE OF RESULT IS LEFT
;    IN THE CARRY FLAG OF THE CC-REGISTER.
;	 BASHES: D AND CC.
;
XADDY
	XPLUSY			; ADD 9 BYTES AT X TO BYTES AT Y
	RTS

;*****************************************************************
;
;    VALID --
;	 VALIDATES THE FLOATING-POINT RESULT AND
;    CALLS THE APPROPRIATE EXCEPTION-HANDLING
;    ROUTINES, IF NECESSARY.
;
VALID
	LBSR	CHKUNF		; Check for underflow.
	BNE	1F		; Nope, go check for uverflow.
	LDX	PFPCB,U
	LDA	ENB,X		; Get trap enables.
	ANDA	#ENBUNF		; Underflow traps enabled?
	BEQ	2F		; No, handle non-trapping case.
	LBSR	ADBIAS
	; XXXJRT ROUND needs to be calle with X pointing to the result?
	; XXXJRT could to a tail-call with LBRA here...
	LBSR	ROUND		; DELIVER ROUNDED RESULT TO TRAP HANDLER
	RTS			; Done.
2
	; XXXJRT could do a tail-call with LBRA here...
	LBSR	UNFLNT		; Go handle the underflow.
	RTS			; Done.

1	; ROUND AND CHECK FOR OVERFLOW
	LEAX	RESULT,U	; POINT X TO RESULT
	LBSR	ROUND		; ROUND RESULT
	LBSR	CKINVD		; CHECK FOR INVALID
	LBSR	CHKOVF		; Check for overflow.
	BEQ	1F		; Yes, go handle it.
	RTS			; Otherwise, we're done.
1
	LDX  PFPCB,U
	LDA  ENB,X		; Get trap enables.
	ANDA #ENBOVF		; Overflow traps enabled?
	;
	; XXXJRT This function had been damaged in the fp09
	; source drop, I guess?  It trailed off with:
	;
	; IFCC NE**************************
	;
	; I *believe* the intent is similar to how underflow
	; is handled: call SUBIAS if Overflow traps are enabled,
	; otherwise call OVFLNT.  I don't see anything else that
	; might need to happen at the tail that would be common
	; to either case.  Alas, it's no longer possible to ask
	; Joel Boney (RIP), and I don't know about Greg Walker.
	;
	BEQ	2F		; No, handle non-trapping case.
	; XXXJRT could to a tail-call with LBRA here...
	LBSR	SUBIAS
	RTS			; Done.
2
	; XXXJRT could to a tail-call with LBRA here...
	LBSR	OVFLNT		; Go handle the overflow.
	RTS			; Done.

;
;    FPMOVE --
;	 MOVES A FLOATING-POINT NUMBER POINTED TO
;    BY XREG TO THE MEMORY POINTED TO BY YREG.	NO
;    LOOP IS USED, SO IT IS VERY FAST.
;
;    ON EXIT:  NO REGISTERS CHANGED.
;
FPMOVE
	PSHS	CC,D
	LDD	0,X		; MOVE OVER 2 BYTES AT A TIME
	STD	0,Y
	LDD	2,X
	STD	2,Y
	LDD	4,X
	STD	4,Y
	LDD	6,X
	STD	6,Y
	LDD	8,X
	STD	8,Y
	LDD	10,X
	STD	10,Y
	LDA	12,X
	STA	12,Y
	PULS	CC,D,PC		; RESTORE REGS AND RETURN

;*****************************************************************
;
;    SHIFTR --
;	 THIS SUBROUTINE TAKES THE PLACE OF THE 9-BYTE
;    RIGHT SHIFT MACRO WHERE SPACE IS CRITICAL AND
;    TIME IS NOT.
;
SHIFTR
	; RSHIFT 0,X,9
	ROR	0+0,X
	ROR	0+1,X
	ROR	0+2,X
	ROR	0+3,X
	ROR	0+4,X
	ROR	0+5,X
	ROR	0+6,X
	ROR	0+7,X
	ROR	0+8,X
	RTS

;*****************************************************************
;
;    COMP2 --
;	 PREFORMS A TWO'S COMPLEMENT ON THE VALUE
; POINTED AT BY THE X-REG. WHOSE LEAST SIGNIFICANT
; BYTE IS GIVEN BY THE OFFSET IN THE B-REG.
;
COMP2
	TFR	B,A		; SAVE OFFSET FOR FUTURE
1	CMPA	#0		; A >= 0?
	BLT	1F		; No, get out of the loop.
	COM	A,X		; Complement the byte.
	DECA			; Decrement the index.
	BRA	1B		; Go back around.
1
	; We've complemented the entire number. Now,
	; perform the add-one to make it's 2's complement.
	LDA	#1		; 1 is the number to add.
	CMPB	#0		; B >= 0?
	BLT	1F		; No, get out of the loop.
2	TST	A		; A != 0?
	BEQ	1F		; No, get out 'cause no more carry to propagate
	ADDA	B,X		; Do the add.
	STA	B,X
	CLRA			; ...and grab the carry to propagate through.
	ROLA
	DECB			; Decrement the index.
	BRA	2B		; Go back around.
1
	RTS			; Done.

;*****************************************************************
;
; PROCEDURE  FILSKY
;
;     OR'S ALL BITS IN THE FRACTION AND G-BIT INTO
; THE STIKY BYTE. ALSO ZEROS OUT THE FRACTION AND THE
; GUARD BIT.
;
;  ON ENTRY: X - POINTS AT THE STACK FRAME ARGUMENT
;
;  ON EXIT: X,Y,D,CC,U,S - UNCHANGED
;
FILSKY
	PSHS	X,Y,D,CC	; SAVE CALLERS REGISTERS
	;
	; GET OFFSET TO THE G-BYTE
	;
	LEAY	GOSET,PCR	; G - OFFSET TABLE
	LDB	RPREC,U		; PRECISION INDEX
	LSRB			; HALVE OFFSET
	LDA	B,Y		; OFFSET FROM FRACT
	ADDA	#FRACT		; OFFSET FROM SIGN

	;
	; START ORING THE BYTES OF FRACTION AND G-BIT INTO STIKY
	; NOTE THAT THE ROUND BITS IN THE SAME BYTE AS THE G BYTE
	; GET ORED AND ZEROED OUT AS WELL.
	;
	CLRB			; STIKY ACCUMULATOR
1	CMPA	#FRACT		; A >= #FRACT?
	BLT	1F		; No, we're done.
	ORB	A,X
	CLR	A,X
	DECA
	BRA	1B
1
	ORB	STIKY,U		; MODIFY STIKY
	STB	STIKY,U
	PULS	X,Y,D,CC,PC	; RETURN

;*****************************************************************
;
;  PROCEDURE  DENORM
;
;    DENORMALIZES A FLOATING PT. FRACTION AND ORS THE
; BITS THAT FALL OFF THE END AS WELL AS THOSE BEYOND
; THE PROCISION OF FLOATING VALUE INTO THE STIKY BYTE.
; THE SHIFT COUNT FOR DENORMALIZING IS PASSED IN THE
; B - REG. .
;
; ON ENTRY: X - POINTS TO THE STACK FRAME ARGUMENT
;	    B - CONTAINS THE SHIFT COUNT
;
; ON EXIT: X,Y,D,CC,U,S - UNCHANGED
;
DENORM
	PSHS	X,Y,D,CC

	CLRA			; STIKY ACCUMULATOR
1	CMPB	#0		; B > 0?
	BLE	1F		; No.
	ANDCC	#NC		; CLEAR CARRY
	; RSHIFT FRACT,X,9	  DO THE SHIFT
	ROR	FRACT+0,X
	ROR	FRACT+1,X
	ROR	FRACT+2,X
	ROR	FRACT+3,X
	ROR	FRACT+4,X
	ROR	FRACT+5,X
	ROR	FRACT+6,X
	ROR	FRACT+7,X
	ROR	FRACT+8,X
	BCC	2F		; Skip if Carry clear
	ROLA
2	DECB
	BRA	1B
1
	;
	; OR ALL BYTES BEYOND THE GUARD BYTE INTO THE
	; STIKY BYTE.
	;
	LEAY	GOSET,PCR	; G - BYTE OFFSET TABLE
	LDB	RPREC,U		; GET PRECISION
	LSRB			; HALVE  OFFSET
	LDB	B,Y 		; G- BYTE OFFSET
	ADDB	#FRACT+1	; ADJUST OFFSET FOR FRACT

1	CMPB	#(ARGSIZ-1)	; B < #(ARGSIZ-1)?
	BGE	1F		; No...
	ORA	B,X
	INCB
	BRA	1B
1
	ORA	STIKY,U
	STA	STIKY,U
	PULS	X,Y,D,CC,PC
