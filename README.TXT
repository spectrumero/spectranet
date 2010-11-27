BUILDING THE SPECTRANET ROMs/MODULES
------------------------------------

Pre-requisites:
A Unix build environment (Linux, BSD, Mac OSX, Windows with Cygwin, Windows
with MinGW etc)
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

DEVELOPING
----------
If you intend to work on the ROM sources or modules, it's advisable to 
also generate the dependencies, by running 'buildtoos/makedeps'. This
will ensure if you alter an include file, everything that depends on it
gets rebuilt the next time 'make' is run.

