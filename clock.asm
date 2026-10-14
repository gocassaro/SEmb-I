; Integrantes: Gustavo Cassaro e Ellyas Hiagamo
; Obs: Não tinha certeza de como exatamente era pra ser o ajuste de hora, então
; no keyINT definimos h e m pra aumentar a hora ou minuto em 1, e vai ciclando 
; quando chega no limite do formato.
segment code
..start:
        MOV     AX, data
        MOV     DS, AX
        MOV     AX, stack
        MOV     SS, AX
        MOV     SP, stacktop
        
        CLI                             ; Desabilita interrupções
        XOR     AX, AX
        MOV     ES, AX
        
        ; Salva e redireciona INT 8 (Clock)
        MOV     AX, [ES:08h*4]
        MOV     [offset_dos8], AX
        MOV     AX, [ES:08h*4+2]
        MOV     [cs_dos8], AX
        MOV     [ES:08h*4+2], CS
        MOV     WORD [ES:08h*4], ClockINT
        
        ; Salva e redireciona INT 9 (Teclado)
        MOV     AX, [ES:09h*4]
        MOV     [offset_dos9], AX
        MOV     AX, [ES:09h*4+2]
        MOV     [cs_dos9], AX
        MOV     [ES:09h*4+2], CS
        MOV     WORD [ES:09h*4], keyINT
        
        STI                             ; Reabilita interrupções
        
l1:
        CMP     byte [sair_flag], 1     ; Verifica se a flag de saída foi ativada pelo teclado
        JE      fim
        CMP     byte [atualiza_tela], 1 ; Verifica se houve mudança de segundo ou ajuste manual
        JNE     l1
        MOV     byte [atualiza_tela], 0
        CALL    converte                ; Atualiza display na mesma linha
        JMP     l1
        
fim:
        CLI
        XOR     AX, AX
        MOV     ES, AX
        ; Restaura INT 8 original
        MOV     AX, [cs_dos8]
        MOV     [ES:08h*4+2], AX
        MOV     AX, [offset_dos8]
        MOV     [ES:08h*4], AX
        ; Restaura INT 9 original
        MOV     AX, [cs_dos9]
        MOV     [ES:09h*4+2], AX
        MOV     AX, [offset_dos9]
        MOV     [ES:09h*4], AX
        STI
        
        MOV     AH, 4Ch
        INT     21h                     ; Retorna ao DOS

; ISR DO RELÓGIO (INT 8)
ClockINT:
        PUSH    AX
        PUSH    DS
        MOV     AX, data
        MOV     DS, AX
        
        INC     byte [tique]
        CMP     byte [tique], 18
        JB      Fimrel
        MOV     byte [tique], 0
        MOV     byte [atualiza_tela], 1 ; Marca para repintar a tela na virada do segundo
        
        INC     byte [segundo]
        CMP     byte [segundo], 60
        JB      Fimrel
        MOV     byte [segundo], 0
        
        INC     byte [minuto]
        CMP     byte [minuto], 60
        JB      Fimrel
        MOV     byte [minuto], 0
        
        INC     byte [hora]
        CMP     byte [hora], 24
        JB      Fimrel
        MOV     byte [hora], 0
        
Fimrel:
        MOV     AL, 20h
        OUT     20h, AL                 ; EOI no PIC
        POP     DS
        POP     AX
        IRET

; ISR DO TECLADO (INT 9)
keyINT:
        PUSH    AX
        PUSH    DS
        MOV     AX, data
        MOV     DS, AX
        
        IN      AL, 60h                 ; Lê Make/Break Code da porta
        
        CMP     AL, 01h                 ; Make code do ESC
        JNE     k_d
        MOV     byte [sair_flag], 1
        JMP     k_end
        
k_d:    CMP     AL, 20h                 ; Make code da tecla 'd'
        JNE     k_v
        MOV     byte [formato], 1       ; Seta 12h
        MOV     byte [atualiza_tela], 1
        JMP     k_end
        
k_v:    CMP     AL, 2Fh                 ; Make code da tecla 'v'
        JNE     k_h
        MOV     byte [formato], 0       ; Seta 24h
        MOV     byte [atualiza_tela], 1
        JMP     k_end
        
k_h:    CMP     AL, 23h                 ; Make code da tecla 'h' (ajuste de hora)
        JNE     k_m
        INC     byte [hora]
        CMP     byte [hora], 24
        JB      k_h_ok
        MOV     byte [hora], 0
k_h_ok: MOV     byte [atualiza_tela], 1 ; Permite visualização imediata do ajuste
        JMP     k_end
        
k_m:    CMP     AL, 32h                 ; Make code da tecla 'm' (ajuste de minuto)
        JNE     k_end
        INC     byte [minuto]
        CMP     byte [minuto], 60
        JB      k_m_ok
        MOV     byte [minuto], 0
k_m_ok: MOV     byte [atualiza_tela], 1 ; Permite visualização imediata do ajuste
        
k_end:
        IN      AL, 61h                 ; Lê porta de controle
        OR      AL, 80h                 ; Seta bit de reset do teclado
        OUT     61h, AL
        AND     AL, 7Fh                 ; Restaura estado
        OUT     61h, AL
        MOV     AL, 20h
        OUT     20h, AL                 ; EOI no PIC
        POP     DS
        POP     AX
        IRET

; FUNÇÃO DE FORMATAÇÃO/ IMPRESSÃO NA TELA
converte:
        PUSH    AX
        PUSH    BX
        PUSH    DX
        PUSH    DS
        MOV     AX, data
        MOV     DS, AX
        
        MOV     AL, [hora]
        CMP     byte [formato], 1
        JNE     conv_24h
        
        ; Lógica do formato 12h
        CMP     AL, 12
        JAE     eh_pm
eh_am:
        MOV     byte [horario+10], 'A'  ; Aplica AM
        MOV     byte [horario+11], 'M'
        CMP     AL, 0
        JNE     calc_digits
        MOV     AL, 12                  ; Se for 00h, imprime 12 AM
        JMP     calc_digits
        
eh_pm:
        MOV     byte [horario+10], 'P'  ; Aplica PM
        MOV     byte [horario+11], 'M'
        CMP     AL, 12
        JE      calc_digits             ; Se for 12h, imprime 12 PM
        SUB     AL, 12                  ; 13h vira 01h PM, etc.
        JMP     calc_digits
        
conv_24h:
        ; Lógica do formato 24h
        MOV     byte [horario+10], ' '  ; Apaga a string AM/PM
        MOV     byte [horario+11], ' '
        
calc_digits:
        ; Converte hora pronta em AL para ASCII
        XOR     AH, AH
        MOV     BL, 10
        DIV     BL
        ADD     AL, 30h
        MOV     byte [horario+1], AL
        ADD     AH, 30h
        MOV     byte [horario+2], AH
        
        ; Converte Minutos
        XOR     AH, AH
        MOV     AL, byte [minuto]
        DIV     BL
        ADD     AL, 30h
        MOV     byte [horario+4], AL
        ADD     AH, 30h
        MOV     byte [horario+5], AH
        
        ; Converte Segundos
        XOR     AH, AH
        MOV     AL, byte [segundo]
        DIV     BL
        ADD     AL, 30h
        MOV     byte [horario+7], AL
        ADD     AH, 30h
        MOV     byte [horario+8], AH
        
        ; Imprime string (uso de '\r' 13 sobrescreve a mesma linha)
        MOV     AH, 09h
        MOV     DX, horario
        INT     21h
        
        POP     DS
        POP     DX
        POP     BX
        POP     AX
        RET

segment data
        offset_dos8     DW 0
        cs_dos8         DW 0
        offset_dos9     DW 0
        cs_dos9         DW 0
        tique           DB 0
        segundo         DB 0
        minuto          DB 0
        hora            DB 0
        sair_flag       DB 0
        atualiza_tela   DB 1
        formato         DB 0            ; 0 = 24h, 1 = 12h
        ; String de exibição. O byte '13' retorna o cursor ao início da linha sem pular linha.
        horario         DB 13,'00:00:00    $' 

segment stack stack
        resb 256
stacktop: