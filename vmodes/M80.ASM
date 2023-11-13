; M80.ASM
;
; Change mode to 80x25 columns
; Author: Homero Trevino <homerotl@gmail.com>
.MODEL small

.STACK 100h

.DATA      

.CODE
	.8086   ; Force 8086 code 
	JUMPS   ; Enable jump re-mapping
	
MAIN PROC
	
	mov ah,00h	; INT 10h, Function 00h - Set video mode
	mov al,03h	; Set mode to 80x25x16
	int 10h

	mov ah,4ch	; INT 21h, Function 4ch - End program	
	int 21h	
	
MAIN ENDP

END