data	segment
   table db 3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,6fh,77h,7ch,39h,5eh,79h,71h
   buf1 db 5 dup(0)
   chu dw 10
   ad1 dw buf1
data ends
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE,DS:data
START:
    mov ax,data
    mov ds,ax
;   mov al,00110101b
;	out 36h,al
;	mov al,10011000b
;	out 56h,al
;	mov al,20
;	out 30h,al
;begin:	mov al,00001010b	;start adc0808 from pc5
;	out 56h,al
;trans:	in al,54h
;	test al,00100001b	;test EOC from pc4
;	jnz trans
;	in al,50h
;	xor ah,ah
    mov ax,123 
    mov di,ad1
	lea bx,table
deal:sub dx,dx	
    inc di
	div chu
	mov [di],dl
	cmp ax,0
	ja deal	
	sub di,ad1  ;prepare for disp 
	inc di
	mov cx,di
	lea di,buf1
	mov dx,11111110b
disp:mov al,[di]
	add al,al
	sub al,bl
	mov bl,0
	mov ah,[di+1]
	sub al,ah 
	aas 
	adc bl,0
;	xlat
	cmp dx,11110111b	;the fourth time
	jnz disp1
	and al,7fh	;add a point
disp1:  out 52h,al
	mov al,dl
	out 54h,al
;	call delay
	inc di
	shl dl,1
	loop disp
;	loop begin
delay:  mov al,00h
	out 36h,al
	in al,30h
        mov ah,al
delay1: in al,30h
	 cmp ah,al
	 jz delay1
	 ret	
CODE    ENDS
        END START