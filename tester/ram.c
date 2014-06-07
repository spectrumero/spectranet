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
#include "sntester.h"

unsigned char *faultPtr;
unsigned char intendedByte;
unsigned char faultByte;

int prngTest(int seed, unsigned char *start, unsigned short length) {
    unsigned char *ptr=start;
    unsigned short remaining=length;

    printk("Starting test with seed %d start=%d len=%d\n",
            seed, start, length);

    // initialize prng for fill
    srand(seed);
    pageIn();
    while(remaining--) {
       *ptr++ = rand() & 0xFF;
    }

    // read back contents
    srand(seed);
    remaining=length;
    ptr=start;

    while(remaining--) {
        intendedByte=rand() & 0xFF;
        if(*ptr != intendedByte) {
            faultPtr=ptr;
            faultByte=*ptr;
            pageOut();
            return 0;
        }
        ptr++;
    }
    pageOut();

    return 1;
}

void testWorkspace() {
    unsigned char *addr=0x3000;
    printk("Testing workspace with PRNG fill\n");
    if(prngTest(0, addr, 1024)) {
        printk("Workspace OK.\n");
    }
    else {
        printMemoryFault();
    }
}

void testPagedRam() {
    int page;
    int length;
    unsigned char *ptr;

    printk("Filling paged RAM with ascending sequence.\n");
    pageIn();
    for(page=0xC0; page < 0xE0; page++) {
        ptr=(unsigned char *)0x2000;
        setPageB(page);

        length=1024;
        while(length--) {
            *ptr=(unsigned char)page;
        }
    }
    pageOut();
    printk("Reading back paged RAM\n");
    pageIn();

    for(page=0xC0; page < 0xE0; page++) {
        ptr=(unsigned char *)0x2000;
        setPageB(page);

        length=1024;
        intendedByte=(unsigned char)page;
        while(length--) {
            if(*ptr != intendedByte) {
                faultPtr=ptr;
                faultByte=*ptr;
                pageOut();
                printMemoryFault();
                return;
            }
        }
    }
    pageOut();
    
    printk("Page test complete.\n");
}

void printMemoryFault() {
    char buf[9];
    printk("Memory fault detected:\n");

    ultoa((unsigned long)faultPtr, buf, 16);
    printk("Address : %s\n", buf);

    toBinary(faultByte, buf);
    printk("Content : %s", buf);
    ultoa((unsigned long)faultByte, buf, 16);
    printk("  hex %s\n", buf);

    toBinary(intendedByte, buf);
    printk("Intended: %s", buf);
    ultoa((unsigned long)intendedByte, buf, 16);
    printk("  hex %s\n", buf);
}

