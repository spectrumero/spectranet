/* Spectranet modules LD script */
OUTPUT_FORMAT("binary")
OUTPUT_ARCH("z80")
MEMORY {
   pagez : ORIGIN = 0x007D, LENGTH = 0x0F83 
   rst0 : ORIGIN = 0x0000, LENGTH = 0x0008
   rst8 : ORIGIN = 0x0008, LENGTH = 0x0008
   rst10 : ORIGIN = 0x0010, LENGTH = 0x0018
   rst28 : ORIGIN = 0x0028, LENGTH = 0x0008
   rst30 : ORIGIN = 0x0030, LENGTH = 0x0008
   isr : ORIGIN = 0x0038, LENGTH = 0x002E
   nmi : ORIGIN = 0x0066, LENGTH = 0x0014
   unpage : ORIGIN = 0x007B, LENGTH = 0x0002
}
SECTIONS
{
.rst0 : {
	*(.rst0)
	*(rst0)
	__Hrst0 = .;
	} > rst0
.rst8 : {
	*(.rst8)
	*(rst8)
	__Hrst8 = .;
	} > rst8
.rst10 : {
	*(.rst10)
	*(rst10)
	__Hrst10 = .;
	} > rst10
.rst28 : {
	*(.rst28)
	*(rst28)
	__Hrst28 = .;
	} > rst28
.rst30 : {
	*(.rst30)
	*(rst30)
	__Hrst30 = .;
	} > rst30
.isr : {
	*(.isr)
	*(isr)
	__Hisr = .;
	} > isr
.nmi : {
	*(.nmi)
	*(nmi)
	__Hnmi = .;
	} > nmi
.unpage : {
	*(.unpage)
	*(unpage)
	__Hunpage = .;
	} > unpage
.text : {
        *(.text)
        *(text)
         __Htext = .;
        } > pagez
.data : {
         __Ldata = .;
        *(.data)
        *(data)
         __Hdata = .;
        } > pagez
.bss :  {
         __Lbss = .;
        *(.bss)
        *(bss)
         __Hbss = .;
        } > pagez
}

