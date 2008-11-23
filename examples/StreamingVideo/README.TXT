Streaming Video example
=======================

This is a really simple example of the Spectranet in action.

Compile bwtest.c on a PC (the source is for Unixy operating systems, you may
need to change the #include files for Windows). Unzip the BWTest.zip file on
the PC.

Assemble bwtestrx.asm and send it to the Spectrum.

Run bwtestrx on the Spectrum, and "bwtest <ipaddr-of-spectrum>" on the PC,
in the same directory as the unzipped BWTest.zip file.

And you should see the video show on the Spectrum. The BWTest.bin file is
just a sequence of Spectrum SCREEN$ images.

