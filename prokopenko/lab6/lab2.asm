TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
 START: JMP BEGIN
; ДАННЫЕ
off_mem_	db 'Segment address of the first byte of inaccessible memory: '
off_mem 	db '    ',0DH,0AH,'$'
Seg_adr_ 	db 'Segmental address of the environment passed to the program: '
Seg_adr		db '    ',0DH,0AH,'$'
TAIL_ 		db 'Command-line tail: ',0DH,0AH,'$'
SREDA_ 		db 'The contents of the environment area in the symbolic form: ',0DH,0AH,'$'
PATH_ 		db 'Load module path: ',0DH,0AH,'$'
ENDL 		db 0DH,0AH,'$'
; ПРОЦЕДУРЫ
;--------------------------------------- 
Write PROC near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
Write ENDP
;---------------------------------------
GET_adr_off_mem PROC near
	mov ax,es:[2]
	mov di,offset off_mem+3
	call WRD_TO_HEX
	lea dx,off_mem_
	call Write
	ret
GET_adr_off_mem ENDP	
;---------------------------------------
GET_Seg_adr PROC near
	mov ax,es:[2Ch]
	mov di,offset Seg_adr+3
	call WRD_TO_HEX
	lea dx,Seg_adr_
	call Write
	ret
GET_Seg_adr  ENDP
;---------------------------------------
TAIL PROC near
	mov dx,offset TAIL_
	call Write
	mov cx,0
	mov cl,es:[80h]
	cmp cl,0
	je TAIL_END
	mov dx,81h
	mov bx,0
	mov ah,02h
	TAIL_loop:
		mov dl,es:[bx+81h]
		int 21h
		inc	bx
	loop TAIL_loop
	mov dx,offset ENDL
	call Write
	TAIL_END:
	ret
TAIL ENDP
;--------------------------------------
SREDA PROC near
	mov dx,offset SREDA_
	call Write
	push es
	; кладём в es адрес области среды
	mov ax,es:[2Ch]
	mov es,ax
	mov ah,02h
	mov bx,0
	SREDA_loop:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne SREDA_loop
		mov dx,offset ENDL
		call Write
		cmp word ptr es:[bx],0000h
		jne SREDA_loop
	add bx,4 ; пропускаем 0001
	mov dx,offset PATH_
	call Write
	
	SREDA_loop1:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne SREDA_loop1
	mov dx,offset ENDL
	call Write
	pop es
	ret
SREDA ENDP
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
BEGIN:
	call GET_adr_off_mem
	call GET_Seg_adr
	call TAIL
	call SREDA
	xor al, al
	mov ah,01h
	int 21h
	mov ah,4Ch
	int 21h

TESTPC ENDS
 END START 