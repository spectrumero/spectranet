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

STR_choose	defb "\n\nOpciones de configuración:\n",0
STR_dhcp	defb "Usar/no usar DHCP",0
STR_ipaddr	defb "Cambiar la dirección de IP",0
STR_netmask	defb "Cambiar la máscara de subred",0
STR_gateway	defb "Cambiar la puerta de enlace",0
STR_hostname	defb "Cambiar el nombre del host",0
STR_pridns	defb "Cambiar el DNS primario",0
STR_secdns	defb "Cambiar el DNS secundario",0
STR_hwaddr	defb "Cambiar la dirección del hardware",0
STR_save	defb "Guardar los cambios y salir",0
STR_cancel	defb "Salir sin guardar",0

STR_currset	defb "Configuración actual\n====================\n",0
STR_usedhcp	defb "Usar DHCP             : ",0
STR_currip	defb "Dirección             : ",0
STR_currmask	defb "Máscara de subred     : ",0
STR_currgw	defb "Puerta de enlace      : ",0
STR_currhwaddr	defb "Dirección del hardware: ",0
STR_currhost	defb "Nombre del host       : ",0
STR_currpridns	defb "DNS primario          : ",0
STR_currsecdns	defb "DNS secundario        : ",0
STR_no		defb "No\n",0
STR_yes		defb "Sí\n",0
STR_bydhcp	defb "DHCP",0
STR_unset	defb "[No establecido]",0

STR_abort	defb "Dejar linea en blanco para abortar",0
STR_invalidip	defb "\nLa dirección era inválida\n",0
STR_dhcpquestion defb "\n¿Usar DHCP? (S/N): ",0
STR_askip	defb "\nDirección de IP: ",0
STR_asknetmask	defb "\nMáscara de subred: ",0
STR_askgw	defb "\nPuerta de enlace: ",0
STR_askhw	defb "\nDirección del hardware: ",0
STR_askhostname	defb "\nNombre del host: ",0
STR_askpridns	defb "\nDNS primario: ",0
STR_asksecdns	defb "\nDNS secundario: ",0

STR_saving	defb "\nGuardando...",0
STR_done	defb "Configuración completa\n",0
STR_erasebork	defb "Fallo al borrar\n",0
STR_writebork	defb "Fallo al escribir\n",0

