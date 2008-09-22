#include <stdio.h>
#include <spectranet.h>

char *token="*foo";

void foocmd();

main()
{
	struct basic_cmd bc;

	bc.errorcode=0x0b;	// nonsense in basic
	bc.command=token;
	bc.rompage=0;		// don't do paging
	bc.function=foocmd;

	if(addbasicext(&bc) < 0)
	{
		printk("Failed to add extension\n");
		return;
	}
	printk("Added basic extension.\n");
}

void foocmd()
{
	statement_end();
	printk("Statement executed.\n");
#asm
	jp 0x3E99
#endasm
}

