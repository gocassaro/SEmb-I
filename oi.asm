segment code
..start:
; iniciar os registros de segmento DS e SS e o ponteiro de pilha SP
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax
	mov sp,stacktop
	mov ah,9
	mov dx,mensagem
	int 21h
; Terminar o programa e voltar para o sistema operacional
	mov ah,4ch
	int 21h
segment data
	CR equ 0dh
	LF equ 0ah
	mensagem db 'Oi, olha eu aqui',CR,LF,'$' ; necessario '$' para encerrar string, senao sai printando lixo
segment stack stack
	resb 256
	stacktop:
	
; para executar:
; nasm <nome_arq>
; freelink <nome_arq>
; <nome_arq>
; ou debug <nome_arq>.exe