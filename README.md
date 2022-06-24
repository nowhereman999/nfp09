# nfp09
Motorola MC6839 floating point firmware for MC6809 microprocessor, updated for modern assemblers

This is a fork of [fp09](https://github.com/brouhaha/fp09) that has been updated for modern assemblers.
It is a work-in-progress.  The *doc/* and *src/* directories are un-changed from the original.
The *newsrc/* directory contains the updated source code, along with notes.

The basic approach I'm taking is to try and keep the macro structure of the original as much as
possible.  However asm6809's macro language is not as rich, so there are some cases where a
parameterized macro has been replaced with multiple macros.

I'm also making an effort to tidy up the code from a readability perspective, mainly around
how comments are handled (the original Motorola assembler syntax is really bothersome, if
you ask me).  I am, however, keeping all of the original symbol and equate names.
