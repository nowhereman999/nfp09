/*-
 * Copyright (c) 2022 Jason R. Thorpe.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * Generate test programs for the NFP09 floating point package.
 */

#include <inttypes.h>
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef FPTYPE_SINGLE
typedef	float	fpval_type;
typedef	uint32_t fpval_int;
#define	FPCONST(v)	v##F
#define	FPFUNC(x)	x##f
#else
typedef	double	fpval_type;
typedef	uint64_t fpval_int;
#define	FPCONST(v)	v
#define	FPFUNC(x)	x
#endif

#define	fpval_bytes	sizeof(fpval_int)

typedef union {
	fpval_type	val_float;
	fpval_int	val_int;
} fpval;

static void
emit_section(const char *section)
{
	printf("\tsection \"%s\"\n", section);
}

static void
emit_fpval(fpval_type fval, const char *label)
{
	const fpval val = {
		.val_float = fval,
	};
	uint8_t bytes[fpval_bytes];

#ifdef FPTYPE_SINGLE
	bytes[0] = (uint8_t)(val.val_int >> 24);
	bytes[1] = (uint8_t)(val.val_int >> 16);
	bytes[2] = (uint8_t)(val.val_int >>  8);
	bytes[3] = (uint8_t)(val.val_int);
#else
	bytes[0] = (uint8_t)(val.val_int >> 56);
	bytes[1] = (uint8_t)(val.val_int >> 48);
	bytes[2] = (uint8_t)(val.val_int >> 40);
	bytes[3] = (uint8_t)(val.val_int >> 32);
	bytes[4] = (uint8_t)(val.val_int >> 24);
	bytes[5] = (uint8_t)(val.val_int >> 16);
	bytes[6] = (uint8_t)(val.val_int >>  8);
	bytes[7] = (uint8_t)(val.val_int);
#endif

	const char *sep = "";
	int i;
	printf("%s\tfcb\t", label);
	for (i = 0; i < fpval_bytes; i++) {
		printf("%s$%02X", sep, bytes[i]);
		sep = ",";
	}
	printf("\n");
}

static void
emit_tcmp(const char *exp_label, int len)
{
	/*
	 * The Playground'09 emulator supports a "test compare"
	 * instruction specifically for unit tests like these.
	 *
	 *	X = buffer 1
	 *	Y = buffer 2
	 *	A = length
	 *
	 * X already points to the result.
	 */
	printf("\tldy\t#%s\n", exp_label);
	printf("\tlda\t#%d\n", len);
	printf("\tfdb\t$11fc\t\t; pg09 TCMP\n");
}

static void
emit_exit(void)
{
	printf("\tfdb\t$11fd\t\t; pg09 EXIT\n");
}

static void
emit_trc(uint8_t a)
{
	printf("\tfdb\t$11fb\t\t; pg09 TRC\n");
	printf("\tfcc\t%d\n", a);
}

static void
emit_pri(void)
{
	printf("\tfdb\t$11fe\t\t; pg09 PRI\n");
}

static int callnum;

static void
emit_dyadic(const char *comment,
    const char *op, fpval_type arg1, fpval_type arg2, fpval_type expected)
{
	char arg1_label[40], arg2_label[40], exp_label[40];
	char start_label[40], end_label[40];

	snprintf(arg1_label, sizeof(arg1_label), "call%d_arg1", callnum);
	snprintf(arg2_label, sizeof(arg2_label), "call%d_arg2", callnum);
	snprintf(exp_label, sizeof(exp_label), "call%d_exp", callnum);

	snprintf(start_label, sizeof(start_label), "call%d_start", callnum);
	snprintf(end_label, sizeof(end_label), "call%d_end", callnum);

	emit_section("CODE");
	printf("%s\n", start_label);
	printf("\t; %s\n", comment);
	printf("\tldu\t#%s\n", arg1_label);
	printf("\tldy\t#%s\n", arg2_label);
	printf("\tldd\t#fpcb\n");
	printf("\tldx\t#result\n");
	printf("\tnfp09_call FPOP_%s\n", op);
	emit_tcmp(exp_label, fpval_bytes);
	printf("\texport %s\n", end_label);
	printf("%s\n", end_label);
	printf("\n");

	emit_section("DATA");
	emit_fpval(arg1, arg1_label);
	emit_fpval(arg2, arg2_label);
	emit_fpval(expected, exp_label);
	printf("\n");

	callnum++;
}

static void
emit_monadic(const char *comment,
    const char *op, fpval_type arg2, fpval_type expected)
{
	char arg2_label[40], exp_label[40];
	char start_label[40], end_label[40];

	snprintf(arg2_label, sizeof(arg2_label), "call%d_arg2", callnum);
	snprintf(exp_label, sizeof(exp_label), "call%d_exp", callnum);

	snprintf(start_label, sizeof(start_label), "call%d_start", callnum);
	snprintf(end_label, sizeof(end_label), "call%d_end", callnum);

	emit_section("CODE");
	printf("%s\n", start_label);
	printf("\t; %s\n", comment);
	printf("\tldy\t#%s\n", arg2_label);
	printf("\tldd\t#fpcb\n");
	printf("\tldx\t#result\n");
	printf("\tnfp09_call FPOP_%s\n", op);
	emit_tcmp(exp_label, fpval_bytes);
	printf("\texport %s\n", end_label);
	printf("%s\n", end_label);
	printf("\n");

	emit_section("DATA");
	emit_fpval(arg2, arg2_label);
	emit_fpval(expected, exp_label);
	printf("\n");

	callnum++;
}

int
main(int argc, char *argv[])
{

	printf(
";\n"
";             ********** AUTOMATICALLY GENERATED **********\n"
";             **********     from gentests.c     **********\n"
";\n"
"; Copyright (c) 2022 Jason R. Thorpe.\n"
"; All rights reserved.\n"
";\n"
"; Redistribution and use in source and binary forms, with or without\n"
"; modification, are permitted provided that the following conditions\n"
"; are met:\n"
"; 1. Redistributions of source code must retain the above copyright\n"
";    notice, this list of conditions and the following disclaimer.\n"
"; 2. Redistributions in binary form must reproduce the above copyright\n"
";    notice, this list of conditions and the following disclaimer in the\n"
";    documentation and/or other materials provided with the distribution.\n"
";\n"
"; THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR\n"
"; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES\n"
"; OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.\n"
"; IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,\n"
"; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,\n"
"; BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;\n"
"; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED\n"
"; AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\n"
"; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY\n"
"; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF\n"
"; SUCH DAMAGE.\n"
";\n");

	printf(
"\n"
"	include \"../abi/nfp09-abi.s\"\n"
"\n"
"	; pg09-specific memory map stuff.\n"
"ROM_START	equ	$E000\n"
"\n"
"	org	$0000\n"
"	setdp	$00\n"
"\n"
"	;\n"
"	; The reset vector points to $0000, so we jump to the\n"
"	; real entry after our zero page variables.\n"
"	;\n"
"	jmp	testprog_start\n"
"\n"
"nfp09_entryvec\n"
"	rmb	2\n"
"fpcb\n"
"	rmb	SIZEOF_FPCB\n"
"result\n"
"	rmb	SIZEOF_FPBCD\n"
"\n"
"	section	\"CODE\"\n"
"testprog_start\n"
"	section \"CODE\"\n"
"	;\n"
"	; Initialize the stack.\n"
"	;\n"
"	lds	#stack_top\n"
"\n"
"	;\n"
"	; Initialize our NFP09 entry vector.\n"
"	;\n"
"	ldx	#ROM_START\n"
"	nfp09_set_regentry\n"
"\n"
"	;\n"
"	; Initialize the FPCB.\n"
"	;\n"
"	lda	#SIZEOF_FPCB\n"
"	ldx	#fpcb\n"
"1	clr	A,X\n"
"	deca\n"
"	bpl	1B\n"
#ifdef FPTYPE_SINGLE
"	lda	#FP_CTRL_SINGLE\n"
#else
"	lda	#FP_CTRL_DOUBLE\n"
#endif
"	sta	FPCB_FP_CTRL,X\n"
"\n"
"	section	\"DATA\"\n"
#ifdef FPTYPE_SINGLE
"	fcn	\"NFP09 single-precision test program\"\n"
#else
"	fcn	\"NFP09 double-precision test program\"\n"
#endif
"	rmb	512\n"
"stack_top\n"
"\n"
"	section \"CODE\"\n"
"\n");

	/*
	 * Simple monadic calls.
	 */
	emit_monadic("FABS -1.0",
	    "FABS", FPCONST(-1.0), FPFUNC(fabs)(FPCONST(-1.0)));

	printf(
"\n"
"	section \"CODE\"\n"
"	; Exit out of the emulator.\n"
"	fdb	$11fd\t\t; pg09 EXIT\n");

	return 0;
}
