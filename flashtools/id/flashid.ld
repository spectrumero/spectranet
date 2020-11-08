OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   main : ORIGIN = 32768, LENGTH = 0x0100
}
SECTIONS
{
.main : {
        *(.main)
        *(main)
        __Hmain = .;
      } > main
.text : {
        *(.text)
        *(text)
         __Htext = .;
        } > main
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        } > main
.bss :  {
         __Lbss = .;
        *(.bss)
        *(bss)
         __Hbss = .;
        } > main
}

