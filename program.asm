segment code
..start:
; iniciar os registros de segmento DS e SS e o ponteiro de pilha SP
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax
	mov sp,stacktop
	mov bx,three_chars
	mov ah,1
	int 21h ; função do DOS de entrada de caractere. Retorna em AL
	dec al ; decrementa al simplesmente porque sim, a ideia eh que se digite por ex "123" e mostre "012"
	mov [bx],al
	inc bx
	int 21h
	dec al
	mov [bx],al
	inc bx
	int 21h
	dec al
	mov [bx],al
	mov dx,display_string
	mov ah,9 ; int pra mostrar o conteudo de uma string (armazenada no ds pelo resb 3)
	int 21h
; Terminar o programa e voltar para o sistema operacional
	mov ah,4ch
	int 21h
segment data
	CR equ 0dh ; equ = define constant, 0dh == \n
	LF equ 0ah ; 0ah == \r
	display_string db CR,LF ; db = define byte e serve pra basicamente criar uma variavel, alocando os valores da direita
	three_chars resb 3
	db '$'
segment stack stack
	resb 256
stacktop:

; ou seja, o codigo basicamente le 3 chars pelo input do DOS e ao final printa decrementados de 1