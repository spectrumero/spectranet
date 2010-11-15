.data
.globl CHARSET
CHARSET:
char_space:
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0

char_pling:
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb 0
         defb %00100000
         defb 0

char_quote:
         defb %01010000
         defb %01010000
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0

char_octothorpe:
         defb 0
         defb %01010000
         defb %11111000
         defb %01010000
         defb %01010000
         defb %11111000
         defb %01010000
         defb 0

char_buck:
         defb %00100000
         defb %11111000
         defb %10100000
         defb %11111000
         defb %00101000
         defb %11111000
         defb %00100000
         defb 0

char_percent:
         defb %11001000
         defb %11001000
         defb %00010000
         defb %00100000
         defb %01000000
         defb %10011000
         defb %10011000
         defb 0

char_ampersand:
         defb %01110000
         defb %10001000
         defb %01010000
         defb %00100000
         defb %01010000
         defb %10001000
         defb %01110100
         defb 0

char_singlequote:
         defb %00010000
         defb %00100000
         defb %01000000
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0

char_obrace:
         defb %00100000
         defb %01000000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %01000000
         defb %00100000
         defb 0

char_cbrace:
         defb %00100000
         defb %00010000
         defb %00001000
         defb %00001000
         defb %00001000
         defb %00010000
         defb %00100000
         defb 0

char_asterisk:
         defb 0
         defb %01010000
         defb %00100000
         defb %11111000
         defb %00100000
         defb %01010000
         defb 0
         defb 0 

char_plus:
         defb 0
         defb %00100000
         defb %00100000
         defb %11111000
         defb %00100000
         defb %00100000
         defb 0
         defb 0

char_comma:
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb %00100000
         defb %00100000
         defb %01000000

char_minus:
         defb 0
         defb 0
         defb 0
         defb %11111000
         defb 0
         defb 0
         defb 0
         defb 0

char_period:
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb %00110000
         defb %00110000
         defb 0

char_slash:
         defb %00001000
         defb %00001000
         defb %00010000
         defb %00100000
         defb %01000000
         defb %10000000
         defb %10000000
         defb 0
        
char_zero:
         defb %01110000
         defb %10001000
         defb %10011000
         defb %10101000
         defb %11001000
         defb %10001000
         defb %01110000
         defb 0

char_one:
         defb %00100000
         defb %01100000
         defb %10100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %11111000
         defb 0

char_two:
         defb %01110000
         defb %10001000
         defb %00001000
         defb %00110000
         defb %01000000
         defb %10000000
         defb %11111000
         defb 0

char_three:
         defb %01110000
         defb %10001000
         defb %00001000
         defb %00110000
         defb %00001000
         defb %10001000
         defb %01110000
         defb 0

char_four:
         defb %00010000
         defb %00110000
         defb %01010000
         defb %10010000
         defb %11111000
         defb %00010000
         defb %00010000
         defb 0

char_five:
         defb %11111000
         defb %10000000
         defb %11110000
         defb %00001000
         defb %00001000
         defb %10001000
         defb %01110000
         defb 0

char_six:
         defb %00111000
         defb %01000000
         defb %10000000
         defb %11110000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_seven:
         defb %11111000
         defb %00001000
         defb %00001000
         defb %00010000
         defb %00010000
         defb %00100000
         defb %00100000
         defb 0

char_eight:
         defb %01110000
         defb %10001000
         defb %10001000
         defb %01110000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_nine:
         defb %01110000
         defb %10001000
         defb %10001000
         defb %01111000
         defb %00001000
         defb %00001000
         defb %01110000
         defb 0

char_colon:
         defb 0
         defb %00100000
         defb 0
         defb 0
         defb 0
         defb %00100000
         defb 0
         defb 0

char_semicolon:
         defb 0
         defb %00100000
         defb 0
         defb 0
         defb %00100000
         defb %00100000
         defb %01000000
         defb 0

char_lessthan:
         defb %00010000
         defb %00100000
         defb %01000000
         defb %10000000
         defb %01000000
         defb %00100000
         defb %00010000
         defb 0

char_equals:
         defb 0
         defb 0
         defb %11110000
         defb 0
         defb %11110000
         defb 0
         defb 0
         defb 0

char_gtthan:
         defb %10000000
         defb %01000000
         defb %00100000
         defb %00010000
         defb %00100000
         defb %01000000
         defb %10000000
         defb 0

char_quest:
         defb %01110000
         defb %10001000
         defb %00001000
         defb %00110000
         defb %00100000
         defb 0
         defb %00100000
         defb 0

char_at:
         defb %01110000
         defb %10001000
         defb %10111000
         defb %10101000
         defb %10010000
         defb %10000000
         defb %01111000
         defb 0

char_A:   defb %00100000
         defb %01010000
         defb %10001000
         defb %11111000
         defb %10001000
         defb %10001000
         defb %10001000
         defb 0

char_B:   defb %11110000
         defb %10001000
         defb %10001000
         defb %11110000
         defb %10001000
         defb %10001000
         defb %11110000
         defb 0

char_C:   defb %01110000
         defb %10001000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %10001000
         defb %01110000
         defb 0

char_D:
         defb %11100000
         defb %10010000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10010000
         defb %11100000
         defb 0

char_E:
         defb %11111000
         defb %10000000
         defb %10000000
         defb %11110000
         defb %10000000
         defb %10000000
         defb %11111000
         defb 0

char_F:
         defb %11111000
         defb %10000000
         defb %10000000
         defb %11110000
         defb %10000000
         defb %10000000
         defb %10000000
         defb 0

char_G:   defb %01110000
         defb %10001000
         defb %10000000
         defb %10000000
         defb %10011000
         defb %10001000
         defb %01110000
         defb 0

char_H:   defb %10001000
         defb %10001000
         defb %10001000
         defb %11111000
         defb %10001000
         defb %10001000
         defb %10001000
         defb 0

char_I:
         defb %01110000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_J:
         defb %00001000
         defb %00001000
         defb %00001000
         defb %00001000
         defb %00001000
         defb %10001000
         defb %01110000
         defb 0

char_K:
         defb %10001000
         defb %10010000
         defb %10100000
         defb %11000000
         defb %10100000
         defb %10010000
         defb %10001000
         defb 0

char_L:         
         defb %10000000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %11111000
         defb 0

char_M:
         defb %10001000
         defb %11011000
         defb %10101000
         defb %10101000
         defb %10001000
         defb %10001000
         defb %10001000
         defb 0

char_N:
         defb %10001000
         defb %10001000
         defb %11001000
         defb %10101000
         defb %10011000
         defb %10001000
         defb %10001000
         defb 0

char_O:
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_P:
         defb %11110000
         defb %10001000
         defb %10001000
         defb %11110000
         defb %10000000
         defb %10000000
         defb %10000000
         defb 0

char_Q:
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10101000
         defb %10010000
         defb %01101000
         defb 0

char_R:
         defb %11110000
         defb %10001000
         defb %10001000
         defb %11110000
         defb %10010000
         defb %10001000
         defb %10001000
         defb 0

char_S:
         defb %01110000
         defb %10001000
         defb %10000000
         defb %01110000
         defb %00001000
         defb %10001000
         defb %01110000
         defb 0

char_T:
         defb %11111000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb 0

char_U:
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_V:
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01010000
         defb %01010000
         defb %00100000
         defb %00100000
         defb 0

char_W:
         defb %10001000
         defb %10001000
         defb %10101000
         defb %10101000
         defb %10101000
         defb %11011000
         defb %10001000
         defb 0

char_X:
         defb %10001000
         defb %10001000
         defb %01010000
         defb %00100000
         defb %01010000
         defb %10001000
         defb %10001000
         defb 0

char_Y:
         defb %10001000
         defb %10001000
         defb %01010000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb 0

char_Z:
         defb %11111000
         defb %00001000
         defb %00010000
         defb %00100000
         defb %01000000
         defb %10000000
         defb %11111000
         defb 0

char_osqb:
         defb %01110000
         defb %01000000
         defb %01000000
         defb %01000000
         defb %01000000
         defb %01000000
         defb %01110000
         defb 0

char_backslash:
         defb %10000000
         defb %10000000
         defb %01000000
         defb %00100000
         defb %00010000
         defb %00001000
         defb %00001000
         defb 0

char_csqb:
         defb %01110000
         defb %00010000
         defb %00010000
         defb %00010000
         defb %00010000
         defb %00010000
         defb %01110000
         defb 0

char_power:
         defb %00100000
         defb %01010000
         defb %10001000
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0

char_underscore:
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb %11111100
         defb 0

char_quid:
         defb %00110000
         defb %01001000
         defb %01000000
         defb %11110000
         defb %01000000
         defb %01000000
         defb %11111000
         defb 0

char_a:
         defb 0
         defb 0
         defb %01110000
         defb %00001000
         defb %01111000
         defb %10001000
         defb %01111000
         defb 0

char_b:
         defb %10000000
         defb %10000000
         defb %11110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %11110000
         defb 0

char_c:         
         defb 0
         defb 0
         defb %01111000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %01111000
         defb 0

char_d:
         defb %00001000 
         defb %00001000
         defb %01111000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01111000
         defb 0

char_e:
         defb 0
         defb 0
         defb %01110000
         defb %10001000
         defb %11110000
         defb %10000000
         defb %01111000
         defb 0

char_f:
         defb 0
         defb %01110000
         defb %10000000
         defb %11100000
         defb %10000000
         defb %10000000
         defb %10000000
         defb 0

char_g:
         defb 0
         defb 0
         defb %01111000
         defb %10001000
         defb %10001000
         defb %01111000
         defb %00001000
         defb %01110000

char_h:
         defb %10000000
         defb %10000000
         defb %11110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb 0

char_i:
         defb %00100000
         defb 0
         defb %01100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_j:
         defb %00100000
         defb 0
         defb %01100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %11000000

char_k:
         defb 0
         defb %10000000
         defb %10010000
         defb %10100000
         defb %11000000
         defb %10100000
         defb %10010000
         defb 0

char_l:   defb %01100000 
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_m:
         defb 0
         defb 0
         defb %11010000
         defb %10101000
         defb %10101000
         defb %10101000
         defb %10001000
         defb 0

char_n:
         defb 0
         defb 0
         defb %11110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb 0

char_o:
         defb 0
         defb 0
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_p:
         defb 0
         defb 0
         defb %11110000
         defb %10001000
         defb %10001000
         defb %11110000
         defb %10000000
         defb %10000000

char_q:
         defb 0
         defb 0
         defb %01111000
         defb %10001000
         defb %10001000
         defb %01111000
         defb %00001000
         defb %00001100

char_r:
         defb 0
         defb 0
         defb %01110000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %10000000
         defb 0

char_s:
         defb 0
         defb 0
         defb %01111000
         defb %10000000
         defb %01110000
         defb %00001000
         defb %11110000
         defb 0

char_t:
         defb %01000000
         defb %01000000
         defb %11110000
         defb %01000000
         defb %01000000
         defb %01000000
         defb %00111000
         defb 0

char_u:
         defb 0
         defb 0
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_v:
         defb 0
         defb 0
         defb %10001000
         defb %10001000
         defb %01010000
         defb %01010000
         defb %00100000
         defb 0

char_w:
         defb 0
         defb 0
         defb %10101000
         defb %10101000
         defb %10101000
         defb %10101000
         defb %01010000
         defb 0

char_x:
         defb 0
         defb 0
         defb %10001000
         defb %01010000
         defb %00100000
         defb %01010000
         defb %10001000
         defb 0

char_y:
         defb 0
         defb 0
         defb %10001000
         defb %10001000
         defb %01111000
         defb %00001000
         defb %01110000
         defb 0

char_z:
         defb 0
         defb 0
         defb %11111000
         defb %00010000
         defb %00100000
         defb %01000000
         defb %11111000
         defb 0

char_ocbk:
         defb %00111000
         defb %01000000
         defb %01000000
         defb %10000000
         defb %01000000
         defb %01000000
         defb %00111000
         defb 0

char_ccbk:
         defb %11100000
         defb %00010000
         defb %00010000
         defb %00001000
         defb %00010000
         defb %00010000
         defb %11100000
         defb 0

char_tilde:
         defb %01010000
         defb %10100000
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0
         defb 0

char_copy:
         defb %01110000
         defb %10001000
         defb %11101000
         defb %11001000
         defb %11101000
         defb %10001000
         defb %01110000
         defb 0

char_block:
	 defb 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF

; Aquí, hay unos carácteres de UTF-8
; 0xC3 0x80 - 0xBF
char_A_grave:			; 0x80
	 defb %01000000
         defb %00100000
         defb %01110000
         defb %10001000
         defb %11111000
         defb %10001000
         defb %10001000
         defb 0

char_A_acute:			; 0x81
	 defb %00100000
         defb %01000000
         defb %01110000
         defb %10001000
         defb %11111000
         defb %10001000
         defb %10001000
         defb 0

char_A_circumflex:		; 0x82
	 defb %00100000
         defb %01010000
         defb %01110000
         defb %10001000
         defb %11111000
         defb %10001000
         defb %10001000
         defb 0

char_A_tilde:			; 0x83
	 defb %01010000
         defb %10100000
         defb %01110000
         defb %10001000
         defb %11111000
         defb %10001000
         defb %10001000
         defb 0

char_A_umlaut:			; 0x84
	 defb %01010000
         defb %00000000
         defb %01110000
         defb %10001000
         defb %11111000
         defb %10001000
         defb %10001000
         defb 0

char_ANGSTROM:			; 0x85
	 defb %00100000
         defb %01010000
         defb %01110000
         defb %10001000
         defb %11111000
         defb %10001000
         defb %10001000
         defb 0

char_AE:				; 0x86
         defb %00011100
         defb %00110000
         defb %01010000
         defb %11111100
	 defb %10010000
	 defb %10010000
	 defb %10011100
	 defb 0

char_C_cedilla:			; 0x87
	 defb %01110000
         defb %10001000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %10001000
         defb %01110000
         defb %01100000

char_E_grave:			; 0x88
	 defb %01000000
         defb %00100000
	 defb %11111000
	 defb %10000000
	 defb %11110000
	 defb %10000000
	 defb %11111000
	 defb 0

char_E_acute:			; 0x89
	 defb %00100000
         defb %01000000
	 defb %11111000
	 defb %10000000
	 defb %11110000
	 defb %10000000
	 defb %11111000
	 defb 0

char_E_circumflex:		; 0x8A
	 defb %00100000
         defb %01010000
	 defb %11111000
	 defb %10000000
	 defb %11110000
	 defb %10000000
	 defb %11111000
	 defb 0

char_E_umlaut:			; 0x8B
	 defb %01010000
         defb %00000000
	 defb %11111000
	 defb %10000000
	 defb %11110000
	 defb %10000000
	 defb %11111000
	 defb 0

char_I_grave:			; 0x8C
         defb %01000000
         defb %00100000
         defb %01110000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_I_acute:			; 0x8D
         defb %00100000
         defb %01000000
         defb %01110000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_I_circumflex:		; 0x8E
         defb %00100000
         defb %01010000
         defb %01110000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_I_umlaut:			; 0x8F
         defb %01010000
         defb %00000000
         defb %01110000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_D_barrada:			; 0x90
         defb %11100000
         defb %10010000
         defb %10001000
         defb %11101000
         defb %10001000
         defb %10010000
         defb %11100000
         defb 0

char_ENE:			; 0x91
         defb %00101000
         defb %01010000
         defb %10001000
         defb %11001000
         defb %10101000
         defb %10011000
         defb %10001000
         defb 0

char_O_grave:			; 0x92
	 defb %01000000
	 defb %00100000
	 defb %01110000
	 defb %10001000
	 defb %10001000
	 defb %10001000
	 defb %01110000
	 defb 0

char_O_acute:			; 0x93
	 defb %00100000
	 defb %01000000
	 defb %01110000
	 defb %10001000
	 defb %10001000
	 defb %10001000
	 defb %01110000
	 defb 0

char_O_circumflex:		; 0x94
	 defb %00100000
	 defb %01010000
	 defb %01110000
	 defb %10001000
	 defb %10001000
	 defb %10001000
	 defb %01110000
	 defb 0

char_O_tilde:			; 0x95
	 defb %01010000
	 defb %10100000
	 defb %01110000
	 defb %10001000
	 defb %10001000
	 defb %10001000
	 defb %01110000
	 defb 0

char_O_umlaut:			; 0x96
	 defb %01010000
	 defb %00000000
	 defb %01110000
	 defb %10001000
	 defb %10001000
	 defb %10001000
	 defb %01110000
	 defb 0

char_times:			; 0x97
	 defb 0
	 defb 0
	 defb %10001000
	 defb %01010000
	 defb %00100000
	 defb %01010000
	 defb %10001000
	 defb 0

char_O_slash:			; 0x98
         defb %01110000
         defb %10001000
         defb %10011000
         defb %10101000
         defb %11001000
         defb %10001000
         defb %01110000
         defb 0

char_U_grave:			; 0x99
         defb %01000000
         defb %00100000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_U_acute:			; 0x9A
         defb %00100000
         defb %01000000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_U_circumflex:		; 0x9B
         defb %00100000
         defb %01010000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_U_umlaut:			; 0x9C
         defb %01010000
         defb %00000000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_Y_acute:			; 0x9D
         defb %00010000
         defb %00100000
         defb %10001000
         defb %01010000
         defb %00100000
         defb %00100000
         defb %00100000
         defb 0

char_THORN:			; 0x9E
	 defb %10000000
	 defb %11110000
	 defb %10001000
	 defb %10001000
	 defb %10001000
	 defb %11110000
	 defb %10000000
	 defb 0

char_ESZETT:			; 0x9F
         defb %11110000
         defb %10001000
         defb %10001000
         defb %11110000
         defb %10001000
         defb %10001000
         defb %10110000
         defb %10000000

char_a_grave:			; 0xA0
         defb %01000000
         defb %00100000
         defb %01110000
         defb %00001000
         defb %01111000
         defb %10001000
         defb %01111000
         defb 0

char_a_acute:			; 0xA1
         defb %00100000
         defb %01000000
         defb %01110000
         defb %00001000
         defb %01111000
         defb %10001000
         defb %01111000
         defb 0

char_a_circumflex:		; 0xA2
         defb %00100000
         defb %01010000
         defb %01110000
         defb %00001000
         defb %01111000
         defb %10001000
         defb %01111000
         defb 0

char_a_tilde:			; 0xA3
         defb %01010000
         defb %10100000
         defb %01110000
         defb %00001000
         defb %01111000
         defb %10001000
         defb %01111000
         defb 0

char_a_umlaut:			; 0xA4
         defb %01010000
         defb %00000000
         defb %01110000
         defb %00001000
         defb %01111000
         defb %10001000
         defb %01111000
         defb 0

char_anillo:			; 0xA5
         defb %01110000
         defb %10001000
         defb %01110000
         defb %00001000
         defb %01111000
         defb %10001000
         defb %01111000
         defb 0

char_ae:				; 0xA6
	 defb 0
	 defb 0
	 defb %11110000
	 defb %00101000
	 defb %01111000
	 defb %10100000
	 defb %01011000
	 defb 0

char_c_cedilla:			; 0xA7
         defb 0
         defb 0
         defb %01111000
         defb %10000000
         defb %10000000
         defb %10000000
         defb %01111000
         defb %00100000

char_e_grave:			; 0xA8
         defb %01000000
         defb %00100000
         defb %01110000
         defb %10001000
         defb %11110000
         defb %10000000
         defb %01111000
         defb 0

char_e_acute:			; 0xA9
         defb %00100000
         defb %01000000
         defb %01110000
         defb %10001000
         defb %11110000
         defb %10000000
         defb %01111000
         defb 0

char_e_circumflex:		; 0xAA
         defb %00100000
         defb %01010000
         defb %01110000
         defb %10001000
         defb %11110000
         defb %10000000
         defb %01111000
         defb 0

char_e_umlaut:			; 0xAB
         defb %01010000
         defb %00000000
         defb %01110000
         defb %10001000
         defb %11110000
         defb %10000000
         defb %01111000
         defb 0

char_i_grave:			; 0xAC
         defb %01000000
         defb %00100000
         defb %01100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_i_acute:			; 0xAD
         defb %00100000
         defb %01000000
         defb %01100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_i_circumflex:		; 0xAE
         defb %00100000
         defb %01010000
         defb %01100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_i_umlaut:			; 0xAF
         defb %01010000
         defb %00000000
         defb %01100000
         defb %00100000
         defb %00100000
         defb %00100000
         defb %01110000
         defb 0

char_o_d_barrada:		; 0xB0
         defb %00000000
         defb %11100000
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_ene:			; 0xB1
         defb %01010000
         defb %10100000
         defb %11110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb 0

char_o_grave:			; 0xB2
         defb %01000000
         defb %00100000
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_o_acute:			; 0xB3
         defb %00100000
         defb %01000000
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_o_circumflex:		; 0xB4
         defb %00100000
         defb %01010000
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_o_tilde:			; 0xB5
         defb %01010000
         defb %10100000
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_o_umlaut:			; 0xB6
         defb %01010000
         defb %00000000
         defb %01110000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_divide:			; 0xB7
	 defb 0
	 defb %00100000
	 defb 0
	 defb %11111000
	 defb 0
	 defb %00100000
	 defb 0
	 defb 0

char_o_slash:			; 0xB8
         defb 0
         defb 0
         defb %01110000
         defb %10011000
         defb %10101000
         defb %11001000
         defb %01110000
         defb 0

char_u_grave:			; 0xB9
         defb %01000000
         defb %00100000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_u_acute:			; 0xBA
         defb %00010000
         defb %00100000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_u_circumflex:		; 0xBB
         defb %00100000
         defb %01010000
         defb %00000000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_u_umlaut:			; 0xBC
         defb %01010000
         defb %00000000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %10001000
         defb %01110000
         defb 0

char_y_acute:			; 0xBD
         defb %00010000
         defb %00100000
         defb %10001000
         defb %10001000
         defb %01111000
         defb %00001000
         defb %01110000
         defb 0

char_thorn:			; 0xBE
	 defb %00000000
	 defb %10000000
	 defb %11110000
	 defb %10001000
	 defb %10001000
	 defb %11110000
	 defb %10000000
	 defb 0

char_y_umlaut:			; 0xBF
         defb %01010000
         defb %00000000
         defb %10001000
         defb %10001000
         defb %01111000
         defb %00001000
         defb %01110000
         defb 0

; for 0xC2 characters, only a small subset is supported (by lookup table)
.globl CHARSET_C2
CHARSET_C2:
.globl CHARSET_C2_DIST
CHARSET_C2_DIST:	equ (CHARSET_C2-CHARSET)/8
char_euro:
         defb %01110000
         defb %10001000
         defb %10000000
         defb %11110000
         defb %10000000
         defb %10001000
         defb %01110000
         defb 0

.globl CHARSET_INVPLING
CHARSET_INVPLING:
.globl CHARSET_INVPLING_DIST
CHARSET_INVPLING_DIST:	equ (CHARSET_INVPLING-CHARSET)/8
char_inverted_pling:
	 defb %00100000
	 defb 0
	 defb %00100000
	 defb %00100000
	 defb %00100000
	 defb %00100000
	 defb %00100000
	 defb 0

char_cent:
         defb 0
         defb %00100000
         defb %01111000
         defb %10100000
         defb %10100000
         defb %10100000
         defb %01111000
         defb %00100000

.globl CHARSET_INVQUEST
CHARSET_INVQUEST:
.globl CHARSET_INVQUEST_DIST
CHARSET_INVQUEST_DIST:	equ (CHARSET_INVQUEST-CHARSET) / 8
char_inverted_quest:
         defb %00100000
         defb 0
         defb %00100000
         defb %01100000
         defb %10000000
         defb %10001000
         defb %01110000
         defb 0

