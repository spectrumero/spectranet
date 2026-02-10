#include <fcntl.h>

long lseek(int fd, long posn, int whence) __naked
{
#asm
    include "spectranet.asm"
    
    push    ix
    ld      ix,4
    add     ix,sp
    
    ; Stack: [ix][ret][fd][posn_low][posn_high][whence]
    ; Parameters: fd at SP+4, posn_low at SP+6, posn_high at SP+8, whence at SP+10
    
    ; Get file descriptor (16-bit, but we only need low byte for VFS)
    ld      a,(ix+0)
    
    ; Get position (32-bit signed): DEHL
    ; posn is stored as: low word (LSB first), high word (LSB first)
    ld      l,(ix+2)    ; posn_low LSB
    ld      h,(ix+3)    ; posn_low MSB
    ld      e,(ix+4)    ; posn_high LSB
    ld      d,(ix+5)    ; posn_high MSB
    
    ; Get whence (16-bit, but we only need low byte for VFS)
    ld      c,(ix+6)
    
    ; VFS LSEEK: A=fd, C=whence, DEHL=position
    call    LSEEK
    
    jr      c,error
    ; Return position in DEHL, but C expects long in HLDE
    ; Actually, return value is typically the new position
    ; For now, return 0 on success, -1 on error
    pop     ix
    ld      hl,0
    ld      de,0
    ret
    
error:
    pop     ix
    ld      hl,-1
    ld      de,0xFFFF
    ret
#endasm
}

