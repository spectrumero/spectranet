OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")

MEMORY {
    udpsync : ORIGIN = 0xFF00, LENGTH = 0x0100
}
SECTIONS
{
.text : {
    *(.text)
    *(text)
    __Htext = .;
    } > udpsync
.data : {
    __Ldata = .;
    *(.data)
    *(data)
    __Hdata = .;
    } > udpsync
.bss : {
    __Lbss = .;
    *(.bss)
    *(bss)
    __Hbss = .;
    } > udpsync
}
