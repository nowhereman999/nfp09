;******************************************************************************
;
;                ABI definitions and documentation for NFP09
;
;                   Floating point routines for the 6809
;
;     Written for Motorola by Joel Boney, G. Stevens, and G. Walker, 1980
;             Released into the public domain by Motorola in 1988
;         Docs and apps for Tandy Color Computer by Rich Kottke, 1989
;    Modified for asm6809 and additional improvements by Jason Thorpe, 2022
;
;******************************************************************************
;
;                          FLOATING POINT FORMATS
;
; NFP09 supports three types of floating point numbers, two integer types,
; and BCD strings.
;
; SINGLE FORMAT
;                  4 bytes long
;       ---------------------------------------
;       |sign| exponent |     significand     |
;       ---------------------------------------
;       1 bit   8 bits         23 bits
;
; The exponent is biased by 127, so 2^0 is 127, 2^2 is 129 and 2^-2 is 125.
; Significand is sign/magnitude vice 2's complement.
;
; Examples:
;   +1.0 = 1.0 * 2^0 = $3F 80 00 00
;   +3.0 = 1.5 * 2^1 = $40 40 00 00
;   -1.0 =-1.0 * 2^0 = $BF 80 00 00
;
; DOUBLE FORMAT
;                  8 bytes long
;       ---------------------------------------
;       |sign| exponent |     significand     |
;       ---------------------------------------
;       1 bit  11 bits         52 bits
;
;     The exponent is biased by 1023, otherwise similar to single format.
;
; Examples:
;   +7.0 = 1.75 * 2^2  = $40 1C 00 00 00 00 00 00
;  -30.0 =-1.875 * 2^4 = $C0 3E 00 00 00 00 00 00
;   +0.25= 1.0 * 2^-2  = $3F D0 00 00 00 00 00 00
;
; EXTENDED FORMAT
;                 10 bytes long
;       ---------------------------------------
;       |sign| exponent |1    significand     |
;       ---------------------------------------
;       1 bit  15 bits         64 bits
;
; This format is used internally but can be used if extra precision is
; needed at an intermediate step in a calculation.  The "1.0" is explicitly
; present in the significand and the exponent contains no bias and is in 2's
; complement form.
;
; Examples:
;   0.5 = 1.0 * 2^-1 = $7F FF 80 00 00 00 00 00 00 00
;  -1.0 =-1.0 * 2^0  = $80 00 80 00 00 00 00 00 00 00
; 384.0 = 1.5 * 2^8  = $00 08 C0 00 00 00 00 00 00 00
;
; BCD STRINGS
;                           26 bytes long
;
;          0  1                    4  5   6                    24  25
;       ---------------------------------------------------------------
;       | se | 4 digit BCD exponent | sf | 19 digit BCD fraction |  p |
;       ---------------------------------------------------------------
;       1 byte      4 bytes         1 byte       19 bytes        1 byte
;
; se = sign of exponent. $00 = positive, $0F = negative
; sf = sign of fraction. $00 = positive, $0F = negative
;  p = number of fraction digits to the right of decimal point
;
; All BCD digits are unpacked and right justified, like this:
;
;       7       4 3       0
;      ---------------------
;      | 0 0 0 0 |   0-9   |
;      ---------------------
;
; The most significant BCD digits will be in lower memory (the normal Motorola
; convention).  To convert to ASCII, one need only add $30 (ASCII 0) to each
; digit.
;
; INTEGERS
;
; NFP09 supports both short (16 bit) and long (32 bit) integers.
;
;               SPECIAL VALUES (SINGLE AND DOUBLE FORMAT)
;
; Generally, when operated on the special values will give predictable
; results.
;
; ZERO
;
; Zero is represented as a zero exponent and zero fraction with a
; significant sign (+0 or -0).
;
;                -----------------------------------------
;                | s |     0     |          0            |
;                -----------------------------------------
;
; INFINITY
;
; Infinity has a maximum exponent and a zero fraction.  The sign
; differentiates between plus infinity and minus infinity.
;
;                -----------------------------------------
;                | s |111 ... 111|          0            |
;                -----------------------------------------
;
; DENORMALIZED (SMALL NUMBERS)
;
; The exponent is always zero and is interpreted as -126 (single) or -1022
; (double).  The fraction is non-zero.
;
;                -----------------------------------------
;                | s |     0     |       non-zero        |
;                -----------------------------------------
;
; Examples:
; Single:
;  1.0 * 2^-128 = 0.25 * 2^126 = $00 20 00 00
; Double:
;  1.0 * 2^-1025 = .125 * 2^1022 = $00 02 00 00 00 00 00 00
;
; NOT A NUMBER (NaN)
;
; NaNs are used by higher level languages to indicate that a number has
; been defined but never assigned a value.  They are also used by NFP09 to
; indicate that an operation could not return a valid result.
;
; NaNs have the largest exponent and a non-zero fraction.
;
;              -------------------------------------------------------
;              | d | 111 ... 111 | t | operation address | 00 ... 00 |
;              -------------------------------------------------------
;
; d: 0 = This NAN has never entered into an operation with another NAN
;    1 = This NAN has entered into an operation with another NAN
;
; t: 0 = This NAN will not necessarily cause an invalid operation trap when
;        operated on.
;    1 = This NAN will cause an invalid operation trap when operated on.  (A
;        trapping NAN).
;
; operation address: (16 bits long) the address of the instruction immediately
; following the call to NFP09 that caused the NAN to be created.
;
;                     SPECIAL VALUES (EXTENDED FORMAT)
;
; ZERO
;
; Has smallest (unbiased) exponent and zero fraction.
;
;                -----------------------------------------
;                | s |100 ... 000|          0            |
;                -----------------------------------------
;
; INFINITY
;
; Maximum (unbiased) exponent and zero fraction.
;
;                -----------------------------------------
;                | s |011 ... 111|          0            |
;                -----------------------------------------
;
; DENORMALIZED NUMBERS
;
; Smallest (unbiased) exponent and non-zero fraction.
;
;                -----------------------------------------
;                | s |100 ... 000|0.     non-zero        |
;                -----------------------------------------
;
; Denormalized extended numbers have an exponent of -16384 but are expressed as
; 0.xxxx * 2^-16383
;
; Example:
;
;  1.0 * 2^-16387 = 0.625 * 2^-16383 = $40 00 08 00 00 00 00 00 00 00
;
; NaNs
;
; Largest (unbiased) exponent and non-zero fractions.
;
;                -------------------------------------------------------
;                | d |011 ... 111| 0 | t | operation address |000...000|
;                -------------------------------------------------------
;
; Where d, t and operation address are the same as single or double NANs.
;
; UNNORMALIZED NUMBERS
;
; Occur only in extended or internal formats.  They have an exponent >
; minimum and the leading fraction bit is 0.  They can only be created when
; denormalized numbers (single or double) are represented in extended or
; internal formats.
;
;                -------------------------------------
;                | s | > 100...000 | 0.   fraction   |
;                -------------------------------------
;
; Example:
; .0625 * 2^2 = $00 02 08 00 00 00 00 00 00 00
;
;******************************************************************************
;
;                             SUPPORTED OPERATIONS
;
; NFP09 supports the following operations.
;
; MNEMONIC                        DESCRIPTION
;
; FADD   Add arg1 to arg2 and store the result.
;
; FSUB   Subtract arg2 from arg1 and store the result.
;
; FMUL   Multiply arg1 by arg2 and store the result.
;
; FDIV   Divide arg1 by arg2 and store the result.
;
; FREM   Take the remainder of arg1 divided by arg2 and store the result.  The
;        remainder is biased to lie in the range -arg2/2 < rem < +arg2/2.
;
; FCMP   Compare arg1 with arg2 and set condition codes to the result of the
;        compare.  Arg1 and arg2 can be of different precisions.
;
; FTCMP  Compare arg1 with arg2 and set condition codes to the result of the
;        compare.  In addition, trap if an unordered exception occurs regardless
;        of the state of the UNOR bit in the trap enable byte of the fpcb.
;
; FPCMP  A predicate compare; this means compare arg1 with arg2 and affirm or
;        disaffirm the input predicate (e.g. 'is arg1=arg2' or 'is arg1>arg2').
; FTPCMP A trapping predicate compare, same as FPCMP except it will trap on an
;        unordered exception regardless of the state of the UNOR bit in the trap
;        enable byte of the fpcb.
;
; FSQRT  Returns the square root of arg2 in the result.
;
; FINT   Returns the integer part of arg2 in the result.  The result is still a
;        floating point number: FINT(54.335623424) = 54.000000.
;
; FFIXS  Convert arg2 to a short (16 bit) integer.
;
; FFIXD  Convert arg2 to a long (32 bit) integer.
;
; FFLTS  Convert a short (16 bit) integer to a floating point result.
;
; FFLTD  Convert a long (32 bit) integer to a floating point result.
;
; BINDEC Convert a floating point number to a BCD string.
;
; DECBIN Convert a BCD string to a floating point number.
;
; FABS   Return the absolute value of arg2 in the result.
;
; FNEG   Return the negative of arg2 in the result.
;
; FMOV   Move (or convert) arg1 -> arg2.  This function is useful for changing
;        precisions (e.g. single to double)  with full exception processing for
;        possible overflow and underflow.
;
; All routines, except FMOV and the compares, accept arguments of the same
; precision and generate a result with the same precision.  For FMOV and the
; compares,  the sizes of the arguments are passed in a parameter word.
;
;******************************************************************************
;
;                             MODES OF OPERATION
;
; NFP09 supports all of the modes required or suggested by the IEEE standard.
; The selection bits are discussed later.
;
; ROUNDING MODES
;
;     1. Round to nearest.        (RN)
;     2. Round toward zero.       (RZ)
;     3. Round toward +Infinity.  (RP)
;     4. Round toward -Infinity.  (RM)
;
; Round to nearest will be used in most cases.  FORTRAN needs round to zero and
; interval arithmetic use RP and RM modes.
;
; NO DOUBLE ROUNDING
;
; No result will undergo more than one rounding error.
;
; INFINITY CLOSURE MODES
;
; Affine closure:  in affine closure,
;
;     -Inifinity < every finite number < +Infinity
;
; Thus, infinity is a member of the real number system just like any other
; signed quantity.
;
; Projective closure: in prjective closure,
;
;    -Infinity = Infinity = +Infinity
;
; Any comparisons between real numbers and infinity other than = and <> (not
; equal to) are invalid.
;
; NORMALIZE MODE
;
; The purpose of the normalize mode is to prevent unnormalized results from
; being generated, which can otherwise happen.  Such an unnormalized result
; arises when a denormalized operand is operated on such that its fraction
; remains not normalized but its exponent is no longer at its original minimum
; value.  By transforming denormalized operands to normalized, internal form
; upon entering each operation, unnormalized results are guarenteed not to
; occur.
;
; Thus, when operating in this mode the user can be assured that no attempt
; will be made to return an unnormalized value to a single or double
; destination.  A bit in the control byte of the fpcb selects whether or not
; this mode is in effect.  This mode is forced whenever the round mode is
; either round towards + infinity or - infinity.  Unnormalized numbers entering
; an operation are not affected by this mode, only denormalized ones are.
; Unnormalized and denormalized operands are discussed in a later section.
;
;******************************************************************************
;
;                                 EXCEPTIONS
;
; Seven types of exceptions are recognized by NFP09:
;
; 1. Invalid operation - A general exception when a sensible result cannot be
;    returned and the exception does not fit into any other category.
;
; 2. Underflow - result is too small to fit in specified precision.
;
; 3. Overflow - result is too large to fit in specified precision.
;
; 4. Division by zero - obvious.
;
; 5. Inexact result - result of an operation was not exact so it was rounded to
;                     the required precision before being returned.
;
; 6. Integer overflow - result of FIX would not fit into an integer.
;
; 7. Comparison of unordered values - attempting to compare a NAN or infinity.
;
; For each exception the user can specify whether NFP09 should 1) jump to a
; user defined exception trap routine or 2) deliver a default result and
; continue with execution.  Normally the default result is sufficient and a
; trap routine need not be written.  A status bit will be set in the status
; byte of the fpcb.  Whether or not to trap or continue is made by bits in the
; trap byte of the fpcb.  See the section on the fpcb for more details.
;
; After a trap, a pointer is supplied which points to an area on the stack
; with this diagnostic info:
;
; 1. What caused the trap (underflow, etc.)
; 2. Where in the caller's program.
; 3. Opcode.
; 4. The input operands.
; 5. The default result in internal format.
;
; If more than one trap happens in the same operation, only one is taken
; according to this precedence:
;
; 1. Invalid operator
; 2. Overflow
; 3. Underflow
; 4. Division by zero
; 5. Unordered comparison
; 6. Integer overflow
; 7. Inexact result
;
; The user supplied trap routine can 1) fix the result, 2) do nothing and allow
; the default result to be returned or 3) abort execution.
;
;******************************************************************************

;
; Utility equates
;
_bit0_			equ	$0001
_bit1_			equ	$0002
_bit2_			equ	$0004
_bit3_			equ	$0008
_bit4_			equ	$0010
_bit5_			equ	$0020
_bit6_			equ	$0040
_bit7_			equ	$0080
_bit8_			equ	$0100
_bit9_			equ	$0200
_bit10_			equ	$0400
_bit11_			equ	$0800
_bit12_			equ	$1000
_bit13_			equ	$2000
_bit14_			equ	$4000
_bit15_			equ	$8000

;******************************************************************************
;
; FLOATING POINT CONTROL BLOCK (fpcb)
;
; The caller must supply a pointer to the fpcb every call.  It contains
; status information and serves to pass info between NFP09 and the user.
;
;                     -----------------------------
;                     |       control byte        |0
;                     -----------------------------
;                     |     trap enable byte      |1
;                     -----------------------------
;                     |        status byte        |2
;                     -----------------------------
;                     |   secondary status byte   |3
;                     -----------------------------
;                     |       address of          |4
;                     |      trap routine         |5
;                     -----------------------------
;
FPCB_FP_CTRL		equ	0
FPCB_FP_TRAPEN		equ	1
FPCB_FP_STAT		equ	2
FPCB_FP_SSTAT		equ	3
FPCB_FP_TRAPVEC		equ	4
SIZEOF_FPCB		equ	6

;
; CONTROL BYTE - Written by user.  Controls NFP09 operation.  If user sets to
;                zero, all of the IEEE defaults are used.
;
;                7     6     5     4     3     2     1     0
;             -------------------------------------------------
;             |    precision    |  x  | NRM |round mode | A/P |
;             -------------------------------------------------
;
; Bit 0:    Closure (A/P) byte.
;           1 = affine closure
;           0 = projective closure
;
; Bits 1-2: Round mode
;           11 = round to minus infinity (RM)
;           10 = round to plus infinity (RP)
;           01 = round to zero (RZ)
;           00 = round to nearest (RN)
;
; Bit 3:    Normalize (NRM) bit
;           1 = normalize denormalized numbers while in internal format before
;               using.  Precludes formation of unnormalized numbers.  NOTE:
;               this mode is automatically used if rounding mode is RM or RP.
;           0 = do not normalize denormalized numbers.
;
; Bit 4:    Reserved/unused
;
; Bits 5-7: Precision.
;           111 = reserved
;           110 = reserved
;           101 = reserved
;           100 = extended - round result to double
;           011 = extended - round result to single
;           010 = extended - no forced rounding
;           001 = double
;           000 = single
;
FP_CTRL_CLOS		equ	_bit0_
FP_CTRL_RND		equ	_bit1_+_bit2_
FP_CTRL_NRM		equ	_bit3_
FP_CTRL_PREC		equ	_bit5_+_bit6_+_bit7_

;
; Closure modes in control byte
;
FP_CTRL_PROJ		equ	0
FP_CTRL_AFF		equ	FP_CTRL_CLOS

;
; Rounding modes in control byte
;
FP_CTRL_RN		equ	0		; round to nearest
FP_CTRL_RZ		equ	_bit1_		; round to zero
FP_CTRL_RP		equ	_bit2_		; round to +Infinity
FP_CTRL_RM		equ	_bit1_+_bit2_	; round to -Infinity

;
; Precision modes in control byte
;
FP_CTRL_SINGLE		equ	0		; single
FP_CTRL_DOUBLE		equ	_bit5_		; double
FP_CTRL_EXT		equ	_bit6_		; extended
FP_CTRL_EXTFS		equ	_bit5_+_bit6_	; extended forced to single
FP_CTRL_EXTFD		equ	_bit7_		; extended forced to double

;
; STATUS BYTE - Written by NFP09 to indicate any errors that have occured.  Bits
;               must be cleared by the user, NFP09 will never clear a bit once
;               it has been set.
;
;                7     6     5     4     3     2     1     0
;             -------------------------------------------------
;             |  x  | INX | IOV |  UN |  DZ | UNF | OVF | IOP |
;             -------------------------------------------------
;
; Bit 7: reserved
; Bit 6: inexact result
; Bit 5: integer overflow
; Bit 4: unordered
; Bit 3: division by zero
; Bit 2: underflow
; Bit 1: overfloww
; Bit 0: invalid operation
;
; TRAP ENABLE BYTE - Same as status byte; if a bit is set to 1, the user
;                    defined trap routine is entered whenever that error
;                    occurs.  If all bits are 0, no error trapping is done.
;
FP_ERR_IOP		equ	_bit0_		; invalid operation
FP_ERR_OVF		equ	_bit1_		; overflow
FP_ERR_UNF		equ	_bit2_		; underflow
FP_ERR_DZ		equ	_bit3_		; division by zero
FP_ERR_UN		equ	_bit4_		; unordered
FP_ERR_IOV		equ	_bit5_		; integer overflow
FP_ERR_INX		equ	_bit6_		; inexact result

;
; SECONDARY STATUS BYTE (SS) - NFP09 places the exact type of error in this byte
;                              whenever an "invalid operation error" (IOP)
;                              happens.
;
;                7     6     5     4     3     2     1     0
;             -------------------------------------------------
;             |  x  |  x  |  x  |    invalid operation type   |
;             -------------------------------------------------
;
; Bits 0-4: invalid operation type
;           0  = no IOP error
;           1  = square root of a negative number, infinity in a projective
;                mode or not a normalized number.
;           2  = tried to convert a NAN to an integer
;           3  = (plus infinity) + (neg infinity) in affine mode
;           4  = in division: 0/0, infinity/infinity or divisor is not
;                normalized and the dividend is not zero and is finite.
;           5  = one of the input arguments was a trapping NAN
;           6  = unordered values compared via predicate other than = or <>
;           7  = k out of range for BINDEC or p out of range for DECBIN
;           8  = projective closure use of +/- infinity
;           9  = 0 x infinity
;           10 = in REM arg2 is zero or not normalized or arg1 is infinite
;           11 = reserved
;           12 = reserved
;           13 = BINDEC integer too big to convert
;           14 = DECBIN cannot represent input string
;           15 = tried to MOV a single denormalized number to a double
;                destination
;           16 = tried to return an unnormalized number to a single or double
;                (invalid result)
;           17 = division by zero with divide by zero trap disabled
;

;
; TRAP VECTOR - If a trap occurs, NFP09 will JUMP indirectly to the trap address
;               in the fpcb.  Accumulator A will contain the trap type; if more
;               than one trap has occured, the higher priority one is returned
;               (0 = highest priority).  The trap types are:
;
;               0 = invalid operation
;               1 = overflow
;               2 = underflow
;               3 = divide by zero
;               4 = unnormalized
;               5 = integer overflow
;               6 = inexact result
;
;******************************************************************************
;
;                          APPLICATION INTERFACE
;
; NFP09 is an OS-9 Multi-Module.  At the beginning of the image is a
; header that allows an application to find the desired entry point
; into the module.
;
; IMPORTANT NOTE: HISTORTICAL DESCRIPTIONS OF HARD-CODED OFFSETS
; FOR THE ORIGINAL FPO9 PACKGE ARE NOT APPLICABLE TO NFP09.  PLEASE
; PARSE THE HEADER PROPERLY OR USE THE SHORT-CUTS PROVIDED BY NFP09.
;
; OS-9 Multimodule Format:
;                ----------------------------------------------
;                00 |       Sync  bytes - $87CD               |
;                01 |                                         |
;                ----------------------------------------------
;                02 |       Module  size (bytes)              |
;                03 |                                         |
;                ----------------------------------------------
;                04 |       Module name offset                |
;                05 |                                         |
;                ----------------------------------------------
;                06 |      Type          |      Language      |
;                ----------------------------------------------
;                07 |    Attributes      |      Revision      |
;                ----------------------------------------------
;                08 |            Header parity                |
;                ----------------------------------------------
;                09 |     Number of entries in table          |
;                ----------------------------------------------
;                0A |                                         |
;                 . |     Entry table(s). See below           |
;                 . |                                         |
;                ----------------------------------------------
;
; Entry table: for each entry of the multimodule, the table contains
; the following:
;                ----------------------------------------------
;                | Entry name, last character has bit 8 set   |
;                |                                            |
;                ----------------------------------------------
;                | Entry execution offset (2 bytes)           |
;                |                                            |
;                ----------------------------------------------
;                | Amount of permanent storage required by    |
;                | entry (2 bytes)                            |
;                ----------------------------------------------
;                | Amount of stack space required by entry    |
;                | (2 bytes)                                  |
;                ----------------------------------------------
;
; The original FPO9 included 2 ABIs: a Register ABI and a Stack ABI.
; NFP09 also includes both, but may also be built with only one or
; the other in order to save space.
;
; The Register ABI is described by the entry named "REG".  The
; Stack ABI is described by the entry named "STK" (in the original
; FPO9, this entry was named "STAK").
;
; In order to simplify application linkage, NFP09 makes the following
; guarantees:
;
; ==> NFP09's table entries are constructed so that they are the same size.
; ==> If an NFP09 image contains both the ABIs, the entry count will be 2,
;     and "REG" will be the first entry and "STK" will be the second entry.
; ==> If an NFP09 image contains only one of the ABIs, the entry count
;     will be 1.
;
; The following illustrates how to compute the NFP09 entry points,
; assuming that NFP09 is located at a fixed location in ROM:
;
; nfp09_regcall		rzb	2
; nfp09_stkcall		rzb	2
;
;	ldx	#NFP09_ROM_ADDR		; X <- NFP09 ROM address
;	ldd	NFP09_EXECOFF_REG,X	; D <- regcall entry offset
;	leay	D,X			; Y <- regcall absolute address
;	sty	nfp09_regcall
;	ldd	NFP09_EXECOFF_STK,X	; D <- stkcall entry offset
;	leay	D,X			; Y <- stkcall absolute address
;	sty	nfp09_stkcall
;
; If you are using an NFP09 image with only the Register or Stack ABI:
;
; nfp09_entryvec	rzb	2
;
;	ldx	#NFP09_ROM_ADDR		; X <- NFP09 ROM address
;	ldd	NFP09_EXECOFF_SINGLE,X	; D <- entry offset
;	leay	D,X			; Y <- absolute address
;	sty	nfp09_entryvec
;
; A convenience macro is provided for this below.
;
MMOD_HDR_SYNC		equ	0
MMOD_HDR_MODSIZ		equ	MMOD_HDR_SYNC+2
MMOD_HDR_NAMOFF		equ	MMOD_HDR_MODSIZ+2
MMOD_HDR_TL		equ	MMOD_HDR_NAMOFF+2
MMOD_HDR_AR		equ	MMOD_HDR_TL+1
MMOD_HDR_PAR		equ	MMOD_HDR_AR+1
MMOD_HDR_NUMENT		equ	MMOD_HDR_PAR+1
SIZEOF_MMOD_HDR		equ	MMOD_HDR_NUMENT+1

MMOD_ENT_NAME		equ	0
MMOD_ENT_EXECOFF	equ	3	; All NFP09 entry names are 3 bytes
MMOD_ENT_PERMSPACE	equ	MMOD_ENT_EXECOFF+2
MMOD_ENT_STKSPACE	equ	MMOD_ENT_PERMSPACE+2
SIZEOF_MMOD_ENT		equ	9

; Offsets from start of image.
NFP09_EXECOFF_REG	equ	SIZEOF_MMOD_HDR+MMOD_ENT_EXECOFF
NFP09_EXECOFF_STK	equ	SIZEOF_MMOD_HDR+SIZEOF_MMOD_ENT+MMOD_ENT_EXECOFF
NFP09_EXECOFF_SINGLE	equ	SIZEOF_MMOD_HDR+MMOD_ENT_EXECOFF

;
; The following macro computes the specified NFP09 entry vector
; and stores it in the 2-byte location nfp09_entryvec, which is
; supplied by your application.
;
; Call it like so:
;
;	nfp09_set_entryvec NFP09_EXECOFF_REG
;
; On entry: X -- address of the NFP09 module
; On exit:  All registers preserved
;
nfp09_set_entryvec	macro
			pshs	D,X
			ldd	\1,X
			leax	D,X
			stx	nfp09_entryvec
			puls	D,X
			endm

;
; These three convenience macros make nfp09_set_entryvec even
; easier to use!
;
nfp09_set_regentry	macro
			nfp09_set_entryvec NFP09_EXECOFF_REG
			endm

nfp09_set_stkentry	macro
			nfp09_set_entryvec NFP09_EXECOFF_STK
			endm

nfp09_set_oneentry	macro
			nfp09_set_entryvec NFP09_EXECOFF_SINGLE
			endm

;
;                NFP09 CALLING SEQUENCE REFERENCE TABLE
; -----------------------------------------------------------------------
; |Function|  Register entry conditions   | Stack entry conditions      |
; -----------------------------------------------------------------------
; | FADD   | U -> arg1                    | push arg1                   |
; | FSUB   | Y -> arg2                    | push arg2                   |
; | FMUL   | D -> fpcb                    | push ptr to fpcb            |
; | FDIV   | X -> result                  | call NFP09                  |
; | FREM   |                              | pull result                 |
; -----------------------------------------------------------------------
; | FSQRT  | Y -> arg                     | push arg                    |
; | FINT   | D -> fpcb                    | push ptr to fpcb            |
; | FFIXS  | X -> result                  | call NFP09                  |
; | FFIXD  |                              | pull result                 |
; | FABS   |                              |                             |
; | FNEG   |                              |                             |
; | FFLTS  |                              |                             |
; | FFLTD  |                              |                             |
; -----------------------------------------------------------------------
; | FCMP   | U -> arg1                    | push arg1                   |
; | FTCMP  | Y -> arg2                    | push arg2                   |
; | FPCMP  | D -> fpcb                    | push parameter word         |
; | FTPCMP | X =  parameter word          | push ptr to fpcb            |
; |        | result is returned in the CC | call NFP09                  |
; |        | register.  For predicate     | pull result (if pred. cmp)  |
; |        | compares, Z is set if affirm | result is returned in the CC|
; |        | and clear if disaffirm.      | register. For pred. cmps a 1|
; |        |                              | byte result is on top of the|
; |        |                              | stack: 0 if affirm, $FF if  |
; |        |                              | disaffirm                   |
; -----------------------------------------------------------------------
; | FMOV   | U =  precision parameter word| push arg                    |
; |        | Y -> argument                | push precision param word   |
; |        | D -> fpcb                    | push ptr to fpcb            |
; |        | X -> result                  | call NFP09                  |
; |        |                              | pull result                 |
; -----------------------------------------------------------------------
; | BINDEC | U =  k (# digits in result)  | push arg                    |
; |        | Y -> argument                | push k                      |
; |        | D -> fpcb                    | push ptr to fpcb            |
; |        | X -> decimal result          | call NFP09                  |
; |        |                              | pull result                 |
; -----------------------------------------------------------------------
; | DECBIN | U -> decimal string          | push ptr to BCD string      |
; |        | D -> FPCB                    | push addr of fpcb           |
; |        | X -> binary result           | call NFP09                  |
; |        |                              | pull result                 |
; -----------------------------------------------------------------------
;
;                            PARAMETER WORDS
;
; For predicate compares, X contains a parameter word with the condition to be
; affirmed or disaffirmed.  The predicate bits in X are as follows:
;
; Bit 0    : unordered bit
; Bit 1    : less than bit
; Bit 2    : equal to bit
; Bit 3    : greater than bit
; Bit 4    : not equal bit
; Bits 5-15: not used
;
; greater than or equal to = bit 3 + bit 2
; less than or equal to = bit 2 + bit 1
;
; For moves, U contains a parameter word describing the size of the source and
; destination arguments.  The bits are as follows, where the size is as defined
; in the fpcb control byte
; Bits 0-2  : Destination size
; Bits 3-7  : unused
; Bits 8-10 : Source size
; Bits 11-15: unused
;

FPOP_M		equ	_bit7_			  ; mixed arguments
FPOP_T		equ	_bit6_			  ; trap on unordered

FPOP_FADD	equ	0			  ; FADD
FPOP_FSUB	equ	FPOP_FADD+2		  ; FSUB
FPOP_FMUL	equ	FPOP_FSUB+2		  ; FMUL
FPOP_FDIV	equ	FPOP_FMUL+2		  ; FDIV
FPOP_FREM	equ	FPOP_FDIV+2		  ; FREM
FPOP_FCMP	equ	FPOP_FREM+2+FPOP_M	  ; FCMP
FPOP_FTCMP	equ	FPOP_FREM+4+FPOP_M+FPOP_T ; FCMP (trapping)
FPOP_FPCMP	equ	FPOP_FREM+6+FPOP_M	  ; FPCMP
FPOP_FTPCMP	equ	FPOP_FREM+8+FPOP_M+FPOP_T ; FPCMP (trapping)
FPOP_FSQRT	equ	FPOP_FREM+10		  ; FSQRT
FPOP_FINT	equ	FPOP_FSQRT+2		  ; FINT
FPOP_FFIXS	equ	FPOP_FINT+2		  ; FFIXS
FPOP_FFIXD	equ	FPOP_FFIXS+2		  ; FFIXD
FPOP_FMOV	equ	FPOP_FFIXD+2+FPOP_M	  ; FMOV
FPOP_BINDEC	equ	FPOP_FFIXD+4		  ; BINDEC
FPOP_FABS	equ	FPOP_BINDEC+2		  ; FABS
FPOP_FNEG	equ	FPOP_FABS+2		  ; FNEG
FPOP_DECBIN	equ	FPOP_FNEG+2		  ; DECBIN
FPOP_FFLTS	equ	FPOP_DECBIN+2		  ; FFLTS
FPOP_FFLTD	equ	FPOP_FFLTS+2		  ; FFLTD

PCMP_UN		equ	_bit0_
PCMP_LT		equ	_bit1_
PCMP_EQ		equ	_bit2_
PCMP_GT		equ	_bit3_
PCMP_NE		equ	_bit4_
PCMP_GE		equ	PCMP_GT+PCMP_EQ
PCMP_LE		equ	PCMP_LT+PCMP_EQ

PCMP_RES_TRUE	equ	0
PCMP_RES_FALSE	equ	$FF

;
; The following convenience macro makes calling NFP09 a tad
; bit simpller.  It assumes the application has already stored
; the NFP09 entry vector in a 2-byte location called nfp09_entryvec.
;
; Call it like so:
;
;	; [Code to set up arguments goes here.]
;	nfp09_call FPOP_FADD
;
nfp09_call		macro
			jsr	[nfp09_entryvec]
			fcb	\1
			endm
