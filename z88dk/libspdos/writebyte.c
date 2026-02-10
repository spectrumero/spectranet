#include <fcntl.h>

int writebyte(int handle, int c) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc      ; return address
    pop     hl      ; c (byte to write)
    pop     de      ; handle
    push    de
    push    hl
    push    bc
    
    push    ix
    ld      a,e     ; handle in A
    ; Use stack for single byte buffer
    ld      hl,2
    add     hl,sp   ; HL points to c on stack
    ld      bc,1    ; Write 1 byte
    call    WRITE
    pop     ix
    
    jr      c,error
    ; BC contains bytes written (should be 1)
    ld      h,b
    ld      l,c     ; Return bytes written
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

