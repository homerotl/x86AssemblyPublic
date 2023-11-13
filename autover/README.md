# AUTOVER

I write this program to help me auto-increment the build number
and time stamp of my vintage x86 projects.

The program will look in the current directory for a file called 
'build.num', parse the number found in it, increment it and update
the file. Then it will write (or re-write) a file called 'version.inc',
which includes a constant with the format:

```
YYYYMMDD.<buildNum>
```

The way to include the automatic version on your code is add the line:

```
INCLUDE VERSION.INC
```

And then you can use the contant in anyway you want to display the
time stamp and build number of your code.

Example:

```
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
```