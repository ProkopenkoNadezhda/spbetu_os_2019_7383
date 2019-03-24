TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
 START: JMP BEGIN
; ДАННЫЕ
avail_mem	db 'Amount of available memory:            byte',0DH,0AH,'$'
exten_mem 	db 'Extended memory size:                  kbyte',0DH,0AH,'$'
MBC_ 		db '		Chain of MBC',0DH,0AH,'$'
bu_mem_ 	db 'Address	Type MCB   Address PSP	      Size	 SD/SC ',0DH,0AH,'$'
result      db '                                                                   ',0Dh,0Ah,'$'
ENDL 		db 0DH,0AH,'$'
ERROR_STR	db 'Memory allocation error',0DH,0AH,'$'
sizepr 		db 0


Write PROC near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
Write ENDP
AVL_Mem PROC near
	mov ah,4ah
	mov bx,0FFFFh 
	int 21h
	mov ax,10h 
	mul bx 
	mov si,offset avail_mem
	add si,35
	call BYTE_TO_DEC
	mov dx,offset avail_mem
	call Write
	mov ah,48h
	mov bx,1000h
	int 21h
	jnc ERROR
		mov dx,offset ERROR_STR
		call Write
	ERROR:
	mov ah,4ah
	mov bx,offset sizepr
	int 21h

	ret
AVL_Mem ENDP

Ext_Mem PROC near
	mov  AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h
	mov bh,al
	
	mov ax,bx
	mov dx,0
	mov si,offset exten_mem
	add si,35
	call BYTE_TO_DEC
	mov dx,offset exten_mem
	call Write
	ret
Ext_Mem ENDP
Chain_of_MBC PROC near
		mov di,offset result
		mov ax,es
		add di,4h
		call WRD_TO_HEX
		mov di,offset result
		;смещение 0h
		add di,0Ch
		xor ah,ah
		mov al,es:[00h]
		call WRD_TO_HEX
		mov al,20h
		mov [di],al
		inc di
		mov [di],al
		mov di,offset result
		;смещение 1h
		mov ax,es:[01h]
		add di,19h
		call WRD_TO_HEX
		mov di,offset result
		;смещение 3h
		mov ax,es:[03h]
		mov bx,10h
		mul bx
		add di,29h
		mov si,di
		call BYTE_TO_DEC
		mov di,offset result
		add di,31h
  	mov bx,0h
PRINTS:
    mov dl,es:[8+bx]
		mov [di],dl
		inc di
		inc bx
		cmp bx,8h
		jne PRINTS
		mov ax,es:[03h]
		mov bl,es:[00h]
		ret
Chain_of_MBC ENDP
;--------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX
	pop CX 
	ret
BYTE_TO_HEX ENDP
;---------------------------------------
; перевод в 16с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP
;---------------------------------------
; перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
	push CX
	push DX
	mov CX,10
loop_bd2: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd2
	cmp AL,00h
	je end_l2
	or AL,30h
	mov [SI],AL
end_l2: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
BEGIN:

	call AVL_Mem
	call Ext_Mem	
;MBC

	mov dx, offset MBC_
	call Write
	mov dx,offset bu_mem_
	call Write
	mov ah,52h
	int 21h
	sub bx,2h
	mov es,es:[bx]
MCB_OUT:	
		call Chain_of_MBC
		mov dx,offset result
		call Write
		mov cx,es
		add ax,cx
		inc ax
		mov es,ax
		cmp bl,4Dh
		je MCB_OUT
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START 