How configuration works
=======================

The last 4K page of flash contains configuration for the hardware,
modules, which filesystem to mount etc. This is in two parts: base
configuration (things that need to be configured before things like
modules have initialized), and everything else.

The base configuration has the last 256 bytes in this 4K page.

The "everything else" configuration starts at the bottom of the 4K
page and goes to the end-256 bytes.

The configuration module has the following API:
Modulecall ID	Function
0x01		CFG_COPYCONFIG: Copy config to RAM to be able to write to it
			A flag is set once the data is copied, so subsequent
			calls won't re-copy (until CFG_COMMITCFG or
			CFG_ABANDONCFG has been called).
0x02		CFG_FINDSECTION: sets the configuration section we're 
			going to use. Section ID is in DE.
0x03		CFG_GETCFSTRING: gets a string item. The ID of the item is
			in A, and DE = destination address
0x04		CFG_GETCFBYTE: gets a byte item. A = id of item to get, and
			the byte is returned in A
0x05		CFG_GETCFWORD: gets a 16 bit item. Word returned in HL, and
			A specifies the ID of the item.
0x06		CFG_CREATESECTION: Creates a section with the ID specified
			in DE.
0x07		CFG_COMMITCFG: Commits the RAM copy of the configuration
			to flash memory.
0x08		CFG_SETCFGBYTE: Sets the byte item. The ID is in A, the
			value is in C. If the item doesn't exist it is
			created. If it exists, it's modified.
0x09		CFG_SETCFWORD: Sets the word item. The ID is in A and
			the value in BC. If the item doesn't exist it's
			created, if it exists it's modified.
0x0A		CFG_SETCFSTRING: Sets a string item. The ID is in A and
			the address of the string in DE. Creates the
			item if it doesn't exist, replaces it if it does.
0x0B		CFG_ABANDONCFG: Abandons the RAM copy of the configuration
			such that a new call to CFG_COPYCONFIG will fetch
			the data in flash.
0xFF		CFG_CREATENEWCFG: Creates a brand new blank configuration,
			getting rid of any config that may have been
			(once CFG_COMMITCFG is called).

Organization in memory:

Total cfg size:		2 bytes (first 2 bytes of 4K page)

Then come the sections.
Each section looks like this:
Section-ID		2 bytes
Section-size		2 bytes
First cfg item ID	1 byte
Cfg data		N bytes
Second cfg item ID	1 byte
Cfg data		N bytes
Nth cfg item ID		1 byte
... and so on.

Section-IDs for rom modules with a module ID should be 0x00 <module id>.
Anything without a module ID should have a nonzero MSB. To prevent conflicts,
coordinate them with me :-) It goes without saying 16 bit values are
little endian just like the Z80 itself.

The two most significant bits of the config item ID indicate what the
thing is:

00			Null terminated string
01			reserved
10			8 bit value
11			16 bit value

