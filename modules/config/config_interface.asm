;The MIT License
;
;Copyright (c) 2010 Dylan Smith
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

CFG_COPYCONFIG	equ 0xFE01
CFG_FINDSECTION	equ 0xFE02
CFG_GETCFSTRING	equ 0xFE03
CFG_GETCFBYTE	equ 0xFE04
CFG_GETCFWORD	equ 0xFE05
CFG_ADDCFSTRING	equ 0xFE06
CFG_SETCFBYTE	equ 0xFE07
CFG_SETCFWORD	equ 0xFE08
CFG_CREATESECTION equ 0xFE09
CFG_COMMITCFG	equ 0xFE0A

CFG_CREATENEWCFG	equ 0xFEFF

