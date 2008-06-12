Example IRC client - ZX-IRC
===========================

This is an example to show the multiplexing of user input, socket input,
and the handling of the keyboard where processing messages might take
enough time that a keypress might get missed if it was polled along with
all the other stuff that's going on.

Certain curiosities
-------------------
strlcat/strlcpy: These are safer string copy/concatenation routines
that were developed originally for the OpenBSD operating system, and have
since found their way into all BSD C libraries. Network code has to
deal with arbitrary buffers and all sorts of stuff may be jammed into
a buffer - these are used to try and reduce the risk of overwriting memory
that shouldn't be overwritten when handling C strings.

At the time of writing, the Z88DK did not have an snprintf() function,
so there are some rather clumsy looking routines with lines of strlcats,
since sprintf is pretty unsafe unless you're absolutely certain that
there's no way you can overrun the memory allocated.

