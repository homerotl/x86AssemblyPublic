.MODEL small
	INCLUDE VERSION.INC
.STACK 100h
.DATA
	HelloMsg db 'My Program - version ',VERSION_LBL,'$'	
.CODE
MAIN PROC
	mov ax,@DATA
	mov ds,ax

	mov ah,09h
	mov dx,OFFSET HelloMsg
	int 21h	

	mov ah,4ch	
	int 21h	
MAIN ENDP

END