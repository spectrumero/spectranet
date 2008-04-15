#!/usr/bin/perl
use strict;
my $file=shift;
if(!$file)
{
	die("Usage: extractsym.pl <filename> <symbol1> <symbol2> ...");
}

open FHND, "< $file" or die("Could not open $file: $!");
my %symbols;
while(my $line=<FHND>)
{
	chomp $line;
	my ($symbol, $value)=split(/:/, $line, 2);
	$symbols{$symbol}=$value;
}
close FHND;

while (my $sym=shift)
{
	if($symbols{$sym})
	{
		print "$sym:$symbols{$sym}\n";
	}
}

