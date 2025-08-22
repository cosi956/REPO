data segment
    freq db 26,39,44,44,39
         db 35,35,33,30,26
         db 39,35,33,30,20
    delay db 6,6,6,6,0ch,0ch
    num  db 0,1,2,3,4,0
data ends
stack segment
    db 100 dup(0)
    top=100
stack ends
code segment
   assume ds:data,cs:code,ss:stack
start:
    mov ax,stack
    mov ss,ax
    mov sp,top
    push ds
    sub ax,ax
    push ds
    mov ax,data
    mov ds,ax
    mov al,00110000b
    out 36h,al
    mov al,01010111b
    out 36h,al
    mov di,0
    mov cx,0ffh
    song:
        mov ax,3000
        div freq[di]
        out 32h,al
        mov bl,num[bx] 
        mov al,delay[bx]
        out 30h,al 
        inc bx  
        inc di
        loop song
    mov al,0
    out 38h,al ;gate=0
    code ends
end start