Minimal flash identifier tool.

Works with flash chips using 0x5555 and 0x2AAA programming addresses
(e.g. SST39SF0x0)

Does not depend on Spectranet RAM being present, will work on a Spectranet
board that just contains the CPLD and flash memory. Uses the Spectrum ROM
print routine to write its output.

To build, run make.

To run on the Spectrum:
CLEAR 32767
LOAD "" CODE
RANDOMIZE USR 32768

If you have a working Spectranet, you can use ethup to load the .bin
file instead of the tap file via audio or DivIDE. You can also load the
tap file using the %tapein command.

