Twitter client
==============

This will work as long as Twitter still allow their old Android client
access via HTTP Basic auth. OAuth is unfortunately a non starter for an
8 bit machine. When Twitter eventually turn off the Android basic auth,
I'll add a Twitter proxy to do all the SSL stuff, and we'll have to
go via the Twitter mobile web front end.

You must CLEAR 27999 before running the client.

A suitable BASIC loader to load this via a Spectranet filesystem is:

10 CLEAR 27999
20 BORDER 0: PAPER 0: INK 5: CLS
30 %aload "twitter.bin" CODE 32768
40 RANDOMIZE USR 32768

