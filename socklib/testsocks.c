#include <stdio.h>
#include <input.h>

#include "testsocks.h"

main()
{
	unsigned int opt;

	while(1)
	{
#asm
	ld hl, 0x3E30
	call 0x3FFA
#endasm

		printf("Socket library test.\n");
		printf("====================\n\n");

		printf("1...Client test\n");
		printf("2...Non multiplexed server\n");
		printf("3...Multiplexed server\n");
		printf("4...UDP server\n");
		printf("9...Exit\n");

		printf("\nChoice: ");
		while((opt=in_Inkey()) == 0);
		
		switch(opt)
		{
			case '1':
				testclient();
				break;
			case '2':
				testnonmuxedserver();
				break;
			case '3':
				testmuxedserver();
				break;
			case '4':
				testudpserver();
				break;
			case '9':
				return;
		}
	}				
}

