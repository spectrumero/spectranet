BUILDING THE SPECTRANET ROMs/MODULES
------------------------------------

Pre-requisites:
A Unix-like build environment (Linux, BSD, Mac OSX, 
Windows with Cygwin, Windows with MinGW etc)

GNU binutils for Z80 (assembler, linker, ar, ranlib etc)
Perl for some build scripts (my intention is to remove this requirement)

To build:
In the top level directory, type "make"

To install:
A firmware programmer is generated in the directory 'installer'. This
must be run on a ZX Spectrum with a Spectranet. Two versions exist - a
version that programs just the base ROM set (first four pages), and
a version that programs the base ROM set and standard modules (basext,
streams, msgrom, config and snapman).

Run 'bin2tzx' to convert the install.bin / base.bin files to TZX files
to load via the Spectrum's tape port. Alternatively, to update a Spectranet
that is already programmed, load via ethernet using the 'ethup' utility:

  On the Spectrum:
  CLEAR 26999
  (press NMI button or short the NMI pins on the bare board)
  (Select 'Load arbitrary data...')

  On the build machine:
  ethup <IP-of-spectrum> install.bin 27000

  Then on the Spectrum, exit the NMI menu and:
  RANDOMIZE USR 27000

Or if you have the computer with the build mounted via TNFS or some other
filesystem, on the Spectrum:

  CLEAR 26999
  %aload "install.bin" CODE 27000
  RANDOMIZE USR 27000

Building z88dk libraries:

  make z88dk

You'll of course need the z88dk installed somewhere in your path to do
this. The build results live in the "z88dk" directory.

DEVELOPING
----------
The source tree is organized as follows:

rom:		The base 4 pages of the Spectranet flash, in other words
		the absolute minimum required to make it work. This
		includes the software interface to the ethernet hardware,
		socket library, TNFS client, NMI handler, BASIC extension
		handler  etc.
syslib:		Libraries of code that's used in more than one place.
		Includes basic user interface functions (42 column print
		routine, input routines), paging functions, flash writer
		etc. Most of these are used by the rom, and various utilities
		also use them (eg. the installer).
modules:	The core set of modules distributed with the Spectranet.
installer:	An installer program. Two versions are generated: one that
		only updates the base ROM (the bottom 4 pages of flash) and
		a version that installs the base ROM and core set of modules.
z88dk:		Libraries for developers using the z88dk: a socket library,
		a general 'Spectranet functions' library, and an HTTP lib.
include:	Assembler include files, including spectranet.inc (equs
		for calling functions in ROM), sockdefs.inc, sysvars.inc
		etc. (Note: the files here should be compatible with most
		assemblers).
buildtools:	Tools that are required to build some parts of the system.
		These will get built by running the top level makefile.
devtools:	Useful tools for development, for example "ethup", a program
		that sends data to be loaded directly into the Spectrum's
		RAM.
utils:		General utilities that are not specific to the Spectranet,
		for example bin2tzx (bin2tzx will be used by the build to
		make a TZX version of the installer).
examples:	Various bits of example code, code for the tutorials etc.

Note that the installer directory's Makefile has all the various binary
objects the installer uses listed as dependencies, and the rules necessary
to have them built, so as a convenience typing "make" in the installer 
directory is almost the equivalent to typing "make" at the top level.

Generated files
---------------
There are a number of files that look "sourcey" that are actually 
automatically generated, so don't edit them :-) (If they aren't actually
a versioned resource within svn, this is a good hint). Generally they
follow the pattern of "something.xinc". Usually they are symbols that can
only be resolved after something has been linked, but there's also
ver.xinc and date.xinc which allows a version/date built string to be
put into the build output so someone can see what build they have running
on the actual hardware.

More on syslib
--------------
If it turns out that something is going to get used in more than one place,
for example, in a module and inside some standalone utility, the code
ought to live in syslib so it's available to be linked by anything.
Currently, the following libraries are available:

libflashwrite.a		: Functions to write to the flash memory
libpager.a		: Paging functions. Used by the ROM and various
			  standalone utilities.
libromui.a		: 42 column print routine, routines to read the
			  keyboard. Used by the ROM and various standalone
			  utilities.

Note that if you're developing a module, it's unlikely you need to link
to either libpager or libromui - just include "spectranet.inc" and use
the functions there since they are already present in the ROM. However,
they are useful for standalone utilities. (Note that there's a little bit
of a complication at present with the 42 column print routine: it has
a lookup table that must not span two 256-byte pages; I hope to eliminate
this eventually, but until then see the .ld file for the installer on how
to make sure this lookup table gets put in the right place in your binary).

