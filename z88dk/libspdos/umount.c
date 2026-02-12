#include <fcntl.h>

int umount(int mount_point) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     hl      ; mount_point
    push    hl
    push    bc
    
    push    ix
    ; VFS UMOUNT: A = mount_point (0 to 3)
    ld      a,l
    call    UMOUNT
    pop     ix
    
    ; UMOUNT returns with carry set on error
    jr      c,error
    ld      hl,0
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}
