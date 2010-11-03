/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   pageb : ORIGIN = 0x2000, LENGTH = 0x1000
}
SECTIONS
{
.vectors : {
        *(.vectors)
        *(vectors)
        __Hvectors = .;
      } > pageb
.isr : {
        *(.isr)
        *(isr)
        __Hisr = .;
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

