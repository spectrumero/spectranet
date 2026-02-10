#include <fcntl.h>

int close(int handle) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc      ; return address
    pop     hl      ; handle
    push    hl
    push    bc
    
    push    ix
    ld      a,l     ; handle in A
    call    VCLOSE
    pop     ix
    
    jr      c,error
    ld      hl,0    ; success
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

