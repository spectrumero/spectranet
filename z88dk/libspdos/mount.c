#include <fcntl.h>

int mount(int mount_point, char* password, char* user_id, char* path, char* hostname, char *protocol) __naked
{
#asm
    include "spectranet.asm"
    
    push    ix
    ld      ix,4
    add     ix,sp
    
    ; Parameters are pushed right-to-left, so rightmost is at lowest address:
    ; protocol at (ix+0) - rightmost parameter, pushed first
    ; hostname at (ix+2)
    ; path at (ix+4)
    ; user_id at (ix+6)
    ; password at (ix+8)
    ; mount_point at (ix+10) - leftmost parameter, pushed last
    
    ; Get mount_point (leftmost parameter, at highest offset)
    ld      a,(ix+10)
    
    ; IX already points to protocol (ix+0), which matches the structure layout:
    ; byte 0,1: protocol pointer (ix+0)
    ; byte 2,3: hostname pointer (ix+2)
    ; byte 4,5: path pointer (ix+4)
    ; byte 6,7: user_id pointer (ix+6)
    ; byte 8,9: password pointer (ix+8)
    
    ; Call VFS MOUNT: IX=structure, A=mount_point
    call    MOUNT
    
    ; Check return flags
    ; On success: Z reset, C reset
    ; Protocol not recognized: Z set, C reset
    ; Mount failed: C set
    jr      c,error
    jr      z,error
    
    pop     ix
    ld      hl,0
    ret
    
error:
    pop     ix
    ld      hl,-1
    ret
#endasm
}

int setmountpoint(int mount_point) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc
    pop     hl      ; mount_point
    push    hl
    push    bc
    
    push    ix
    ; SETMOUNTPOINT: A = mount_point (0 to 3)
    ld      a,l
    call    SETMOUNTPOINT
    pop     ix
    
    ; Returns with carry set on error (mount_point > 3)
    jr      c,setmount_error
    ld      hl,0
    ret
    
setmount_error:
    ld      hl,-1
    ret
#endasm
}

int getmountpoint(void) __naked
{
#asm
    push    ix
    ; Read from system variable v_vfs_curmount at 0x3F6F
    ld      hl,0x3F6F
    ld      a,(hl)
    pop     ix
    
    ; Return mount point (0-3) in HL
    ld      h,0
    ld      l,a
    ret
#endasm
}
