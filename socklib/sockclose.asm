; int __FASTCALL__ sockclose(int fd);
XLIB sockclose
LIB libsocket

XREF CLOSE
XREF HLCALL

.sockclose
	ld a, l		; file descriptor in lsb of hl
;	ld hl, CLOSE
;	call HLCALL
	ld hl, 0x3E03
	call 0x3FFA
	jr c, err_close
	ld hl, 0	; return code 0
	ret
.err_close
	ld hl, -1
	ret

