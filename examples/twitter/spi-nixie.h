#ifndef _SPI_NIXIE_H
#define _SPI_NIXIE_H

extern void display_int(unsigned short num, unsigned short pos);
extern void display_ra_int(unsigned short num);
extern void display_la_int(unsigned short num);

extern void __FASTCALL__ flash_display(unsigned char flash);
extern void __FASTCALL__ set_led(unsigned char led);

extern void spi_init();
extern void __FASTCALL__ spi_display(char *string);

#endif

