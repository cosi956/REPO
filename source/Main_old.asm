DOSSEG
		.MODEL	SMALL		; ?څ8086?????????Small model
		.8086				; ?څ????8086??????
.stack 100h
;macro definition
istart macro
	 push ax
	 push bx
	 push cx
	 push dx
	 push di
	 push si
	 sti
endm
ireturn macro
	mov al,00100000b
	out 90h,al	;OCW2???8259
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	iret
endm
;-----------------------------------
		.data
       time db 5 dup(0),1
       alm db 20 dup(0)
       num dw 0  ;??????????*2
       x dw 0	;?????????
       y dw 0	;???<x?????
       after db 18h,0h	;????????????????
       intnum dw int1,int2,int3		;3>1>2?????
       segcode db 3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,6fh
	       db 77h,7ch,39h,5eh,79h,71h,73h,76h,6eh,40h,00h
;----------------------------------
		.code						; Code segment definition
		.startup					; ????????????????
;------------------------------------------------------------------------
		in al,0h				; Simulation Patch for Proteus,
						; Please ignore the above code line.
;init 8259
	mov al,00010011b
	out 20h,al
	mov al,01110000b	;70h??????��?????
	out 22h,al
	mov al,00000101b	;?????????EOI,?????
	out 22h,al
	mov al,11110001b	;??????123��?��?
	out 22h,al
	mov si,offset intnum
	mov cx,3
	mov ax,0
	push es
	mov es,ax
	mov di,71h
	shl di,1
	shl di,1
stosnum:
	mov ax,[si]
	stosw
	mov ax,cs
	stosw
	add si,2
	loop stosnum
	pop es
	sti
;init 8253
	mov al,00110111b;???????	
	out 36h,al
	mov al,01110111b;ch1----????1??
	out 36h,al 
	mov al,10011001b;ch2---????????
	out 36h,al
;init 8255 								     
	mov al,10010000b                    
	out 56h,al
	mov al,00001001b;set pc4=1,?????8255 INTE=1,?????��?
	out 56h,al
;start count,wait for int	
	mov al,00h	;1000????????
	out 32h,al
	mov al,10h
	out 32h,al  	
;-------------------range all alarm
main:
	 mov cl,4
	 mov al,time[3]
	 shl al,cl
	 add al,time[2]
	 mov ah,time[1]
	 shl ah,cl
	 add ah,time[0]
	 mov cx,ax
range:
	 cmp di,num
	 je end3
	 mov ah,alm[di]
	 cmp ah,0ffh
	 jnz range1
	 add di,2
	 inc bx
	 jmp range
range1:
	 shl bx,1
	 mov al,alm[di+1]
	 xchg di,bx
	 stosw
	 cmp cx,ax
	 jb next
	 inc y
	 inc y
next:
	 cmp ax,dx	
	 jbe next1
	 xchg dx,ax	;AX???��?,???��
next1:
	 stosw
	 mov di,bx
	 add di,2
	 mov bx,0
	 jmp range
end1:
	 mov dx,num
	 cmp y,dx
	 jae end2
	 add al,cl	
	 daa
	 add ah,ch
	 daa
	 mov x,0	;??????
	 jmp end3
end2:
	 sub di,y
	 lodsw
	 sub al,cl
	 das
	 sbb ah,ch
	 das
	 mov x,di
end3:
	 mov after[1],al
	 mov after[0],ah
	 jmp main
;--------------------------customize yourself
int3 proc
	istart
chos:
	in al,50h
	jz waiting
	test al,10h
	jnz delete
	test al,20h
	jnz almjia
	test al,08h
	jnz cmpen
	cmp ento,0
	je udtime 
chg:
	test al,01h
	jz ud
	inc si
	cmp si,n	;???????��
	jz chos
	mov si,0
	jmp chos
cmpen:
	cmp n,5
	jz udtime1
	mov dx,3	;?????????????
	mov n,dx
	inc ento
	cmp ento,1
	jz en1
	cmp ento,3
	jz en3
en0:
	add di,2	;ento=2,change to next alm[di]
	call trans
	cmp di,num	;???num??????
	jb chos
	mov di,0
	jmp chos
delete:
	cmp ento,1
	jnz chos
	mov alm[di+1],0ffh	;???????????
	jmp chos
almjia:
	inc num
	inc num
	mov di,num
	jmp en2
en1:		;change  first alm
	mov di,0
en2:	
	lea si,tpchg
	call trans
	push di
	lea di,tpchg
	call show
	inc ento
	jmp chos    
en3: 
	dec ento
	mov cl,4
	mov al,tpchg[2]
	shl al,cl
	add al,tpchg[3]	
	mov alm[di+1],al
	mov ah,tpchg[0]
	shl ah,cl
	add ah,tpchg[1]
	mov alm[di],ah
	call left	;ah,al??????��???????10????BCD
	jmp en0
ud:			;+
	test al,04h
	jz ud1
	call over
	inc byte ptr[si]
	jmp chos 
ud1:			;-
	mov al,0
	cmp [si],al
	jz chos
	dec byte ptr[si]
	jmp chos
over:
	 mov bx,offset limit
	 mov ax,si
	 xlat
	 cmp [si],al
	 jb over1
	 mov al,0
	 mov [si],al
over1:	 ret
trans:		;?????BCD??????????
	mov cl,4
	mov al,alm[di+1];hour
	mov ah,al
	and al,0fh
	mov tpchg[1],al
	shl ah,cl
	and ah,0fh
	mov tpchg[0],ah
	mov al,alm[di];minute
	mov ah,al
	and al,0fh
	mov tpchg[3],al
	shl ah,cl
	and ah,0fh
	mov tpchg[2],ah
	push di
	add di,10	;???????????
	mov word ptr tpchg[4],di
	pop di
	ret
left:
	mov bx,x	;cmpare new alarm with after-alarm
	mov dh,alm[bx+1]
	mov dl,alm[bx]
	cmp dx,ax
	ja left1
	ret
left1:
	 xchg ax,dx
	 sub al,dl
	 das
	 sbb ah,dh
	 das
	 mov dh,after[0]
	 mov dl,after[1]
	 cmp dx,ax
	 ja left2
	 ret
left2:	 sub dl,al
	 das
	 sbb dh,ah
	 das
	 mov after[1],dl
	 mov after[0],dh
	 ret
;------------------------change present time
udtime:
	 lea si,time 
	 mov dx,5
	 mov n,dx
	 jmp chos
udtime1:
	 cli
	 dec ento		;ento=0??��	 
	 sti           ;??��????????????????,????waiting
waiting:
	push di
	 cmp n,5
	 jnz wait1
	 lea di,time
	 call show
	 jmp wait2
wait1:
	 lea di,tpchg
	 call show
wait2:
	 mov al,01000000b
	 out 36h,al
	 in al,32h
	 mov ah,al
	 in al,32h
	 cmp ah,0ah	;???????10ms
	 jbe waiting
	 in al,50h
	 jnz chos
	 ireturn
      ento db 0	;??????????ENTER
      n dw 0	;??????????��?????????
      tpchg db 4 dup(0)
      limit db 2,4,5,9,5,9	;??��???????????��
int3 endp
;-----------------------------normal second show
int1 proc 
	 istart
	 mov si,4
secmin:
	 mov al,time[si+1]
	 mov ah,time[si]
	 add ax,1
	 aaa
	 sub si,2
	 jz hour
	 cmp ax,60
	 jnz endhour
	 mov ax,0
	 mov time[si+1],al
	 mov time[si],ah
hour:
	 cmp ax,24
	 jnz hour1	;???��??????
	 xor ax,ax
	 mov time[0],ah
	 mov time[1],al
hour1:
	 mov al,after[0]
	 sub al,1
	 das
	 jnz endhour	;???????��??
	 mov al,after[1]
	 out 34h,al	;???2????????????,???4
endhour:
	 push di
	 lea di,time
	 ireturn
int1 endp
;----------------------------------;????
int2 proc
	istart
	push di
	lea di,time;??????????????????
	call show
	mov bx,num
	mov dh,alm[bx-2]
	mov dl,alm[bx-1]
	mov di,0
	mov al,00100000b
	out 90h,al	;OCW2????INT2	
;------------------------------------ring 1min
	mov al,00001010b	;pc4=1---gate0=1,???????
	out 54h,al
	mov si,0
	mov bx,offset dltime
	mov dl,time[3]
ring:
	mov ax,1000	;8253clk=1kHZ
	div freq[si]
	out 30h,al
	mov al,ah
	out 30h,al
	mov cx,bx	
dly:
	mov ax,1000h
	nop
	nop
	dec ax
	loop dly
	inc bx
        add si,2
	cmp si,6	;6��????
        jnz ring
	mov si,0
	mov dh,time[3]
	cmp dh,dl
	jz ring
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	iret
      freq dw 12,13,10,5,12,5
      dltime db 1,2,2,3,1,4 
int2 endp
show proc
	push cx
	push dx
	mov dl,11111110b	;ror????1��???
	mov cx,6
	mov al,0ffh
	out 52h,al
	mov al,10b
	out 54h,al
show1:
	mov al,dl
	out 52h,al
	mov al,00b	;close both
	out 54h,al
	mov al,0h
	out 52h,al
	mov al,01b
	out 54h,al	;pc1,pc0=01,choose 74hc573(1)
	lea bx,segcode
	mov al,[di]
	xlat
	test cl,01b
	jz show2
	add al,80h
show2:
	out 52h,al
	call delay
	mov al,0h
	out 52h,al
	mov al,10b
	out 54h,al
	inc di
	rol dl,1
	loop show1
	jmp endshow
delay:
	mov ax,10h
delay1:
	dec ax
	nop
	nop
	jnz delay1
	ret
endshow:
	pop dx
	pop cx
	pop di
show endp
END	