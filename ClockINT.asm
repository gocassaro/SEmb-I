; Este programa tem por objetivo usar a interrupção por hardware de "tique", a qual é definida como Int 8
; O sistema utiliza uma fonte de relogio de ~18.2 Hz, ou seja, a cada ~0.0549 segundos ou ~54.9 ms, o sistema é interrumpido

segment code
..start:
		MOV 	AX,data						; Inicializa o registrador de Segmento de Dados DS
		MOV 	DS,AX
		MOV 	AX,stack					; Inicializa o registrador de Segmento de Pilha SS
		MOV 	ss,AX
		MOV 	sp,stacktop					; Inicializa o apontador de Pilha SP
	
		CLI									; Deshabilita INTerrupções por harDWare - pin INTR NÃO atende INTerrupções externas
		XOR 	AX, AX						; Limpa o registrador AX, é equivALente a fazer "MOV AX,0"
		MOV 	ES, AX						; Inicializa o registrador de Segmento Extra ES para acessar à região de vetores de INTerrupção (posição zero de memoria)
		MOV     AX, [ES:INTr*4]				; Carrega em AX o vALor do IP do vector de INTerrupção 8
		MOV     [offset_dos], AX    		; Salva na variável offset_dos o vALor do IP do vector de INTerrupção 8
		MOV     AX, [ES:INTr*4+2]   		; Carrega em AX o vALor do CS do vector de INTerrupção 8
		MOV     [cs_dos], AX  				; Salva na variável cs_dos o vALor do CS do vector de INTerrupção 8   
		MOV     [ES:INTr*4+2], CS			; Atualiza o valor do CS do vector de INTerrupção 8 com o CS do programa atuAL
		MOV     WORD [ES:INTr*4],ClockINT	; Atualiza o valor do IP do vector de INTerrupção 8 com o offset "ClockINT" do programa atuAL
		STI									; Habilita INTerrupções por harDWare - pin INTR SIM atende INTerrupções externas
	
l1:											; No loop principal l1, a função converte só é chamada se a variável tique for iguAL a 0, se não, verifica se ALguma tecla foi acionada para sair do programa
		CMP 	byte [tique], 0				; Compara variável tique com zero
		JNE 	ab							; Pula a ab se tique for diferente de zero	
		CALL 	converte					; Chama função converte se ab for iguAL a zero

ab: 	MOV 	AH,0Bh						; Carrega em AH o valor de 0Bh, parâmetro para ler o teclado com interrupção por software "INT 21h"	
		INT 	21h							; Le buffer de teclado e armazena em AL "0" se nehuma tecla foi acionada ou "1" se qualquer tecla foi acionada
		CMP 	AL,0						; Se o buffer está vacio, ou seja, nehuma tecla foi acionada pula para "l1", se não, pula para "fim"
		JNE 	fim							; Salto condicional -> se o teclado foi acionado pula para "fim"	
		JMP 	l1							; Salta para l1 se nehuma tecla foi acionada, ou seja, se a clausula do salto condicionla "linha 31" não foi acionada

fim:										; Ao sair do programa temos que restaurar o CS:IP da Interrupção 8, que INCialmente alteramos nas linhas 19 e 20
		CLI									; Deshabilita Interrupções por harDWare - pin INTR NÃO atende Interrupções externas							
		XOR     AX, AX						; Limpa o registrador AX, é equivalente a fazer "MOV AX,0"
		MOV     ES, AX						; Inicializa o registrador de Segmento Extra ES para acessar à região de vetores de INTerrupção (posição zero de memoria)
		MOV     AX, [cs_dos]				; Carrega em AX o valor do CS do vector de INTerrupção 8 que foi salvo na variável cs_dos -> linha 16
		MOV     [ES:INTr*4+2], AX			; Atualiza o valor do CS do vector de INTerrupção 8 que foi salvo na variável cs_dos
		MOV     AX, [offset_dos]			; Carrega em AX o valor do IP do vector de INTerrupção 8 que foi salvo na variável offset_dos				
		MOV     [ES:INTr*4], AX 			; Atualiza o valor do IP do vector de INTerrupção 8 que foi salvo na variável offset_dos
		MOV     AH, 4Ch						; Carrega em AH o valor de 4Ch, parametro para INT 21h
		INT     21h							; Chama Interrupção 21h para RETornar o controle ao sistema operacional -> sai de forma segura da execução do programa

ClockINT:									; Este segmento de código só será executado se um pulso de relojio está ativo, ou seja, se a INT 8h for acionada!
		PUSH	AX							; Salva contexto na pilha							
		PUSH	DS
		MOV     AX,data						; Carrega em AX o endereço de "data" -> Região do código onde encontra-se o segemeto de dados "Segment data"
		MOV     DS,AX						; Atualiza registrador de segmento de dados DS, isso pode ser feito no inicio do programa!	
    
		INC		byte [tique]				; Incremente variável tique toda vez que entra na interrupção
		CMP		byte[tique], 18				; Compara variável "teique" com 18, isso para alterar os valores do relogio a cada segundo -> 18/18.2 ~1 segundo!
		JB		Fimrel						; Se for menor que 18 pula para Fimrel
		MOV 	byte [tique], 0				; Se não, limpa variável tique e  
		INC 	byte [segundo]				; Incrementa variável segundo
		CMP 	byte [segundo], 60			; Compara variável "segundo" com 60
		JB   	Fimrel						; Se segundo for menor do que 60, pula para Fimrel
		MOV 	byte [segundo], 0			; Se não, limpa segundo e
		INC 	byte [minuto]				; Incrementa variável minuto
		CMP 	byte [minuto], 60			; Compara variável "minuto" com 60
		JB   	Fimrel						; Se minuto for menor do que 60, pula para Fimrel
		MOV 	byte [minuto], 0			; Se não, limpa minuto e
		INC 	byte [hora]					; Incrementa variável hora
		CMP 	byte [hora], 24				; Compara variável "hora" com 24
		JB   	Fimrel						; Se hora for menor do que 24, pula para Fimrel
		MOV 	byte [hora], 0				; Se não, limpa hora	
Fimrel:
		MOV		AL,eoi						; Carrega o AL com a byte de End of Interruption, -> 20h por default						
		OUT		20h,AL						; Livera o PIC que está na porta 20h
		POP		DS							; Reestablece os registradores salvos na pilha na linha 46
		POP		AX
		IRET								; Retorna da interrupção
		
converte:									; Esta função conver os valores binarios/decimais para ascii, ou seja acrecenta 0x30 a cada numero
		PUSH 	AX							; Salva contexto na pilha
		PUSH    DS
		MOV     AX, data					; Carrega em AX o endereço de "data" -> Região do código onde encontra-se o segemeto de dados "Segment data"
		MOV     DS, AX						; Atualiza registrador de segmento de dados DS, isso pode ser feito no inicio do programa!
		
		XOR 	AH, AH						; Limpa AH, pois será utilizado na operação de divisão 
		MOV     BL, 10						; Carrega o operando da divisão
		MOV 	AL, byte [segundo]			; Carrega em AL o valor da variável segundo de 0 até 59
		DIV     BL							; Divide AL por BL, ou seja, AL/10. Como 10 é um byte, o cociente fica armacenado em AL e o residuo em AH 
		ADD     AL, 30h 					; Acrecenta 0x30 ao cociente para converter em ascii                                                                                          
		MOV     byte [horario+6], AL		; Atualiza a variável "horario" ná posição decenas de segundos
		ADD     AH, 30h						; Acrecenta 0x30 ao residuo para converter em ascii
		MOV 	byte [horario+7], AH		; Atualiza a variável "horario" ná posição unidades de segundos
											
		XOR 	AH, AH						; Repete o processo anterior para minutos
		MOV 	AL, byte [minuto]
		DIV     BL
		ADD     AL, 30h                                                                                          
		MOV     byte [horario+3], AL
		ADD     AH, 30h
		MOV 	byte [horario+4], AH
	
		XOR 	AH, AH						; Repete o processo anterior para horas
		MOV 	AL, byte [hora]
		DIV     BL
		ADD     AL, 30h                                                                                          
		MOV     byte [horario], AL
		ADD     AH, 30h
		MOV 	byte [horario+1], AH
		
		MOV 	AH, 09h						; Imprime o valor de horario com a interrupção 21h
		MOV 	dx, horario
		INT 	21h
		
		POP     DS							; Recupera contexto salvo nas linhas 75 e 76
		POP     AX
		RET 								; Retorna da função 

segment data
		eoi     	EQU 20h					; Byte de final de interrupção PIC - resgistrador OCW2 do 8259A
		pictrl  	EQU 20h					; Porta do PIC do Clock -> tick de ~54.9 ms 
		INTr	   	EQU 08h					; Interrupção por hardware do tick
		char		DB	0
		offset_dos	DW	0					; Variável de 2 bytes para armacenar o IP da INT 8
		cs_dos		DW	0					; Variável de 2 bytes para armacenar o CS da INT 8
		tique		DB  0					; Variável de 2 bytes que é incrementada a cada tick do clock ~54.9 ms 
		segundo		DB  0					; Variável para os segundos
		minuto 		DB  0					; Variável para os minutos
		hora 		DB  0					; Variável para as horas
		horario		DB  0,0,':',0,0,':',0,0,' ', 13,'$' ; Variável typo string para printar o relogio

segment stack stack							; Segmento da pilha -> SS
		resb 256							; Reserva 256 bytes para a pilha
stacktop:									; Define ponteiro do topo da pilha -> SP