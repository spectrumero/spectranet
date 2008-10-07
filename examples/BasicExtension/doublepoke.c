/* Double poke example in C */
/* Pokes a 16 bit value into memory */

#include <stdio.h>
#include <spectranet.h>
#include <basicext.h>

char *token="*poke";
void doublepoke();

main()
{
	struct basic_cmd bc;	// BASIC command struct
	bc.errorcode=0x0b;	// C Nonsense in BASIC
	bc.command=token;	// Pointer to the token to interpret
	bc.rompage=0;		// don't page
	bc.function=doublepoke;	// pointer to function to call

	if(addbasicext(&bc) < 0)
	{
		printk("Failed to add extension\n");
		return;
	}
	printk("Added BASIC extension\n");
}

void doublepoke()
{
	unsigned int addr, value;

	// Syntax time
	expect2Num();		// Two numbers separated by commas
	statement_end();	// followed by statement end.

	// Run time
	value=find_int2();	// get the value to be poked
	addr=find_int2();	// get the address to be poked

	// Now do some casting tricks to write to memory.
	// This turns addr from being an ordinary unsigned int to an
	// address in memory to write (with the value of the int, of course).
	// So if addr=16384, the RAM address 16384 will be poked.
	*((unsigned int *)addr)=value;

	// Jump to EXIT_SUCCESS
#asm
	jp 0x3e99
#endasm
}

