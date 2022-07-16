TESTPROGS=	nfp09test-single.bin nfp09test-double.bin
TESTSRCS=	nfp09test-single.s nfp09test-double.s
TESTROM=	nfp09test-pg09-rom.bin
CLEANFILES=	$(TESTPROGS) $(TESTROM) $(TESTSRCS) *.exp gentests-*
CFLAGS=		-O1 -g -Wall

all: $(TESTPROGS) $(TESTROM)

nfp09test-pg09-rom.bin: nfp09test-pg09-rom.s
	asm6809 -o nfp09test-pg09-rom.bin nfp09test-pg09-rom.s

nfp09test-single.bin: nfp09test-single.s
	asm6809 -E nfp09test-single.exp -o nfp09test-single.bin \
	    nfp09test-single.s

nfp09test-single.s: gentests-single
	-./gentests-single > nfp09test-single.s

nfp09test-double.bin: nfp09test-double.s
	asm6809 -E nfp09test-double.exp -o nfp09test-double.bin \
	    nfp09test-double.s

nfp09test-double.s: gentests-double
	-./gentests-double > nfp09test-double.s

gentests-single: gentests.c
	$(CC) -DFPTYPE_SINGLE -o gentests-single gentests.c

gentests-double: gentests.c
	$(CC) -DFPTYPE_DOUBLE -o gentests-double gentests.c

clean:
	-rm -f $(CLEANFILES)
