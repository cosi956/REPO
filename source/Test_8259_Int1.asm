code segment public 'code'
	assume cs:code,ds:data
		in al,0h			; Simulation Patch for Proteus,Please ignore the above code line.
start:
	mov ax,data
	mov ds,ax
	mov es,ax
	mov ax,0
	push es
	mov es,ax
	mov di,71h
	shl di,1
	shl di,1
	mov si,offset intnum
stosnum:
	mov ax,[si]
	stosw
	mov ax,cs
	stosw
	pop es
	sti
;init 8259
	mov al,00010011b
	out 20h,al
	mov al,01110000b	;70h?????????????
	out 22h,al
	mov al,00000101b	;?????????EOI,?????
	out 22h,al
	mov al,11111001b	;??????123??????
	out 22h,al
;init 8253
;	mov al,00110111b;???????	
;	out 36h,al
	mov al,01110111b;ch1----????1??
	out 36h,al 
	mov al,10011001b;ch2---????????
	out 36h,al
	mov al,00h
	out 32h,al
	mov al,10h
	out 32h,al
;------------------
main:mov al,00001010b
	out 90h,al
	in al,92h
    test al,010b
	jNz main1
	test al,100b
	jz main
	mov al,0ah
	out 34h,al
	jmp main
main1:
	mov al,01110001b
	out 36h,al
	jmp main
int1 proc
	push ax
	mov al,10h
	out 34h,al
	mov al,00010000b
	out 90h,al
	pop ax
	iret
int1 endp
code ends
data segment
	 intnum dw int1
	 time db 5 dup(0),1
	 after db 18h,0h	;????????????????
data ends
end