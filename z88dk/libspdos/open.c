#include <fcntl.h>

int open(char *name, int flags, mode_t mode) __naked
{
#asm
    include "spectranet.asm"
    
    push    ix
    ld      ix,4
    add     ix,sp
    
    ; Stack: [ix][ret][name][flags][mode]
    ; Parameters: name at SP+4, flags at SP+6, mode at SP+8
    
    ; Get mode
    ld      c,(ix+0)
    ld      b,(ix+1)
    
    ; Get flags
    ld      e,(ix+2)
    ld      d,(ix+3)

    ; Get filename pointer
    ld      l,(ix+4)
    ld      h,(ix+5)
    
    ; VFS OPEN: HL=filename, DE=flags, BC=mode
    call    OPEN
    
    jr      c,error
    ld      h,0
    ld      l,a      ; return handle
    jr      end
    
error:
    ld      hl,-1
    
end:
    pop     ix
    ret
#endasm
}
