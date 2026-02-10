#include <fcntl.h>

int closedir(int dirhandle) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     hl      ; dirhandle
    push    hl
    push    bc
    
    push    ix
    ld      a,l     ; directory handle in A
    ; VFS CLOSEDIR: A = directory handle
    call    CLOSEDIR
    pop     ix
    
    jr      c,error
    ld      hl,0
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

