;
; This example is derived from:
;
;                                 APPENDIX B
;                             APPLICATION EXAMPLE
;                          OF THE QUADRATIC EQUATION
;
;                             from the manual for:
;                      MOTOROLA MC6839 FLOATING POINT ROM
;
; This appendix provides an application example using the MC6839 Floating
; Point ROM.  The program shown below is one that finds the roots to
; quadratic equations using the classic formula:
;
;                           -b +/- SQRT(b^2 - 4ac)
;                       x = ----------------------
;                                    2a
;
; This version has been modified in the following ways:
;
; ==> The "standard set of macro instructions" from the original (that were
;     also used to write the ROM) have been removed, as they are not compatible
;     with asm6809.
;
; ==> The program is written to use the NFP09 ABI header and associated macros.
;
; ==> The program has been updated sylistically, and to allow application
;     memory and code to be disjoint.  The new code is not use position-
;     independent accesses to mutable variables.
;

	include "../abi/nfp09-abi.s"

QUAD_PROGSTART	equ	$E000		; pg09 emulator ROM starts here.

	org	$0000

;
; NFP09 entry vector
;
nfp09_entryvec	rmb	2

;
; RMBs for the operands, binary-to-decimal conversion buffers,
; and the FPCB.
;
ACOEFF		rmb	SIZEOF_FPBCD	; coefficient A in ax^2 + bx + c
BCOEFF		rmb	SIZEOF_FPBCD	; ...B...
CCOEFF		rmb	SIZEOF_FPBCD	; ...C...

REG1		rmb	SIZEOF_FPSINGLE
REG2		rmb	SIZEOF_FPSINGLE
REG3		rmb	SIZEOF_FPSINGLE

FPCB		rmb	SIZEOF_FPCB

;
; Read-only data and code starts here.
;
	org	QUAD_PROGSTART

;
; Single-precision floating point constants: 2.0, 4.0.
;
TWO	fcb	$40,$00,$00,$00
FOUR	fcb	$40,$80,$00,$00

;
; Here is the main event.  We assume the stack has already been initialized
; and that the arguments have been copied into the coefficient buffers in
; as BCD strings.
;
QUAD
	;
	; Initialize the FPCB.  Setting to zeros will
	; select single-precision, round-to-nearest.
	;
	ldx	#FPCB
	ldb	#SIZEOF_FPCB
1	cmpb	#0
	ble	1F
	decb
	clr	B,X
	bra	1B
1
	;
	; ...but for the sake of example, we're going to
	; explicitly initialize the FPCB control byte after
	; having zero'd the FPCB.
	;
	lda	#FP_CTRL_PROJ+FP_CTRL_RN+FP_CTRL_SINGLE
	sta	FPCB_FP_CTRL,X

	;
	; Select the Register ABI
	;
	leax	NFP09_BASE,PCR
	nfp09_set_regentry

	;
	; N.B. NFP09 preserves all caller registers across
	; every call, so we can skip loading D each time,
	; and can skip re-loading argument registers if the
	; arguments are the same.
	;
	ldd	#FPCB		; D -> FPCB for Register ABI calls

	;
	; Convert the inputs from BCD strings to single-precision
	; binary form.
	;
	ldu	#ACOEFF		; U -> decimal string
	ldx	#ACOEFF		; X -> binary result
	nfp09_call FPOP_DECBIN

	ldu	#BCOEFF		; U -> decimal string
	ldx	#BCOEFF		; X -> binary result
	nfp09_call FPOP_DECBIN

	ldu	#CCOEFF		; U -> decimal string
	ldx	#CCOEFF		; X -> binary result
	nfp09_call FPOP_DECBIN

	;
	; Now start the actual calculations for the quadratic
	; formula.
	;
	
	; REG1 = b^2
	ldu	#BCOEFF		; U -> arg1
	ldy	#BCOEFF		; Y -> arg2
	ldx	#REG1		; X -> result
	nfp09_call FPOP_FMUL

	; REG2 = ac
	ldu	#ACOEFF		; U -> arg1
	ldy	#CCOEFF		; Y -> arg2
	ldx	#REG2		; X -> result
	nfp09_call FPOP_FMUL

	; REG2 = 4 * REG2 (i.e. 4AC)
	ldu	#FOUR		; U -> arg1
	ldy	#REG2		; Y -> arg2
	; X already points to REG2 per above
	nfp09_call FPOP_FMUL

	; REG1 = REG1 - REG2 (i.e. "b^2 - 4ac")
	ldu	#REG1		; U -> arg1
	; Y already points to REG2 per above
	ldx	#REG1		; X -> result
	nfp09_call FPOP_FSUB

	;
	; Check result of "b^2 - 4ac" to see if roots are real or
	; imaginary.
	;
	lda	REG1		; N.B. clobbers D
	bmi	imaginary	; if sign -, go handle imaginary root
	;
	; Sign is +, roots are real.
	;

	ldd	#FPCB		; reload D

	; REG1 = SQRT(REG1) (i.e. SQRT(b^2 - 4ac))
	ldy	#REG1		; Y -> arg
	ldx	#REG1		; X -> result
	nfp09_call FPOP_FSQRT

	; REG2 = 2a
	ldu	#ACOEFF		; U -> arg1
	ldy	#TWO		; Y -> arg2
	ldx	#REG2		; X -> result
	nfp09_call FPOP_FMUL

	; Negate b
	ldy	#BCOEFF		; Y -> arg
	ldx	#BCOEFF		; X -> result
	nfp09_call FPOP_FNEG

	;
	; FIRST ROOT
	;

	; Calculate "-b + SQRT(b^2 - 4ac)"
	ldu	#BCOEFF		; U -> arg1
	ldy	#REG1		; Y -> arg2
	ldx	#REG3		; X -> result
	nfp09_call FPOP_FADD

	; Calculate "(-b + SQRT(b^2 - 4ac) / 2a"
	ldu	#REG3		; U -> arg1
	ldy	#REG2		; Y -> arg2
	; X already points to REG3 per above
	nfp09_call FPOP_FDIV

	; Convert results to decimal.
	ldu	#5		; U =  k (# digits in result)
	ldy	#REG3		; Y -> arg
	ldx	#ACOEFF		; X -> result
	nfp09_call FPOP_BINDEC

	;
	; SECOND ROOT
	;

	; Calculate "-b - SQRT(b^2 - 4ac)"
	ldu	#BCOEFF		; U -> arg1
	ldy	#REG1		; Y -> arg2
	ldx	#REG3		; X -> result
	nfp09_call FPOP_FSUB

	; Calculate "(-b - SQRT(b^2 - 4ac) / 2*A"
	ldu	#REG3		; U -> arg1
	ldy	#REG2		; Y -> arg2
	; X already points to REG3 per above
	nfp09_call FPOP_FDIV

	; Convert results to decimal.
	ldu	#5		; U =  k (# digits in result)
	ldy	#REG3		; Y -> arg
	ldx	#BCOEFF		; X -> result
	nfp09_call FPOP_BINDEC

	; Sentinal signalling that roots are real.
	lda	#$FF
	sta	CCOEFF

	; Adios!
	rts

imaginary
	ldd	#FPCB		; reload D

	; Sign is negative -- make sign positive.
	ldy	#REG1		; Y -> arg
	ldx	#REG1		; X -> result
	nfp09_call FPOP_FABS

	; Calculate SQRT(b^2 - 4ac)
	; X and Y already point to REG1 per above
	nfp09_call FPOP_FSQRT

	; Calculate 2a
	ldu	#ACOEFF		; U -> arg1
	ldy	#TWO		; Y -> arg2
	ldx	#REG2		; X -> result
	nfp09_call FPOP_FMUL

	; Calculate SQRT(b^2 - 4ac) / 2a
	ldu	#REG1		; U -> arg1
	ldy	#REG2		; Y -> arg2
	ldx	#REG1		; X -> result
	nfp09_call FPOP_FDIV

	; Calculate -b/2a
	ldu	#BCOEFF		; U -> arg1
	; Y already points to REG2 per above
	ldx	#REG2		; X -> result
	nfp09_call FPOP_FDIV
	nfp09_call FPOP_FNEG

	; Convert -b/2a to decimal
	ldu	#5		; U =  k (# digits in result)
	ldy	#REG2		; Y -> arg
	ldx	#BCOEFF		; X -> result
	nfp09_call FPOP_BINDEC

	; Convert SQRT(b^2 - 4ac) / 2a to decimal
	; U already contains #5 per above
	ldy	#REG1		; Y -> arg
	ldx	#ACOEFF		; X -> result
	nfp09_call FPOP_BINDEC

	; Sentinal signalling imaginary roots.
	clr	CCOEFF

	; Adios!
	rts

	;
	; Pull in the NFP09 package.
	;
NFP09_BASE
	includebin "../newsrc/nfp09.bin"
