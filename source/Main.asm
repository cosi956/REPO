DOSSEG
		.MODEL	SMALL		; 设定8086汇编程序使用Small model
		.8086				; 设定采用8086汇编指令集
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
	out 20h,al	;OCW2终止8259
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
        time db 1,2,1,7,0,0
        alm db 01h,10h,20h,13h,00h,00h,16 dup(0)
	list dw 1,2,4,20 dup(0)
	x dw 0	;当前闹钟位置---(编号-1)*2
	after dw 1800h	;下一闹钟还要多长时间响
	flag db 0
	tpchg db 6 dup(0)
	limit db 2,3,5,9,5,9	;每一位的限制调整大小
	key db 01b,01b,100b,100b,01b,10b,10b,10b,0000b
	intnum dw int3;3>1>2优先级
	freq dw 12,13,10,5,12,5
	dltime db 1,2,2,3,1,4 
	segcode db 0c0h,0f9h,0a4h,0b0h,099h,092h,82h,0f8h,80h,90h
;-----------------------------------------------------
.code						; Code segment definition
.startup					; 定义汇编程序执行入口点
;-----------------------------------------------------
	in al,0h				; Simulation Patch for Proteus,
	mov ax,ds				; Please ignore the above code line.
	mov es,ax
;init 8253
	mov al,00110111b;音乐发声	
	out 36h,al
	mov al,01110111b;ch1----产生1秒
	out 36h,al 
	mov al,10011001b;ch2---闹钟倒计时
	out 36h,al
;init 8255 								     
	mov al,10010000b   ;A=1,B,C=0                 
	out 56h,al
	mov al,00001001b;set pc4=1,为了保证8255 INTE=1,允许中断
	out 56h,al
;start count,wait for int	
	mov al,00h	;1000的表示方法
	out 32h,al
	mov al,10h
	out 32h,al  
;init 8259
	mov al,00010011b
	out 20h,al
	mov al,01110000b	;70h开始的中断向量
	out 22h,al
	mov al,00000101b	;非自动结束EOI,非缓冲
	out 22h,al
	mov al,11110001b	;不屏蔽123位中断
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
;-------------------range all alarm
main:
	lea di,alm
	mov bx,0
	mov dx,after
	 mov cx,4	;当前时间-CX
	 mov al,time[2]
	 shl al,cl
	 add al,time[3]
	 mov ah,time[0]
	 shl ah,cl
	 add ah,time[1]
	 mov cx,ax
	 cmp cx,0
	jnz range
	inc cx
range:		;根据BX选择sI
	mov si,list[bx]	;先在AX,CX中比较
	cmp si,0
	jz end0
	dec si 
	shl si,1
	mov ah,alm[si+1]
	mov al,alm[si]
	cmp bx,si
	jz range1
	add di,bx
	stosw
	dec si
	dec list[bx]
range1:
	cmp cx,ax
	ja next1
	cmp dx,ax	
	jbe next1
	mov dx,ax	;dx为最小值,由大到小
	mov x,si
next1:
	inc bx
	inc bx
	jmp range
end0:		;最后把剩余时间存入AFTER里
	mov ax,dx
	cmp cx,0
	jz end1
	cmp dx,after
	jnz end2
	push cx
	mov cx,0 
	jmp range
end1:
	pop cx
	add al,cl	
	daa
	add ah,ch
	xchg al,ah
	daa
	xchg al,ah
	jmp endrage
end2: 
	cmp al,cl
	jae end3
	xchg al,cl
	dec ah
end3:
	sub al,cl
	das
	sub ah,ch
	xchg ah,al
	das
	xchg al,ah
endrage:
 	mov after,ax
	lea di,tpchg
	lea si,time;先显示当前时间和闹钟编号
	mov cx,6
	rep movsb
	mov si,6
	mov di,0
	mov dl,01b
	call show
	jmp main
;----------------------------------normal count:
int1 proc 
	 istart
	 mov si,6
secmin:
	 mov al,time[si-1]
	 mov ah,time[si-2]
	 add ax,1
	 aaa
	 sub si,2
	 jz hour
	 cmp ax,0600H
	 jnz next
	mov time[si+1],0
	 mov time[si],0
	jmp secmin
next:
	 mov time[si+1],al
	 mov time[si],ah
	 jmp endhour
hour:
	 cmp ax,0204H
	 jnz hour1	;到一小时的时候
	 mov time[0],0
	 mov time[1],0
hour1:
	 mov al,after[1]
	 dec al
	 das
	 jnz endhour	;闹钟剩余不到一小时
	 mov al,after[0]
	 out 34h,al	;输入通道2
endhour:
	 ireturn
int1 endp
;--------------------------customize yourself
int3 proc
	istart
	mov bx,0
	in al,50h
	test al,1000b
	jnz whenclock
	jmp whenalm
chos:
	mov cx,80h
;	mov cl,time[4]
;	mov ch,cl
wait0:	in al,50h
	not al
	test al,0111b
	jnz wait0
wait1:
	mov dx,01b
	mov di,0
	cmp flag,2
	jnz wait2
	mov dx,10000b
	mov di,4
wait2:
	call show
	in al,50h
	not al
	test al,0111b
	jnz chos1
;		mov cl,time[4]
;		cmp ch,cl	;看是否有10s
		loop wait1
		mov flag,0
		mov al,00100000b
		out 20h,al	;OCW2终止8259
		pop si
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		iret
chos1:
     test al,100b
     jnz ento
     test al,10b
     jnz back
up:
		cmp flag,0
		jz up1
		cmp si,4
		jb up1
		inc tpchg[si]
		mov al,tpchg[si]
		cmp al,10
		jnz chos
		mov tpchg[si],0
		jmp chos
up1:	
		call over
		inc tpchg[si]
		jmp chos
back:
	cmp flag,2
	jnz back1
	dec si
	cmp si,3
	jz back3
	jmp chos
back1:
	cmp si,0
	jz back2
	dec si
	jmp chos
back2:
		cmp flag,0
		jz back3
		call save
		dec bx
		dec bx
		call trans
back3:
		mov si,5
		jmp chos
ento:
		cmp si,5
		jz ento1
		inc si
		jmp chos			
ento1:
		mov si,0
		cmp flag,2
		jnz ento2
		mov al,10
		mul tpchg[4]
		add al,tpchg[5]
		mov cx,20h
		cld
		lea di,list
		push di
		repnz scasw
		pop bx
		sub di,bx
		mov bx,di
		dec bx
		dec bx
		call trans
		mov flag,1
		jmp chos
ento2:
		cmp flag,0
		jz ento3
		call save
		inc bx
		inc bx
		jmp chos
ento3:
		mov cx,6
		cld
		lea di,time
		lea si,tpchg
		rep movsb
		mov si,0
		jmp chos
;--------
whenalm:
		mov si,4
		mov flag,2
		mov ax,list[bx]
		mov cl,10
		div cl
		mov word ptr tpchg[4],ax
		jmp chos
;-------
whenclock:
		mov cx,6
		cld
		lea si,time
		lea di,tpchg
		rep movsb
		mov si,0
		mov flag,0
		jmp chos
;------------save:
save:
		mov al,10
		mul tpchg[4]
		add al,tpchg[5]
		cmp ax,0
		jnz save1
		push di
		push bx
		lea di,list[bx]
del:
		mov ax,list[bx+1]		
		stosw	; 后面覆盖前面
		inc bx
		inc bx
		cmp ax,0
		jne del
		pop di
		pop bx
		ret
save1:
		mov di,ax
		dec di
		shl di,1
		mov bx,di
		mov list[bx],ax
		mov cl,4
		mov al,tpchg[0]
		shl al,cl
		add al,tpchg[1]	
		mov alm[di+1],al	; 小时
		mov ah,tpchg[2]
		shl ah,cl
		add ah,tpchg[3]
		mov alm[di],ah	;分钟
		call left	;ah,al分别代表分钟,小时的10进制BCD
		ret
;------------------将压缩BCD换成非压缩的
trans:
	mov ax,list[bx]
	mov cl,10
	div cl
	cmp ax,0
	jz whenalm
	mov word ptr tpchg[4],ax
	mov di,list[bx]
	dec di
	shl di,1
	mov cl,4
	mov al,alm[di+1]	;hour
	mov ah,al
	and al,0fh
	mov tpchg[1],al
	shr ah,cl
	mov tpchg[0],ah
	mov al,alm[di]	;minute
	mov ah,al
	and al,0fh
	mov tpchg[3],al
	shr ah,cl
	mov tpchg[2],ah 
	mov si,0
	ret
over:		;是否超过
	  mov al,tpchg[si]
	 cmp al,limit[si]
	 jna over1
	 mov tpchg[si],0
over1:	 ret
;----------------与现有AFTER比较
left:
	mov si,x	;cmpare new alarm with after-alarm
	mov dh,alm[si+1]
	mov dl,alm[si]
	cmp dx,ax
	jbe leftend
	 xchg ax,dx
	call left1
	mov dx,after
	 cmp dx,ax
	 jbe leftend
	 xchg ax,dx
	call left1
	 mov after,ax
	 mov x,di	; 存入此时新的编号
leftend:ret
left1:	 cmp al,dl
	 jae left2
	 xchg al,dl
	dec ah
left2:	 
	sub al,dl
	das
	sub ah,dh
	xchg al,ah
	das
	xchg al,ah
	ret	 
int3 endp
;--------------------------响铃
int2 proc
	istart
	mov ax,x
	shr ax,1
	dec ax
	mov cl,10
	div cl
	mov word ptr tpchg[4],ax
	lea si,time;先显示当前时间和闹钟编号
	lea di,tpchg[4]
	mov cx,4
	rep movsb
	mov si,4
	mov di,0
	mov dl,01b
	call show
cmpbut:	mov al,00001010b;查询有无按键按下
	out 20h,al
	in al,22h
	test al,01000b
	jnz endring
;------------------------------------ring 1min
ring:	mov al,00001010b	;pc4=1---gate0=1,开始音乐
	out 54h,al
	mov si,0
	mov bx,offset dltime
	mov dl,time[3]
ring1:
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
	cmp si,6	;6位音符
        jnz ring1
	mov si,0
	mov dh,time[3]
	cmp dh,dl
	jz cmpbut
endring:ireturn
int2 endp
;------------------显示
show proc	;dl,di,si
	push bx
	push dx
	push di
show1:
	mov al,10b
	out 54h,al
	mov al,dl
	out 52h,al
	mov al,00b	;close both
	out 54h,al
	mov al,0ffh
	out 52h,al
	mov al,01b
	out 54h,al	;pc1,pc0=01,choose 74hc573(1)
	lea bx,segcode
	mov al,tpchg[di]
	xlat
	test di,1b
	jz show2
	xor al,80h
show2:
	out 52h,al 
	call delay
	mov al,0ffh
	out 52h,al
	inc di
	cmp di,6
	jz endshow
	rol dl,1
	jmp show1
delay:
	mov ax,100h
	cmp di,si
	jnz delay1
	cmp dh,0
	jz delay1
	mov al,0ffh
	out 52h,al
delay1:
	dec ax
	nop
	nop
	jnz delay1
	ret
endshow:
	cmp dh,0
	jz endshow1
	pop bx
	ret
endshow1:
	pop di
	pop dx
	mov dh,1
	jmp show1
show endp
END	

/* ------------------------------------------int3:

1---ento,2--back,3--up,4--alm/clock(开关)
flag=0---time,flag=1---调整闹钟,flag=3---选择闹钟编号

si--tpchg(6),12.01. 1,or time
di--alm-------(di)按照编号排序,编号是输入时已经确定的
bx--list---存放编号信息的列表 */





