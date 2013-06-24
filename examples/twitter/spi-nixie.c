#ifdef NIXIE_DISPLAY
// SPI-nixie display interface.
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "spi-nixie.h"

static char display_buf[16];

void display_int(unsigned short num, unsigned short pos)
{
	if(pos > 6)
		return;

	memset(display_buf, ' ', 7);
	sprintf(display_buf+pos, "%d", num);
	*(display_buf+strlen(display_buf))=' ';
	spi_display(display_buf);
}

void display_ra_int(unsigned short num) {
	char buf[8];
	memset(display_buf, ' ', 7);
	sprintf(buf, "%d", num);
	strcpy(display_buf+7-strlen(buf), buf);
	spi_display(display_buf);
}

void display_la_int(unsigned short num) {
	sprintf(display_buf, "%d", num);
	memset(display_buf+strlen(display_buf), ' ', 7);
	spi_display(display_buf);
}

// Initialize the hardware. Turn on the clock divider and use the 5th
// stage. (Binary 00011000)
void spi_init() {
#asm
	ld bc, 0x053B
	ld a, 0x18
	out (c), a
#endasm
}

void __FASTCALL__ flash_display(unsigned char flash) {
#asm
	ld bc, 0x043B
	ld a, 0xAB
	out (c), a
	ld b, 0x05
.wait_flash
	in a, (c)
	and 0x80
	jr nz, wait_flash
	
	; it seems like the microcontroller code here is a bit
	; slow and needs a delay.
	ld b,255	
.delayloop1
	nop
	djnz delayloop1

	ld b, 0x04
	out (c), l


	ld b,255	
.delayloop2
	nop
	djnz delayloop2
#endasm
}

void __FASTCALL__ set_led(unsigned char led) 
{
#asm
	ld bc, 0x043B
	ld a, 0xAE
	out (c), a
	ld b, 0x05
.wait_led
	in a, (c)
	and 0x80
	jr nz, wait_led

	; it seems like the microcontroller code here is a bit
	; slow and needs a delay.
	ld b, 255
.delayloop
	nop
	djnz delayloop

	ld b, 0x04
	out (c), l

	ld b, 255
.delayloop3
	nop
	djnz delayloop3
#endasm
}

// The string must be exactly 7 characters long.
void __FASTCALL__ spi_display(char *string)
{
#asm
	ld bc, 0x043B
	ld a, 0xAA	; Send "Display characters" request
	out (c), a
	ld b, 7
.loop
	push bc
	ld bc, 0x053B
.busy_check
	in a, (c)
	and 0x80	; mask out everything except bit 7
	jr nz, busy_check

	ld b, 0x04
	ld a, (hl)
	out (c), a
	inc hl
	pop bc
	djnz loop
#endasm
}
#endif

