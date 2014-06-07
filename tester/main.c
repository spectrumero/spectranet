/*
   Spectranet tester.
   Tests the various hardware functions to aid in fixing broken boards.
   */

#include <stdlib.h>
#include <stdio.h>
#include <spectrum.h>
#include <input.h>

#include "sntester.h"

main() {
    mainmenu();
}

void mainmenu() {
    int key;
#asm
    di
#endasm
    while(1) {
        zx_border(0);
        ia_cls();
        printk("Spectranet tester main menu\n\n");
        printk("0. Test workspace RAM\n");
        printk("1. Test paged RAM\n");
        printk("2. CPLD tests\n");
        printk("3. CPLD status register\n");
        printk("4. Dump first 20 bytes of flash\n");
        printk("9. Exit\n");

keyconsume:        
        in_WaitForKey();
        key=in_Inkey();
        switch(key) {
            case '0':
                testWorkspace();
                pressSpace();
                break;
            case '1':
                testPagedRam();
                pressSpace();
                break;
            case '2':
                testCPLD();
                break;
            case '3':
                getCPLDFlagBits();
                pressSpace();
                break;
            case '4':
                dumpFirstFewBytes();
                pressSpace();
                break;
            case '9':
                pageout();
#asm
                ei
#endasm
                return;
            default:
                goto keyconsume;
        }
    }

    pageout();
}

void ia_cls()
{
  // 32 cols, BRIGHT 1
  printk("\x13\x01");
  setUIAttrs();
  zx_border(0);
  zx_colour(INK_WHITE|PAPER_BLACK);
}

void setUIAttrs()
{
  printk("\x10\x36\x11\x48");
}

void pressSpace() {
    int key;

    printk("\nPress space to continue.\n");
    while(1) {
        key=in_Inkey();
        if(key == ' ')
            return;
    }
}

void toBinary(char byte, char *buf) {
    int i;
    for(i=0; i<8; i++) {
        if(byte << i & 0x80)
            *buf='1';
        else
            *buf='0';
        buf++;
    }
    *buf=0;
}
