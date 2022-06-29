;
; nfp09.s
;
; Main file building nfp09.  This includes the individual source files
; in the correct order.
;

	; Pull in the macros used all over the place.
	include "macros.s"

	; Pull in the global equates.
	include "equates.s"

	;
	; frnbak.s must be the first real source file, as it includes
	; the ROM-LINK header.
	;
	include "frnbak.s"

	include "getput.s"
	include "dispat.s"
	include "comp.s"
	include "procs.s"
	include "rndexep.s"
	include "notrap.s"
	include "check.s"
	include "intflt.s"
	include "mvabsneg.s"
	include "util.s"
