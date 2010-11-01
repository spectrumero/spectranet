;The MIT License
;
;Copyright (c) 2009 Dylan Smith
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

; Functions to load  .SNA0 (snapshot) files

; SNA file definitions
HEADER          equ 0x3000
SNA_I           equ HEADER
SNA_HLALT       equ HEADER+1
SNA_DEALT       equ HEADER+3
SNA_BCALT       equ HEADER+5
SNA_AFALT       equ HEADER+7
SNA_HL          equ HEADER+9
SNA_DE          equ HEADER+11
SNA_BC          equ HEADER+13
SNA_IY          equ HEADER+15
SNA_IX          equ HEADER+17
SNA_EIDI        equ HEADER+19
SNA_R           equ HEADER+20
SNA_AF          equ HEADER+21
SNA_SP          equ HEADER+23
SNA_IM          equ HEADER+25
SNA_BORDER      equ HEADER+26
HEADERSZ        equ 27
SNA_PC          equ HEADER+27           ; 128K  .SNA0 file - program counter
SNA_7FFD        equ HEADER+29           ; value of port 0x7FFD
SNA_TRDOS	equ HEADER+30

