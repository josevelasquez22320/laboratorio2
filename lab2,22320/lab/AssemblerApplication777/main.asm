;UNIVERSIDAD DEL VALLE DE GUATEMALA
;IE2023: PROGRAMACIÓN DE MICROCONTROLADORES
;Lab2.asm
;AUTOR: Jose Andrés Velásquez Gacía 
;PROYECTO: contador hexdecimal con pushbottons y timer 0
;HARDWARE: ATMEGA328P
;CREADO: 12/02/2024
;ÚLTIMA MODIFICACIÓN: 12/02/2024 23:36
.INCLUDE "M328PDEF.inc"
.CSEG
.ORG 0x000


; Configuración del stack
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R16, HIGH(RAMEND)
OUT SPH, R16

.DSEG
SEVENSEGMENTS: .BYTE 16 ; Definición de una tabla de siete segmentos de 16 bytes
.CSEG

;la tabla de siete segmentos
POPULATESEVENSEGMENTS:
; Carga la dirección de memoria baja y alta de la tabla de siete segmentos
	LDI XL, LOW(SEVENSEGMENTS)
	LDI XH, HIGH(SEVENSEGMENTS)

    ; Pobla la tabla de siete segmentos con los valores correspondientes

	LDI R16, 0xFC ;0
	ST X+, R16
	LDI R16, 0x90 ;1
	ST X+, R16
	LDI R16, 0x7A ;2
	ST X+, R16
	LDI R16, 0xDA ;3
	ST X+, R16
	LDI R16, 0x96 ;4
	ST X+, R16
	LDI R16, 0xCE ;5
	ST X+, R16
	LDI R16, 0xEE ;6
	ST X+, R16
	LDI R16, 0x9A ;7
	ST X+, R16
	LDI R16, 0xFE ;8
	ST X+, R16
	LDI R16, 0xDE ;9
	ST X+, R16
	LDI R16, 0xBE ;A
	ST X+, R16
	LDI R16, 0xE6 ;b
	ST X+, R16
	LDI R16, 0x6C ;C
	ST X+, R16
	LDI R16, 0xF2 ;d
	ST X+, R16
	LDI R16, 0x6E ;E
	ST X+, R16
	LDI R16, 0x2E ;F
	ST X+, R16

; Configuración inicial
SETUP:

    ; Selección de reloj: Frecuencia de 1MHz
	LDI R16, (1<<CLKPCE)
	STS CLKPR, R16
	LDI R16, 0b00000100
	STS CLKPR, R16

    ; Configuración de puertos de entrada y salida
	SBI DDRB, PB0
	LDI R16, 0b11111100 
	STS DDRD, R16

	LDI R16, 0B0011_1100
	STS DDRC, R16
	
	SBI PORTC, PC0
	SBI PORTC, PC1
	
    ; Iniciar Timer0
	CALL INIT_T0
	
	    ; Definir registros de trabajo
	.DEF COUNTER=R18
	.DEF HEXCOUNTER=R19
	.DEF DISPOUT=R20
	.DEF INPUTS=R21
	
	LDI HEXCOUNTER, 0x00
	LDI COUNTER, 0b0000_0000
; Bucle infinito
LOOP:
    ; Esperar a que se levante la bandera de comparación
	IN R16, TIFR0
	CPI R16, (1<<TOV0)
	BRNE LOOP

	CALL INCCOUNTER
	
    ; Reiniciar Timer
	LDI R16, 157
	OUT TCNT0, R16
	SBI TIFR0, TOV0 ; Reiniciar la bandera
	
	IN INPUTS, PINC
	SBRS INPUTS, PC1
	CALL INCHEXCOUNTER
	SBRS INPUTS, PC0
	CALL DECHEXCOUNTER

	CALL OUTPUTDISPLAY	

	RJMP LOOP


; Configuración del Timer0, modo normal
; Aproximadamente 100ms (100.532 ms) por ciclo de overflow
INIT_T0:
	LDI R16, 0
	OUT TCCR0A, R16 
	
	LDI R16, (1<<CS02)|(1<<CS00)
	OUT TCCR0B, R16
	
	LDI R16, 157 
	OUT TCNT0, R16
	
	LDI R16, 0
	RET

; Incrementar el contador. Si el contador es 0x0F (15), reiniciar a 0.
; Limpiar los primeros 4 bits del contador
INCCOUNTER:
	INC COUNTER
	CBR COUNTER, 0b1111_0000 
	RET	
	
; Mostrar el valor del contador en los displays de 7 segmentos
OUTPUTDISPLAY:
	MOV R17, COUNTER
	LSL R17 
	LSL R17 
	; Configuración de los pines de salida para los displays de 7 segmentos
    ; PC2
	SBRS R17, PC2
	CBI PORTC, PC2
	SBRC R17, PC2
	SBI PORTC, PC2
; Actualizar el estado del LED indicador

	;PC3
	SBRS R17, PC3
	CBI PORTC, PC3
	SBRC R17, PC3
	SBI PORTC, PC3
	
	;PC4
	SBRS R17, PC4
	CBI PORTC, PC4
	SBRC R17, PC4
	SBI PORTC, PC4

	;PC5
	SBRS R17, PC5
	CBI PORTC, PC5 
	SBRC R17, PC5
	SBI PORTC, PC5
	
	CALL SVSGMTDECODER

	MOV R17, DISPOUT
	SBRS R17,7
	CBI PORTB, PB0
	SBRC R17, 7
	SBI PORTB, PB0
	
	LSL R17
	OUT PORTD, R17	
	RET
; Decodificar el valor del contador para mostrarlo en los displays de 7 segmentos

SVSGMTDECODER:
	MOV R21, HEXCOUNTER
	LDI XL, LOW(SEVENSEGMENTS)
	LDI XH, HIGH(SEVENSEGMENTS)
	ADD XL, HEXCOUNTER

	LD R21, X
	 
	MOV DISPOUT, R21
	RET
; Incrementar el contador hexadecimal

INCHEXCOUNTER:
	INC HEXCOUNTER
	CBR HEXCOUNTER, 0b1111_0000
	CALL DEBOUNCE
	RET
; Decrementar el contador hexadecimal

DECHEXCOUNTER:
	DEC HEXCOUNTER
	CBR HEXCOUNTER, 0b1111_0000
	CALL DEBOUNCE
	RET
	; Aplicar debounce a las entradas

DEBOUNCE:
	;Reiniciar Timer
	LDI R16, 107;entar el valor del temporizador para debounce a 107
	OUT TCNT0, R16
	SBI TIFR0, TOV0 ;reiniciar bandera
	CHECK:
	IN R16, TIFR0
	CPI R16, (1<<TOV0)
	BRNE CHECK
	RET