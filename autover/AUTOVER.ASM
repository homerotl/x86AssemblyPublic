; AUTOVER.ASM
;
; A small program to automatically increase the version number
; in your code
; 
; USAGE:
; You can leave autover.exe in any directory you like, as long as it is
; in the DOS path.
; Author: Homero Trevino <homerotl@gmail.com>
.MODEL small

.STACK 100h

.DATA      

	; File names
	BuildFileName 		db 'build.num',0
	VersionAsmFileName 	db 'version.inc',0
	
	; Version.asm template
	VersionFileBodyHead db 'VERSION_LBL EQU ', 27h, 0

	VersionFileBodyTail db 27h,,0

	; Error and info messages
	ProgramInfoMsg			db 'Autover - Increase your build number - by Homero Trevino',13,10,'$'
	BuildFileExistsMsg		db '...build.num file found...',13,10,'$'
	BuildFileNotExistsMsg	db '...build.num file was not found...',13,10,'$'
	VersionFileProcMsg		db '...processing version.inc...',13,10,'$'
	SuccessMsg				db '...all processing completed successfully',13,10,'$'

	ErrorReadingBuildNum	db '...Error reading build.num...aborting program..',13,10,'$'
	ErrorDeletingBuildNum	db '...Error deleting build.num...aborting program..',13,10,'$'
	ErrorCreatingBuildNum	db '...Error creating build.num...aborting program..',13,10,'$'
	ErrorWritingBuildNum	db '...Error writing build.num...aborting program..',13,10,'$'
	ErrorClosingBuildNum	db '...Error closing build.num...aborting program..',13,10,'$'
	ErrorCreatingVersion	db '...Error creating version.inc...aborting program..',13,10,'$'
	ErrorWritingVersion		db '...Error writing version.inc...aborting program..',13,10,'$'
	ErrorClosingVersion		db '...Error closing version.inc...aborting program..',13,10,'$'

	; Other variables
	PUBLIC _FILE_Handle
	_FILE_Handle 			dw ?
	
	PUBLIC _MATH_Parsed_Integer
	_MATH_Parsed_Integer 	dw 0

	PUBLIC _FILE_WriteBuffer
	_FILE_WriteBuffer 		db 6 dup ('-')
	
	PUBLIC _IntToStringBuffer
	_IntToStringBuffer		db 6 dup ('-')

	PUBLIC _CharToStringBuffer
	_CharToStringBuffer		db '   ', 0

	DateString				db 'yyyymmdd',0
	Separator				db '.',0

	Year					dw 0
	Month					db 0
	Day						db 0

	BuildNumberString		db 6 dup (0)

	
.CODE
	.8086   ; Force 8086 code 
	JUMPS   ; Enable jump re-mapping

MAIN PROC
	mov ax,@DATA						; Align data segment
	mov ds,ax							; Set DS to the data segment

	mov ah,09h
	mov dx,OFFSET ProgramInfoMsg		; Print program information
	int 21h	
	
	lea dx,BuildFileName				; Check if file build.num exists
	call _FILE_OPEN_FILE				; in the current directory
	jc Open_Failed
	
	mov ah,09h							; Print that build.num was found
	mov dx,OFFSET BuildFileExistsMsg
	int 21h	

	mov cx,05h							; bytes to read
	call _FILE_READ_FROM_FILE			; Read from file
	jc Error_Reading_BuildNum
	
	call _MATH_PARSE_INTEGER
	; TODO: Add error handling logic for a parsing error
	
	mov ax,_MATH_Parsed_Integer			; Increase parsed integer
	inc ax
	; TODO Check for overflow

	call _FILE_CLOSE_FILE				; Close the current build.num file	
	jc Error_Closing_BuildNum			; jump if error
	
	lea dx,BuildFileName				; Delete previous build.num file
	call _FILE_DELETE_FILE
	jc Error_Deleting_BuildNum			; jump if error

Continue_BuildNum_Proc:
	
	call _STR_INT_TO_STRING				; Convert int (ax) to string

	lea si,_IntToStringBuffer
	lea di,BuildNumberString
	mov cx,6
	call _STR_BUFFER_COPY				; Copy the to-string buffer

	lea dx,BuildFileName
	call _FILE_CREATE_FILE				; create the new build num file
	jc Error_Creating_BuildNum			; jump if error
	
	lea dx,BuildNumberString			; point dx to the buffer
	call _FILE_WRITE_TO_FILE			; write to file
	jc Error_Writing_BuildNum			; jump if error
	
	call _FILE_CLOSE_FILE				; close the file
	jc Error_Closing_BuildNum			; jump if error
	
	jmp Handle_Version_Asm
	
Open_Failed:
	mov ah,09h							; Print that build.num was NOT found
	mov dx,OFFSET BuildFileNotExistsMsg
	int 21h	
	mov ax,1							; stat with build number 1
	jmp Continue_BuildNum_Proc
	
Handle_Version_Asm:
	
	mov ah,09h
	mov dx,OFFSET VersionFileProcMsg	; Print version processing message
	int 21h	

	lea dx,VersionAsmFileName			; Delete previous version.asm file
	call _FILE_DELETE_FILE				

	call _FILE_CREATE_FILE				; Create new version.asm file
	jc Error_Creating_Version			; jump if error
	
	lea dx,VersionFileBodyHead			; Write version.asm head
	call _FILE_WRITE_TO_FILE
	jc Error_Writing_Version			; jump if error

	call SET_DATE_STRING

	lea dx,DateString					; point dx to the date string
	call _FILE_WRITE_TO_FILE			; write to file
	jc Error_Writing_Version			; jump if error
	
	lea dx,Separator					; point dx to the separator string
	call _FILE_WRITE_TO_FILE			; write to file
	jc Error_Writing_Version			; jump if error
	
	lea dx,BuildNumberString			; point dx to the buffer
	call _FILE_WRITE_TO_FILE			; write to file
	jc Error_Writing_Version			; jump if error
	
	lea dx,VersionFileBodyTail			; Write version.asm tail
	call _FILE_WRITE_TO_FILE
	jc Error_Writing_Version			; jump if error
	
	call _FILE_CLOSE_FILE				; close file
	jc Error_Closing_Version			; jump if error
	
	mov ah,09h
	mov dx,OFFSET SuccessMsg			; Print success
	int 21h	
	jmp End_Program

	; Error conditions
	
Error_Reading_BuildNum:
	mov dx,OFFSET ErrorReadingBuildNum
	jmp Error_Final_Message
	
Error_Deleting_BuildNum:
	mov dx,OFFSET ErrorDeletingBuildNum
	jmp Error_Final_Message
	
Error_Creating_BuildNum:
	mov dx,OFFSET ErrorCreatingBuildNum
	jmp Error_Final_Message

Error_Writing_BuildNum:
	mov dx,OFFSET ErrorWritingBuildNum
	jmp Error_Final_Message

Error_Closing_BuildNum:
	mov dx,OFFSET ErrorClosingBuildNum
	jmp Error_Final_Message

Error_Creating_Version:
	mov dx,OFFSET ErrorCreatingVersion
	jmp Error_Final_Message
	
Error_Writing_Version:
	mov dx,OFFSET ErrorWritingVersion
	jmp Error_Final_Message

Error_Closing_Version:
	mov dx,OFFSET ErrorClosingVersion

Error_Final_Message:
	mov ah,09h
	int 21h
	jmp End_Program
	
End_Program:
	mov ah,4ch							; INT 21h, Function 4ch - End program	
	int 21h

MAIN ENDP

SET_DATE_STRING PROC

	call _TIME_GET_DATE					; Get date in registers
	mov Year,cx
	mov Month,dh
	mov Day,dl
	
	mov ax,Year
	call _STR_INT_TO_STRING				; convert year to string

	lea di,DateString					; destination
	lea si,_IntToStringBuffer			; source

	mov cx,4
Copy_Year_Loop:							; copy all 4 digits
	mov al,[si]
	mov [di],al	
	inc si
	inc di
	loop Copy_Year_Loop
	
	mov ah,Month						
	call _STR_CHAR_TO_STRING			; convert month to string
	
	lea di,DateString
	add di,4
	
	lea si,_CharToStringBuffer			; source
	cmp byte ptr [si+1],0				; check if we have 1 or two digits
	je Month_One_Digit					
	
	; Two digits
	mov al,[si]
	mov [di],al
	inc si
	inc di
	mov al,[si]
	mov [di],al
	inc di
	jmp Continue_With_Day
	
Month_One_Digit:
	mov byte ptr [di],'0'
	inc di
	mov al,[si]
	mov [di],al	
	inc di
	
Continue_With_Day:

	mov ah,Day
	call _STR_CHAR_TO_STRING			; convert day to string

	lea di,DateString
	add di,6

	lea si,_CharToStringBuffer			; source
	cmp byte ptr [si+1],0				; check if we have 1 or two digits
	je Day_One_Digit
	
	; Two digits
	mov al,[si]
	mov [di],al
	inc si
	inc di
	mov al,[si]
	mov [di],al
	
	jmp Finish_Date_String
	
Day_One_Digit:
	mov byte ptr [di],'0'
	inc di
	mov al,[si]
	mov [di],al	
	
Finish_Date_String:

	ret
SET_DATE_STRING ENDP

;----
; _FILE_OPEN_FILE
; Open existing file
; Inputs: ds:dx points to the file name (null terminated string)
; Output: cf clear if successful. If successful _FILE_Handle has the open file handle
; Destroys: None
;----
PUBLIC _FILE_OPEN_FILE
_FILE_OPEN_FILE PROC
	push ax					; Save used registers
	
	mov ah,3dh				; INT 21h, Function 3dh Open existing file
	mov al,00
	int 21h

	jc F_OF_No_Success
	mov _FILE_Handle,ax
	
F_OF_No_Success:
	pop ax
	ret
_FILE_OPEN_FILE ENDP

;----
; _FILE_CLOSE_FILE
; Close a file using its handle
; Inputs: _FILE_Handle has the file handle
; Output: cf clear if successful.
; Destroys: None
;----
PUBLIC _FILE_CLOSE_FILE
_FILE_CLOSE_FILE PROC
	push ax						; Save used registers
	push bx
	
	mov ah,3eh					; INT 21h, Function 3eh Open existing file
	int 21h

	pop bx
	pop ax
	ret
_FILE_CLOSE_FILE ENDP

;----
; _FILE_CREATE_FILE
; Create a file with the given name
; Inputs: ds:dx points to the file name (null terminated string)
; Output: cf clear if successful. If successful _FILE_Handle has the open file handle
; Destroys: None
;----
PUBLIC _FILE_CREATE_FILE
_FILE_CREATE_FILE PROC
	push ax						; Save used registers
	push cx
	
	mov ah,3ch					; INT 21h, Function 3ch Create file
	mov cx,0					; Default flags
	int 21h

	jc F_CF_No_Success
	mov _FILE_Handle,ax
	
F_CF_No_Success:
	pop cx
	pop ax
	ret
_FILE_CREATE_FILE ENDP

;----
; _FILE_WRITE_TO_FILE
; Write a buffer to a file
; Inputs: 
;  - _FILE_Handle points to an file handle for an open file for writing.
;  - dx points to a null-terminated buffer to write
; Output: cf clear if successful
; Destroys: None
;----
PUBLIC _FILE_WRITE_TO_FILE
_FILE_WRITE_TO_FILE PROC
	push ax						; Save used registers
	push bx
	push cx

	; Count buffer bytes to write
	xor cx,cx					; cx=0
	mov si,dx
F_WTW_CCont:
	cmp byte ptr [si],0
	je F_WTW_CFE
	inc cx
	inc si
	jmp F_WTW_CCont

F_WTW_CFE:
	; cx has the number of bytes to write
	mov bx, _FILE_Handle		; Setup file handle 
	mov ah,40h					; INT 21h, Function 40h Write to file
	int 21h

	pop cx
	pop bx
	pop ax
	ret
_FILE_WRITE_TO_FILE ENDP

;----
; _FILE_READ_FROM_FILE
; Read from a file and into a buffer
; Inputs: 
;  - _FILE_Handle points to an file handle for the file to read from
;  - _FILE_WriteBuffer points to buffer to receive the bytes read
;  - cx has the number of bytes to read
; Output: cf clear if successful
; Destroys: None
;----
PUBLIC _FILE_READ_FROM_FILE
_FILE_READ_FROM_FILE PROC
	push ax
	push bx
	push cx
	push dx
	push di
	
	mov bx,	_FILE_Handle		; setup file handle
	lea dx, _FILE_WriteBuffer	; setup buffer
	mov ah,3fh					; INT 21h, Function 3fh read from file
	int 21h
	
	add dx,ax					; Increase index to add null
	mov di,dx
	mov byte ptr[di],0			; then add null
	
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
_FILE_READ_FROM_FILE ENDP

;----
; _FILE_DELETE_FILE
; Delete a file. The name is a null-terminated string in dx
; Inputs: ds:dx - null terminated string with the name of the file
; Output: cf clear if successful
; Destroys: None
;----
PUBLIC _FILE_DELETE_FILE
_FILE_DELETE_FILE PROC
	push ax
	
	mov ah,41h
	int 21h
	
	pop ax
	ret
_FILE_DELETE_FILE ENDP

;----
; _MATH_PARSE_INTEGER
; Parse a number represented by a null-terminated string
; Limited to unsigned number from 0 to 65534 (16 bits)
; Inputs: 
;  - _FILE_WriteBuffer is a buffer containing a null terminated string
; Output: _MATH_Parsed_Integer has the parsed number or 65534 (ffffh) if there was an error
; Destroys: None
;----
PUBLIC _MATH_PARSE_INTEGER
_MATH_PARSE_INTEGER PROC

	push ax
	push bx
	push cx
	push dx	
	push di
	push si
	
	xor cx,cx					; start accumulator on 0
	mov bx,1					; Initial position multiplier

	lea di, _FILE_WriteBuffer
	lea si, _FILE_WriteBuffer
	
M_PI_Continue_Look_For_End:
	cmp byte ptr[di],0
	je M_PI_Continue_Parse
	inc di
	jmp M_PI_Continue_Look_For_End
	
M_PI_Continue_Parse:

	cmp di,si
	je M_PI_Done
	
	dec di						; Move index one position back	
	mov ah,0
	mov al,[di]
	sub al,30h					; Make the ascii a char number
	mul bx						; multiply by the position multiplier dx:ax=ax*bx
	add cx,ax					; we accumulate on cx	
	mov ax,bx					; we need to update the multipler
	mov bx,0ah					;
	mul bx						; dx:ax=ax*bx
	mov bx,ax
	jmp M_PI_Continue_Parse		; continue to the next digit
	
M_PI_Done:
	mov _MATH_Parsed_Integer,cx ; copy the end result
	
	pop si
	pop di	
	pop dx
	pop cx
	pop bx
	pop ax
	
	ret
_MATH_PARSE_INTEGER ENDP

;----
; _STR_INT_TO_STRING 
; Converts the value in ah to a decimal string. Only 8-bit unsigned int.
; Inputs:
; 	- ax = the value to conver to decimal 
; Output: 
;	- _IntToStringBuffer contains the decimal string.
; Destroys: None
;----
PUBLIC _STR_INT_TO_STRING
_STR_INT_TO_STRING PROC NEAR	; Assuming the value we want to convert is in ah

	lea di,_IntToStringBuffer	; Point di to the buffer where we are going to write number		

	push ax						; we are going to use these registers, so save them
	push bx	
	push dx
	
	mov bl,20h					; Reset buffer with blank space char (20h)
	mov [di],bl
	mov [di+1],bl
	mov [di+2],bl
	mov [di+3],bl
	mov [di+4],bl

	add di,4					; start from the back, move index to position 4
	
	mov bx,000ah				; prep to divide by 10 (0ah)

STR_ITS_Loop:
	xor dx,dx
	div bx						; We divide AX/BX. AX has the quotient and DX has the reminder
	add dl,30h					; Make ah ASCII
	mov [di],dl					; Copy the ASCII value to the buffer
	dec di						; increment the index for the buffer
	cmp ax,0					; if the quotient is 0, we are done				
	je STR_ITS_Trim				;
	jmp STR_ITS_Loop			; repeat
	
STR_ITS_Trim:
	lea di,_IntToStringBuffer
	cmp BYTE PTR [di],20h
	jne STR_ITS_Done
	
	mov bl,[di+1]
	mov [di],bl
	mov bl,[di+2]
	mov [di+1],bl
	mov bl,[di+3]
	mov [di+2],bl
	mov bl,[di+4]
	mov [di+3],bl
	mov BYTE PTR [di+4],0
	
	jmp STR_ITS_Trim

STR_ITS_Done:
	pop dx
	pop bx						; Restore registers
	pop ax						

	ret
_STR_INT_TO_STRING ENDP

;----
; _STR_CHAR_TO_STRING 
; Converts the value in ah to a decimal string. Only 8-bit unsigned int.
; Inputs:
; 	- ah = the value to conver to decimal 
; Output: 
;	- NumToAsciiB contains the decimal string.
; Destroys: None
;----
PUBLIC _STR_CHAR_TO_STRING
_STR_CHAR_TO_STRING PROC NEAR	; Assuming the value we want to convert is in ah

	lea di,_CharToStringBuffer	; Point di to the buffer where we are going to write number		

	push ax						; we are going to use these registers, so save them
	push bx
	
	mov bl,20h					; Reset buffer with blank space char (20h)
	mov [di],bl
	mov [di+1],bl
	mov [di+2],bl

	add di,2					; start from the back, move index to position 2
	
	mov bl,0ah					; prep to divide by 10 (0ah)
	mov al,ah					; Prep AX

STR_CTS_Loop:
	mov ah,0					; Prep AX
	div bl						; We divide ax/bl. al has the quotient and ah has the reminder
	add ah,30h					; Make ah ASCII
	mov [di],ah					; Copy the ASCII value to the buffer
	dec di						; increment the index for the buffer
	cmp al,0					; if the quotient is 0, we are done				
	je STR_CTS_Trim
	jmp STR_CTS_Loop			; repeat
	
STR_CTS_Trim:

	lea di,_CharToStringBuffer
	cmp BYTE PTR [di],20h
	jne STR_CTS_Done

	mov bl,[di+1]
	mov [di],bl
	mov bl,[di+2]
	mov [di+1],bl
	mov BYTE PTR [di+2],0
	jmp STR_CTS_Trim

STR_CTS_Done:
	pop bx						; Restore registers
	pop ax						

	ret
_STR_CHAR_TO_STRING ENDP

;----
; _TIME_GET_DATE 
; Get system date
; Inputs: none
; Output: 
;    - cx = year (1980-2099)
;    - dh = month 
;    - dl = day
;    - al = day of the week (00h = Sunday)
; Destroys: ax,cx,dx
;----
PUBLIC _TIME_GET_DATE
_TIME_GET_DATE PROC
	mov ah,2ah					; Int 21h Function 2ah - Get system date 
	int 21h	
	ret
_TIME_GET_DATE ENDP

;----
; _STR_BUFFER_COPY 
; Copy from the buffer pointed by si to di a number of bytes specified by cx
; Inputs:
; 	- cx - number of bytes to copy
;   - si - source index
;   - di - destination index
; Output: 
; Destroys: None
;----
PUBLIC _STR_BUFFER_COPY
_STR_BUFFER_COPY PROC
	push ax

S_BC_Continue:

	mov ah,[si]
	mov [di],ah
	inc si
	inc di
	loop S_BC_Continue
	
	pop ax
	
	ret
_STR_BUFFER_COPY ENDP

END