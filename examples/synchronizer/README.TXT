UDP synchronizer

This is a very simple example of how to use a UDP datagram to
synchronize two machines (somewhat, remember there will be a
bit of latency, even on a LAN, but it should be enough to
synchronize multiple machines making music, for example).

It is also a relatively simple example of how to use the GNU
assembler toolchain. If you use a different assembler you will
probably have to modify the source files a bit. It uses a simple
linker script (the .ld file) to tell the linker where to put 
the assembled object code. Look in the .map file to find the
addresses of the various routines once they have been built.

If you've not modified the sources, the addresses you need are:

0xFF00  (65280)     Call to open the socket and bind to port 2500
0xFF1A  (65306)     Call to close the socket
0xFF2D  (65325)     Call to wait for a datagram
0xFF49  (65353)     On the sender, use one time to set the port
0xFF50  (65360)     Call to transmit a datagram

The transmitting side also needs to set the IP address of the
receiver, POKE the following addresses:
0xFF69  (65385)     First octet of the destination IP address
0xFF6A  (65386)     Second octet
0xFF6B  (65387)     Third octet
0xFF6C  (65388)     Fourth octet

The 2 bytes to be sent in the datagram can be set by POKEing:
0xFF71  (65393)     Low order byte
0xFF72  (65394)     High order byte

