/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   main : ORIGIN = 27000, LENGTH = 0x0080
   lut : ORIGIN = 0x6A00, LENGTH = 0x002C
   installer : ORIGIN = 0x6A2D, LENGTH = 0xFFFF-0x6A2D
}
SECTIONS
{
.main : {
        *(.main)
        *(main)
        __Hmain = .;
      } > main
.lookup : {
	*(.lookup)
	*(lookup)
	__Hlookup = .;
	} > lut
.text : {
        *(.text)
        *(text)
         __Htext = .;
        } > installer
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        } > installer
.bss :  {
         __Lbss = .;
        *(.bss)
        *(bss)
         __Hbss = .;
        } > installer
}

