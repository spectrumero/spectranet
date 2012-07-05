/*
;The MIT License
;
;Copyright (c) 2011 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.
*/

#include "matchmake.h"

/* This is in asm because no one's written a library to do this
	yet! It just does a little file IO to see if we have a server
	pre-set.	*/

#define PAGEIN	0x3FF9
#define	PAGEOUT	0x007C

#define OPEN	0x3EB1
#define READ	0x3EC9
#define	CLOSE	0x3ED2
#define O_RDONLY	0x0001

void __FASTCALL__ getDefaultServer(char *buf) {
#asm
	call PAGEIN
	push hl
	ld hl, _serverfile
	ld de, O_RDONLY
	ld bc, 0x00
	call OPEN
	jr c, none
	pop de			; buffer to fill
	push de
	ld bc, 0x10	; max 16 bytes
	push af
	call READ
	jr c, closenone
	pop af
	call CLOSE
.fixstring
	pop hl
	ld b, 0x10
.fixloop
	ld a, (hl)
	cp 0x20
	jr nc, nochange
	ld (hl), 0
.nochange
	inc hl
	djnz fixloop
	
	jr done

.closenone
	pop af
	call CLOSE
.none
	pop hl
	ld (hl), 0		; ensure we have an empty string
	
.done
	call PAGEOUT
#endasm
}

#asm
._serverfile	defb 's','e','r','v','e','r','.','i','p',0
#endasm

