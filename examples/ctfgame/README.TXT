Capture the Flag
================

This example is the most complex example for the Spectranet. It runs
on a 48K or 128K machine.

It's a client/server team game for two teams of up to two players in
each team (it could be expanded). It shows the use of the following:

- Making a multi-load game which uses the Spectranet filesystem.
- Passing an open socket from one program to another when multiloading.
- Using a short BASIC program to orchestrate the multiloading.
- Using the Z88DK's sprite library with a networked game.

The server code keeps track of all the objects in the game, and is written
in straight C. It is targeted at modest hardware, and runs perfectly on
an ancient MicroVAX just as well as it does on a brand new multi-core
AMD64 box.

The protocol between the client and server is a 'packed binary' protocol,
basically, it basically copies the C structs into a buffer and sends it
in a datagram. However, not much attention has been paid to portability,
at present it requires a little-endian system to be the server. This means
it runs happily on:

- Intel/AMD based PCs and Macintoshes under Linux, BSD, Mac OSX, Windows etc.
- VAX
- Raspberry Pi (ARM)

It will need some porting work to run on SPARC or POWER. With some work
(supporting the Unixisms and any endian issues) it might not be too 
hard to port to old Acorn ARM hardware or perhaps the Amiga when TCP/IP 
is available.

Building
========

You'll need the z88dk and the SP1 sprite library to build the Spectrum
client, as well as the Spectranet socket library. Then just go into
the 'client' directory and run 'make'. You'll get a couple of binaries.
The 'boot.zx' file is a BASIC program that may be loaded on a Spectrum
and will load the client.

To build the server, on anything Unixy you just need the basic C compiler.
Run 'make -f Makefile.linux' for anything non-BSD, run 'make' for anything
BSD-like (including Mac OSX), run 'make -f Makefile.win32' for Windows.
On Windows, it will build using MinGW.

Running the game
================

On the server, start it by running 'ctfserv' with the filename of the
map file. A couple of maps are provided named 'map<something>.txt'. Maps
are just text files. You can easily create your own with a text editor.
If you look at the example ones, you can get the basics of it.

On the Spectrum, mount the filesystem where the client is, and then
do %load "" (the location should have boot.zx, matchmake.bin and
ctfclient.bin in it). Then follow the instructions on screen, basically
just enter a player name and the IP address of the server, make all the
players ready then start the game.

Keys are QAOPM.

