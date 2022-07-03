# nfp09 - An IEEE 754 floating point library for the MC6809

nfp09 is a floating poing library for the MC6809 microprocessor, based on the original
Motorola MC6839 floating point firmware for MC6809 microprocessor, updated to build with the
[asm6809](https://www.6809.org.uk/asm6809/) assembler.

This work began as a fork of [fp09](https://github.com/brouhaha/fp09), which is copy of the
original code written in 1980 and released by Motorola in 1988.  The original code is preserved,
without any modification, in the *src/* directory, as well as Rich Kottke's documentation in
the *doc/* directory.

All of the modified source code lives in the *newsrc/* directory.  In that directory, you'll
find copies of the original source code, modified for the new assembler, a Makefile, and a
master source file called *nfp09.s*, which is responsible for including all of the other
source files in the correct order.  *nfp09.s* is the file that is built by asm6809 to
produce the binary image.

*nfp09.s* exists primarily because asm6809 does not support multi-object linking.  Another
upshot of this is that all symbols end up in the same namespace.  To avoid polluting the
namespace, I've made extensive use of asm6809's local label feature.  Alas, there were a few
instances where I needed to tweak conflicting symbol names or comment out duplicate-but-equal
equates.

Not all of the original source files have been converted.  I converted only those that were
required to build a binary image (I kept adding source files until I no longer had unresolved
symbols).  Note that this will NOT build a fully-compaible 6839 ROM image; specifically, I
have left off the trailing file that rounds it to 8K and includes the CRC ("endit.sa").  If
someone is interested in this functionality (i.e. linkability into OS-9 using the standard
mechanisms), I'm definitely open to it, but I didn't tackle it initially because it's not
required for my target application (which is to embed this library inside another ROM image).

### Files that have been converted
- check.sa
- comp.sa
- compare.sa
- dispat.sa
- equates.sa
- fads.sa
- fmuldv.sa
- frmsqt.sa
- frnbak.sa
- getput.sa
- ins.sa
- intflt.sa
- mvabsneg.sa
- notrap.sa
- outs.sa
- procs.sa
- rndexep.sa
- util.sa

While converting the source files, I also made an effort to beautify the source code.  There
is now a consistent indentation style, with an attempt to keep everything as uniform as possible.
Because of the limitations of asm6809's macro language, most of the macros used in the original
code were not used.  In particular, the control flow macros (IF-ELSE-ENDIF and WHILE-ENDWH) were
expanded by-hand and sometimes re-structured to produce more efficient code.  There are still
opportunities for optimization in this area.  The goal, of course, is not to make a binary that
is identical to the original 6839, but rather to implement the same functionality in a way that
is cycle- and space-efficient.

### Major to-do items

- I have found some for-sure bugs and some maybe bugs.  They're
  tagged with *XXXJRT* and I need to file Issues for them.
- I need to go through the warts.sa file and determine if issues
  need to be filed for those items as well.
  
### Minor to-do items

- Go back and remove some of the commented-out IF-ELSE-ENDIF comments.
  I originally kept them, but stopped including them as I converted more
  files beause it just made things harder to read.

### Testing

Yes!  There should be some!  I'm sure there are bugs lurking in here, both in the original code
and almost certainly ones that I added while doing the conversion.  I have some ideas about a
testing using my 6809 CPU emulator, and hand-wavy something something custom instructions to
compare computed results to expected results.  Anyway, if you're interested in helping out with
this effort, by all means let me know!
