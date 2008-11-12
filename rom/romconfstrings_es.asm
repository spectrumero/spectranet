;The MIT License
;
;Copyright (c) 2008 Dylan Smith
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
;
; Programa para configuración de ROM - Español

STR_installed	defb "Configuración actual\n====================\n\n",0
STR_datarom	defb "-- datos --\n",0

STR_menutitle	defb "\n\nMenu de configuración ROM\n=========================\n",0
STR_addmodule	defb "Añadir un módulo de ROM nuevo",0
STR_repmodule	defb "Reemplazar un módulo",0
STR_remmodule	defb "Borrar un módulo",0
STR_exit	defb "Salir",0

STR_send	defb "Escuchando en ",0
STR_port	defb " puerto 2000\n",0
STR_xtoexit	defb "\nPulsar 'x' para salir.\n",0
STR_borked	defb "\nLa operación falló con rc=",0
STR_est		defb "Conexión establecida\n",0
STR_len		defb "Tamaño: ",0
STR_noroom	defb "No hay ningún espacio en la memoria flash\n",0
STR_writingmod	defb "\nEscribiendo el módulo en página ",0

STR_entermod	defb "El número hex del módulo a reemplazar:",0
STR_delrom	defb "El número hex del módulo a borrar:",0
STR_notvalid	defb "El número del módulo era equivocado.\nPor favor, rehacerlo: ",0
STR_erasebork	defb "Fallo al borrar\n",0
STR_writebork	defb "Fallo al escribir\n",0
STR_defragment	defb "Desfragmentendo...\n",0
STR_erasing	defb "\nBorrando...\n",0
STR_eraseok	defb "Borrar completo.\n",0

