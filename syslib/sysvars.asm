;The MIT License
;
;Copyright (c) 2024 Dylan Smith
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

; Defining these as defb/defw allows them to be used outside the Spectranet
; by using a linker script.

.section sysvars

.globl  v_column            ; Spectranet address
v_column:    defb 0          ; 0x3F00
.globl  v_row
v_row:       defw 0          ; 0x3F01
.globl  v_rowcount
v_rowcount:  defb 0          ; 0x3F03
.globl  v_pr_wkspc
v_pr_wkspc:  defb 0          ; 0x3F04
.globl  v_pr_pga
v_pr_pga:    defb 0          ; 0x3F05
.globl  v_pga
v_pga:       defb 0          ; 0x3F06
.globl  v_pgb
v_pgb:       defb 0          ; 0x3F07
.globl  v_utf8
v_utf8:      defb 0          ; 0x3F08

; FIXME when all sysvars are in here, remove
.section regsave
.globl  v_hlsave
v_hlsave:    defw 0

