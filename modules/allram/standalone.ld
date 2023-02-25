/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   himem : ORIGIN = 0x8000, LENGTH = 0x1000
}
SECTIONS
{
.text : {
        *(.text)
        *(text)
         __Htext = .;
        } > himem
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        } > himem
.bss :  {
         __Lbss = .;
        *(.bss)
        *(bss)
         __Hbss = .;
        } > himem
}

