#!/usr/bin/perl
# Generate a file with z88dk's z80asm DEFC syntax.
#
use strict;
open FHND, "< spectranet.asm" or die("Could not open spectranet.asm: $!");
open OHND, "> ../socklib/spectranet.asm" or die("Could not open output file: $!");
while(my $line=<FHND>)
{
	if($line =~ /^[A-Z]/)
	{
		chomp $line;
		my($sym, $equ, $val)=split(/\s{1,}/, $line, 3);
		print OHND "DEFC $sym = $val\n";
	}
}
close FHND;
close OHND;

