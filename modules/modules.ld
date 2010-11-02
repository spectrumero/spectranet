/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
. = 0x2000;
OUTPUT_ARCH("z80")
SECTIONS
{
.vectors : {
        *(.vectors)
        *(vectors)
        __Hvectors = .;
      }
.isr : {
        *(.isr)
        *(isr)
        __Hisr = .;
       }
.text : {
        *(.text)
        *(text)
         __Htext = .;
        }
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        }
.bss :  {
         __Lbss = .;
        *(.bss)
        *(bss)
         __Hbss = .;
        }
}

