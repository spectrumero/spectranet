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

; Strings (English)
.data
.globl STR_filetype
.globl STR_tap
.globl STR_data
.globl STR_basic
.globl STR_numarray
.globl STR_strarray
.globl STR_code
.globl STR_unknown
.globl STR_size
.globl STR_blksize
.globl STR_param1
.globl STR_param2
.globl STR_directory
.globl STR_bytes
.globl STR_headerless
STR_filetype:	defb	"File type: ",0
STR_tap:		defb	"TAP file",0
STR_data:	defb	"Data",0
STR_basic:	defb	"Program: ",0
STR_numarray:	defb	"Number array: ",0
STR_strarray:	defb	"String array: ",0
STR_code:	defb	"Bytes: ",0
STR_unknown:	defb	"Unknown: ",0
STR_size:	defb	"File size: ",0
STR_blksize:	defb	"Block size : ",0
STR_param1:	defb	"Paramater 1: ",0
STR_param2:	defb	"Parameter 2: ",0
STR_directory:	defb	"Directory: size ",0
STR_bytes:	defb	" bytes",0
STR_headerless:	defb	"Headerless block: ",0


