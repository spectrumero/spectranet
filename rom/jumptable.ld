/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   jptable : ORIGIN = 0x3E00, LENGTH = 0x100
}
SECTIONS
{
.text : {
        *(.text)
        *(text)
         __Htext = .;
        } > jptable
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        } > jptable
}

