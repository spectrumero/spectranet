; Spectrum system variables.
; This just a list of numbers from various Spectrum manuals.

; 128k paging
ZX_BANKM	equ 23388	; All 128k machines
ZX_BANK678	equ 23399	; +3/2a only

; 128k paging I/O ports
ZX_IO_BANKM	equ 0x7FFD
ZX_IO_BANK678	equ 0x1FFD
ZX_IO_ULA	equ 0xFE

; Standard system variables
ZX_KSTATE	equ 23552	; 8 - Used when reading the kb
ZX_LAST_K	equ 23560	; 1 - Stores newly pressed key
ZX_REPDEL	equ 23561	; 1 - Time in 50th sec for key repeat
ZX_REPPER	equ 23562	; 1 - Delay in 50th sec for successive repeats
ZX_DEFADD	equ 23563	; 2 - Address of args of user defined fn
ZX_K_DATA	equ 23565	; 1 - 2nd byte of colour controls from kb
ZX_TVDATA	equ 23566	; 2 - Colour/AT/TAB to display
ZX_STRMS	equ 23568	; 38 - Addresses of channels attached to strms
ZX_CHARS	equ 23606	; 2 - 256 less than charset
ZX_RASP		equ 23608	; 1 - Length of warning buzz
ZX_PIP		equ 23609	; 1 - Length of kb pip
ZX_IB		equ 23610	; Interpreter sysvars base address
ZX_ERR_NR	equ 23610	; 1 - 1 less than the report code.
ZX_FLAGS	equ 23611	; 1 - Various BASIC flags
ZX_TV_FLAG	equ 23612	; 1 - Display flags
ZX_ERR_SP	equ 23613	; 2 - Machine stack for addr. for error return
ZX_LIST_SP	equ 23615	; 2 - Return address from automatic listing
ZX_MODE		equ 23617	; 1 - K, L, C, E or G cursor
ZX_NEWPPC	equ 23618	; 2 - Line to be jumped to
ZX_NSPPC	equ 23620	; 1 - Stmt number to jump to
ZX_PPC		equ 23621	; 2 - Line num of statement being exec'd
ZX_PPC_HI	equ 23622	; MSB of the above
ZX_PPC_LO	equ 23621	; LSB of the above
ZX_SUBPPC	equ 23623	; 1 - Number within line of stmt being exec'd
ZX_BORDCR	equ 23624	; 1 - Border colour * 8
ZX_E_PPC	equ 23625	; 2 - Number of curr. line with pgm cursor
ZX_VARS		equ 23627	; 2 - Address of vars
ZX_DEST		equ 23629	; 2 - Address of variable in assignment
ZX_CHANS	equ 23631	; 2 - Address of channel data
ZX_CURCHL	equ 23633	; 2 - Address of current IO
ZX_PROG		equ 23635	; 2 - Address of BASIC program
ZX_CH_ADD	equ 23645	; 2 - Address of next char to be interpreted
ZX_X_PTR	equ 23647	; 2 - Address of char after ? marker
ZX_X_PTR_HI	equ 23648	; MSB of X_PTR
ZX_FLAGS2	equ 23658	; 1 - More flags
ZX_OLDPPC	equ 23662	; 2 - where CONTINUE jumps
ZX_FLAGX	equ 23665
ZX_E_LINE	equ 23641	; 2 - address of line being typed in
ZX_SCR_CT	equ 23692	; 1 - Scroll count
ZX_ATTR_T	equ 23695	; 1 - Temporary current colours
ZX_P_FLAG	equ 23697	; 1 - More flags
ZX_RAMTOP	equ 23730	

; Displacements
D_ERR_NR	equ 0
D_FLAGS		equ 1
D_TV_FLAG	equ 2
D_CHBYTE	equ 0x0B
D_PPC_HI	equ 0x0C
D_CHREC		equ 0x0D
D_CHFLAG	equ 0x18
D_CHDRIV	equ 0x19
D_HDNUMB	equ 0x29
D_RECFLG	equ 0x43
D_RECNUM	equ 0x44
D_RECLEN	equ 0x45
D_FLAGX		equ 0x37
D_SUBPPC	equ 0x0D
