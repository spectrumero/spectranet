/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   pageb : ORIGIN = 0x3000, LENGTH = 0x1000
}
SECTIONS
{
.main : {
        *(.main)
        *(main)
        __Hmain = .;
      } > pageb
.text : {
        *(.text)
        *(text)
         __Htext = .;
        } > pageb
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        } > pageb
.bss :  {
         __Lbss = .;
        *(.bss)
        *(bss)
         __Hbss = .;
        } > pageb
}

