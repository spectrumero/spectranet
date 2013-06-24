Twitter client
==============

This client was written when Twitter used to have an API that was amenable
to embedded devices and 8 bit systems. It didn't require encryption or any
complex authentication schemes. Sadly this is no longer the case and it is
impossible to send a simple 140 character message without needing a processor
that's capable of at least a few tens of MIPS. The current API requires
OAuth, which is a non-starter for an 8 bit system, and the web interface
forces HTTPS (which requires encryption, of course).

Because of this, to use this client you'll need to run the Twitter proxy.
This basically takes care of the encryption and presents the old API as
it stood in 2010. It's a shame the Speccy can't directly send a tweet
any more, but it's doing what it was doing in 2010 so it's not really
cheating! The Raspberry Pi is an ideal system to run the proxy, but any
PC or server will do.

See the subdirectory 'proxy' for information on how to run it. You'll need
Perl.

Running the client
==================

You must CLEAR 27999 before running the client and make sure the Twitter
proxy is running somewhere where you can reach it.

A suitable BASIC loader to load this via a Spectranet filesystem is:

10 CLEAR 27999
20 BORDER 0: PAPER 0: INK 5: CLS
30 %aload "twitter.bin" CODE 32768
40 RANDOMIZE USR 32768

