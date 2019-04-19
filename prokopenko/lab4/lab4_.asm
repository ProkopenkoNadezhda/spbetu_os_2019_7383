ASSUME CS:CODE, DS:DATA, SS:AStack
AStack SEGMENT STACK
	DW 64 DUP(?)
AStack ENDS

CODE SEGMENT

INTERRUPT PROC FAR
	jmp function
;DATA
	AD_PSP 		dw 0
	SR_PSP 		dw 0
	keep_cs 	dw 0
	keep_ip 	dw 0
	is_loaded 	dw 0FFDAh
	counter 	db 'Number of interrupt calls: 0000  $'

function:
	push ax
	push bx
	push cx
	push dx

	;����祭�� �����
	mov ah,3h
	mov bh,0h
	int 10h
	push dx ;���࠭塞 ����� � �⥪�

	;��⠭���� �����
	mov ah,02h
	mov bh,0h
	mov dx,0214h
	int 10h
	;������ ���-�� ���뢠���
	push si
	push cx
	push ds
	mov ax,SEG counter
	mov ds,ax
	mov si,offset counter
	add si,31

	mov ah,[si]
	inc ah
	mov [si],ah
	cmp ah,3Ah
	jne _not
	mov ah,30h
	mov [si],ah

	mov bh,[si-1]
	inc bh
	mov [si-1],bh
	cmp bh,3Ah
	jne _not
	mov bh,30h
	mov [si-1],bh

	mov ch,[si-2]
	inc ch
	mov [si-2],ch
	cmp ch,3Ah
	jne _not
	mov ch,30h
	mov [si-2],ch

	mov dh,[si-3]
	inc dh
	mov [si-3],dh
	cmp dh,3Ah
	jne _not
	mov dh,30h
	mov [si-3],dh

_not:
  pop ds
	pop cx
	pop si
	;����� ��ப�
	push es
	push bp
	mov ax,SEG counter
	mov es,ax
	mov ax,offset counter
	mov bp,ax
	mov ah,13h
	mov al,00h
	mov cx,31
	mov bh,0
	int 10h
	pop bp
	pop es
	;����⠭���� �����
	pop dx
	mov ah,02h
	mov bh,0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax       ;����⠭������� ax

	iret
INTERRUPT ENDP

END_INT PROC
END_INT ENDP

ISLOADED PROC near
	push dx
        push es
	push bx

	mov ax,351Ch ;����祭�� ����� ���뢠���
	int 21h

	mov dx,es:[bx+11]
	cmp dx,0FFDAh ;�஢�ઠ �� ᮢ������� ����
	je int_is_loaded
	mov al,0h
	pop bx
	pop es
	pop dx
	ret
int_is_loaded:
	mov al,01h
  pop bx
	pop es
	pop dx
	ret
ISLOADED ENDP

CHECK_UNLOAD_FLAG PROC near
	push es
	mov ax,AD_PSP
	mov es,ax
	xor bx,bx
	inc bx


	mov al,es:[81h+bx]
	inc bx
	cmp al,'/'
	jne unload_end

	mov al,es:[81h+bx]
	inc bx
	cmp al,'u'
	jne unload_end

	mov al,es:[81h+bx]
	inc bx
	cmp al,'n'
	jne unload_end

	mov al,1h

unload_end:
	pop es
	ret
CHECK_UNLOAD_FLAG ENDP

LOAD PROC near
	push ax
	push bx
	push dx
	push es

	mov ax,351Ch
	int 21h
	mov keep_ip,bx
	mov keep_cs,es

	push ds
	mov dx,offset INTERRUPT
	mov ax,seg INTERRUPT
	mov ds,ax
	mov ax,251Ch
	int 21h
	pop ds

	mov dx,offset int_loaded
	mov ah,09h
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	ret
LOAD ENDP

UNLOAD PROC near
	push ax
	push bx
	push dx
	push es

	mov ax,351Ch
	int 21h

	cli
	push ds
	mov dx,es:[bx+9]   ;IP �⠭���⭮��
	mov ax,es:[bx+7]   ;CS �⠭���⭮��
	mov ds,ax
	mov ax,251Ch
	int 21h
	pop ds
	sti

	mov dx,offset int_unload    ;ᮮ�饭�� � ���㧪�
	mov ah,09h
	int 21h

;�������� MCB
	push es

	mov cx,es:[bx+3]
	mov es,cx
	mov ah,49h
	int 21h

	pop es
	mov cx,es:[bx+5]
	mov es,cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	ret
UNLOAD ENDP

Main PROC far

	mov bx,02Ch
	mov ax,[bx]
	mov SR_PSP,ax
	mov AD_PSP,ds  ;��࠭塞 PSP
	sub ax,ax
	xor bx,bx

	mov ax,data
	mov ds,ax

	call CHECK_UNLOAD_FLAG   ;����㧪� ��� ���㧪�(�஢�ઠ ��ࠬ���)
	cmp al,1h
	je un_load

	call ISLOADED   ;��⠭����� �� ࠧࠡ�⠭�� ����� ���뢠���
	cmp al,01h
	jne al_loaded

	mov dx,offset int_al_loaded	;��� ��⠭�����(��室 � ᮮ�饭��)
	mov ah,09h
	int 21h

	mov ah,4Ch
	int 21h

al_loaded:

;����㧪�
	call LOAD
;��⠢�塞 ��ࠡ��稪 ���뢠��� � �����
	mov dx,offset END_INT
	mov cl,4h
	shr dx,cl
	inc dx
	add dx,1Ah

	mov ax,3100h
	int 21h

;���㧪�
un_load:

	call ISLOADED
	cmp al,0h
	je not_loaded

  call UNLOAD

	mov ax,4C00h
	int 21h

not_loaded:
	mov dx,offset int_not_loaded      ;�᫨ १����� �� ��⠭�����, � ������⥫쭮 ���㦠�� �⠭����� ��
	mov ah,09h
	int 21h

	mov ax,4C00h
	int 21h


Main ENDP
CODE ENDS

DATA SEGMENT
	int_not_loaded db 'Resident not loaded',0DH,0AH,'$'
	int_al_loaded db 'Resident already loaded',0DH,0AH,'$'
	int_loaded db 'Resident loaded',0DH,0AH,'$'
	int_unload db 'Resident was unloaded',0DH,0AH,'$'
DATA ENDS
END Main
