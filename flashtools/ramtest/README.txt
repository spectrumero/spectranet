Basic RAM tester
================

Checks that Spectranet RAM paging has basic functionality. This isn't
a comprehensive RAM test, but if it works, it's pretty likely the RAM
is fine.

It pages each RAM page into paging space A, and writes the page number
to the first byte of that page. It then goes back and reads back the
values from the first byte of each page into the Spectrum's RAM.

If memory paging is working OK, then the output should show the hex values
C0 to DF (each RAM page). Unexpected values will give an idea of which RAM
pages aren't working, or if there's a fault in the paging mechanism.

To run, load the resulting TAP file:
CLEAR 32767
LOAD "" CODE
RANDOMIZE USR 32768

Note that it's probably best to run this utility with the 'disable all'
jumper closed, as this might overwrite important things in a Spectranet
that's actually being used!

