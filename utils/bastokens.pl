#!/usr/bin/perl
use FileHandle;
use strict;

my @TOKEN=(
	"RND","INKEY\$","PI","FN","POINT","SCREEN\$","ATTR ","AT ","TAB ", 
	"VAL\$ ","CODE ","VAL ","LEN ","SIN ","COS ","TAN ","ASN ","ACS ","ATN ",
	"LN ","EXP ","INT ","SQR ","SGN ","ABS ","PEEK ","IN ","USR ",
	"STR\$ ","CHR\$ ","NOT ","BIN "," OR "," AND ","<=",">=","<>",
	"LINE "," THEN "," TO "," STEP ","DEF FN ","CAT ","FORMAT ","MOVE ",
	"ERASE ","OPEN # ","CLOSE # ","MERGE ","VERIFY ","BEEP ","CIRCLE ",
	"INK ","PAPER ","FLASH ","BRIGHT ","INVERSE ","OVER ","OUT ","LPRINT ",
	"LLIST ","STOP ","READ ","DATA ","RESTORE ","NEW","BORDER ","CONTINUE ",
	"DIM ","REM ","FOR ","GO TO ","GO SUB ","INPUT ","LOAD ",
	"LIST ","LET ","PAUSE ","NEXT ","POKE ","PRINT ","PLOT ","RUN ","SAVE ",
	"RANDOMIZE ","IF ","CLS","DRAW ","CLEAR ","RETURN","COPY ");

binmode STDIN;
my $kmode=1;
while(1)
{
	my $chr=getc(STDIN);
	if($chr eq undef) { last; }
	
	my $ord=ord($chr);

	if($ord > 0xA4)
	{
		if($kmode) 
		{ 
			print " ";
	       		$kmode=0;	
		}
		print $TOKEN[$ord - 0xA5];
	}
	else
	{
		print $chr;
	}

	if($ord == 0x0d || $chr eq ":") { $kmode=1; }
}

