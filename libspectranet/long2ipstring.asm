; CALLER linkage for long2ipstring()
XLIB long2ipstring
LIB long2ipstring_callee
XREF ASMDISP_LONG2IPSTRING_CALLEE

; void long2ipstring(inet_addr_t *addr, char *str);
.long2ipstring
	pop bc		; return address
	pop de		; char *str
	pop hl		; inet_addr_t *addr
	push hl
	push de
	push bc
	jp long2ipstring_callee + ASMDISP_LONG2IPSTRING_CALLEE
