#include <fcntl.h>

int readbyte(int fd) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc      ; return address
    pop     af      ; fd
    push    af
    push    bc

    push    ix
    push    hl      ; Reserve space on stack for byte (fd value, will be overwritten)

    ld      hl,0
    add     hl,sp   ; HL points to buffer on stack
    ex      de,hl   ; DE = buffer
    ld      bc,1    ; Read 1 byte

    call    READ

    pop     hl      ; Get byte from stack (byte is in L)
    pop     ix      ; Restore IX
    
    ; check if BC > 0 (EOF with data) or BC == 0 (error)
    ld      a,b
    or      c       ; Check if BC is zero
    jr      z, error
    
    ; Byte value is in L register (from pop hl)
    ld      h,0
    and     a       ; Clear carry flag
    ret
    
error:
    ld      hl,-1
    scf     ; Set carry flag for error
    ret
#endasm
}

