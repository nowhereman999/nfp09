ROM_IMAGES=	nfp09.bin nfp09-reg-abi.bin nfp09-stack-abi.bin

ROM_DEPS=	nfp09.s
ROM_DEPS+=	Makefile

ROM_DEPS+=	check.s
ROM_DEPS+=	comp.s
ROM_DEPS+=	compare.s
ROM_DEPS+=	dispat.s
ROM_DEPS+=	equates.s
ROM_DEPS+=	fads.s
ROM_DEPS+=	fmuldv.s
ROM_DEPS+=	frmsqt.s
ROM_DEPS+=	frnbak.s
ROM_DEPS+=	getput.s
ROM_DEPS+=	ins.s
ROM_DEPS+=	intflt.s
ROM_DEPS+=	macros.s
ROM_DEPS+=	mvabsneg.s
ROM_DEPS+=	notrap.s
ROM_DEPS+=	outs.s
ROM_DEPS+=	procs.s
ROM_DEPS+=	rndexep.s
ROM_DEPS+=	util.s
ROM_DEPS+=	utilio.s

CLEANFILES=	$(ROM_IMAGES) *.lst

all: $(ROM_IMAGES)

nfp09.bin: $(ROM_DEPS)
	asm6809 -d CONFIG_REG_ABI=1 -d CONFIG_STACK_ABI=1 \
	    -l nfp09.lst -o nfp09.bin nfp09.s

nfp09-reg-abi.bin: $(ROM_DEPS)
	asm6809 -d CONFIG_REG_ABI=1 \
	    -l nfp09-reg-abi.lst -o nfp09-reg-abi.bin nfp09.s

nfp09-stack-abi.bin: $(ROM_DEPS)
	asm6809 -d CONFIG_STACK_ABI=1 \
	    -l nfp09-stack-abi.lst -o nfp09-stack-abi.bin nfp09.s

clean:
	-rm -f $(CLEANFILES)
