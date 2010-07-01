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

; The FTP filesystem system variables

v_ftp_servaddr		equ 0x1000	; 4 byte address of the server
v_curmountpt		equ 0x1004	; mount point number
v_ftp_status		equ 0x1005	; status flags
v_controlsock		equ 0x1006	; control connection socket
v_datasock		equ 0x1007	; data connection socket
v_ftp_user		equ 0x1008	; username string
v_ftp_passwd		equ 0x1028	; password string
v_ftp_dataport		equ 0x1048	; Data connection port
v_ftp_dataaddr		equ 0x104A	; Data connection address
v_cwd			equ 0x1100	; current working directory

