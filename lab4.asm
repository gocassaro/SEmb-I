segment code ; Define o início do segmento de código
..start:
MOV AX,dados ; Inicialização dos registros de segmentos
MOV DS,AX
MOV AX,stack
MOV SS,AX
MOV SP,stacktop
; AQUI COMECA A EXECUCAO DO PROGRAMA PRINCIPAL
MOV DX,mensini ; Mensagem de inicio
MOV AH,9
INT 21h
MOV AX,0 ; Primeiro elemento da série
MOV BX,1 ; Segundo elemento da série
L14:
MOV DX,AX
ADD DX,BX ; Calcula novo elemento da série
MOV AX,BX
MOV BX,DX
CALL printnumb
CMP DX, 0x8000
JL L14
; AQUI TERMINA A EXECUCAO DO PROGRAMA PRINCIPAL
exit:
MOV DX,mensfim ; Mensagem de final
MOV AH,9
INT 21h
quit:
MOV AH,4CH
INT 21h

printnumb:
; AQUI, VOCÊ DEVE SALVAR O CONTEXTO
MOV DI,saída ; Variável saída linha 32
CALL num2ascii ; Chamado de função num2ascii
MOV DX,saída ; Imprime o numero
MOV AH,9
INT 21h
; AQUI, VOCÊ DEVE RECUPERAR O CONTEXTO
RET

num2ascii:
MOV BL,10 ; Prepara a divisão
MOV AX,DX ; Passa valor que queremos imprimir pra AX
loop2ascii:
DIV BL ; Salva resultado da div em AL e resto em AH
ADD AH,0x30 ; Somamos 30h para bater o dígito na tabela ASCII
MOV saída,AH ; Substituímos valor na memória
MOV AX,AL ; Pegamos próxima unidade
ADD DI,1 ; Avança pra próxima posição no DS
CMP AL,0 ; Enquanto ainda tiver num, continua dividindo
JNE loop2ascii
MOV DI,0
RET

segment dados ; Segmento de dados inicializados
mensini: DB 'Programa que calcula a Série de Fibonacci. ',13,10,'$'
mensfim: DB 'bye',13,10,'$'
saída: DB '00000',13,10,'$'
segment stack stack
RESB 256 ; reserva 256 bytes para formar a pilha
stacktop: ; posição de memória que indica o topo da pilha=SP