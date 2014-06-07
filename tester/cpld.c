/* 
 * The MIT License
 *
 * Copyright (c) 2014 Dylan Smith
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <input.h>

#include "sntester.h"

void releaseW5100() {
#asm
    ld bc, CTRLREG
    in a, (c)
    set 7, a
    out (c), a
#endasm
}

void holdW5100() {
#asm
    ld bc, CTRLREG
    in a, (c)
    res 7, a
    out (c), a
#endasm
}

void testCPLD() {
    unsigned char ctrlreg;
    unsigned char buf[9];
    int key;
    ia_cls();

    printk("Border = red when W5100 link light on\n");
    printk("Press space to exit\n");
    printk("Control register bits:\n");

    releaseW5100();
    while(1) {
        ctrlreg=getCtrlReg();

        toBinary(ctrlreg, buf);
        printk("\x16\x25\x20%s\n", buf);
        if(ctrlreg & 0x40) 
            zx_border(2);
        else
            zx_border(1);

        key=in_Inkey();
        if(key == ' ')
            break;
    }
    holdW5100();
    zx_border(0);
}

void getCPLDFlagBits() {
    unsigned char ctrlreg;

    printk("CPLD flag bits:\n");
    printk("Control register:\n");
    ctrlreg=getCtrlReg();

    printk("Border colour: %d\n", ctrlreg & 7);
    printk("Trap enable  : %d\n", ctrlreg & 8);
    printk("128K screen  : %d\n", ctrlreg & 0x10);
    printk("A15 disable  : %d\n", ctrlreg & 0x20);
    printk("Link light   : %d\n", ctrlreg & 0x40);
    printk("Reserved     : %d\n", ctrlreg & 0x80);


}

unsigned char getCtrlReg() {
#asm
    ld bc, CTRLREG
    in l, (c)
    ld h, 0
#endasm
}

