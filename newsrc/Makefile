ROM_IMAGES=	nfp09.bin

ROM_DEPS=	nfp09.s

ROM_DEPS+=	dispat.s
ROM_DEPS+=	equates.s
ROM_DEPS+=	frnbak.s
ROM_DEPS+=	getput.s
ROM_DEPS+=	macros.s
ROM_DEPS+=	procs.s

CLEANFILES=	$(ROM_IMAGES) *.lst

all: $(ROM_IMAGES)

nfp09.bin: $(ROM_DEPS)
	asm6809 -l nfp09.lst -o nfp09.bin nfp09.s

clean:
	-rm -f $(CLEANFILES)
