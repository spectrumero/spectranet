/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   wkspace : ORIGIN = 0x3000, LENGTH = 0x200
}
SECTIONS
{
.text : {
        *(.text)
        *(text)
         __Htext = .;
        } > wkspace
}

