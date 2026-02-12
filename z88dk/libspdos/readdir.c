#include <fcntl.h>

int readdir(int dirhandle, void *buf) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     de      ; buf
    pop     hl      ; dirhandle
    push    hl
    push    de
    push    bc
    
    push    ix
    ld      a,l     ; directory handle in A
    ; VFS READDIR: A = directory handle, DE = buffer
    ; DE is already set up correctly
    call    READDIR
    pop     ix
    
    jr      c,error
    ld      hl,0    ; success
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

