/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   pagea : ORIGIN = 0x1000, LENGTH = 0x1000
   lut   : ORIGIN = 0x1F80, LENGTH = 0x0080
}
SECTIONS
{
.text : {
        *(.text)
        *(text)
         __Htext = .;
        } > pagea
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        } > pagea
.bss :  {
         __Lbss = .;
        *(.bss)
        *(bss)
         __Hbss = .;
        } > pagea
.lookup : {
	*(.lookup)
	*(lookup)
	__Hlookup = .;
	} > lut
}

