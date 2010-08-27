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

; This table maps return codes to one or more flags plus a byte that
; indicates what the response means.
RETURNCODES
	defw	c1XX	; 1xx codes
	defw	c2XX	; and so on.
	defw	c3XX
	defw	c4XX
	defw	c5XX
; the main table is made up of the last 2 digits of the return code
; then a flags byte then the code it maps to.
c1XX
	defb	"10", 0, REP_RESTART_MKR
	defb	"20", ERR, REP_READY_LATER
	defb	"25", 0, REP_XFER_STARTING
	defb	"50", 0, REP_OPENING
	defb	0
c2XX
	defb	"00", 0, REP_OK
	defb	"02", 0, REP_SUPERFLUOUS
	defb	"11", 0, REP_SYS_STATUS
	defb	"12", 0, REP_DIR_STATUS
	defb	"13", 0, REP_FILE_STATUS
	defb	"14", 0, REP_HELP_MSG
	defb	"15", 0, REP_SYS_TYPE
	defb	"20", 0, REP_RDY_FOR_NEWUSR
	defb	"21", 0, REP_CLOSING
	defb	"25", 0, REP_NOXFER
	defb	"26", 0, REP_CLOSING
	defb	"27", 0, REP_PASV
	defb	"30", 0, REP_USER_OK
	defb	"50", 0, REP_ACTION_OK
	defb	"57", 0, REP_PATH_CREATED
	defb	0
c3XX
	defb	"31", 0, REP_NEED_PASSWD
	defb	"32", 0, REP_NEED_LOGIN
	defb	"50", 0, REP_MOREINFO
	defb	0
c4XX
	defb	"21", ERR, E......
	defb	"25", ERR, E.....
	defb	"26", ERR, E.....
	defb	"50", ERR, E.....
	defb	"51", ERR, E,,,,,
	defb	"52", ERR, E.....
	defb	0
c5XX
	defb	"00", ERR, EINVAL
	defb	"01", ERR, EINVAL
	defb	"02", ERR, ENOSYS
	defb	"03", ERR, EINVAL
	defb	"04", ERR, ENOSYS
	defb	"30", ERR, EACCES
	defb	"32", ERR, EACCES
	defb	"50", ERR, ENOENT
	defb	"51", ERR, EINVAL
	defb	"52", ERR, ENOSPC
	defb	"53", ERR, EINVAL
	defb	0


