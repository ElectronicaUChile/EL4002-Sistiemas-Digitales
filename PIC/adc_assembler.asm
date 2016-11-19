; ----------------------------------------------
; Nombre: ADC PIC18F4550 - Assembler
; Autor: Christopher E. Muñoz P.
; Fecha: Mayo - 2015
; Email: chmunozp@live.cl
; ----------------------------------------------

; ----------------------------------------------
; PIC SELECTION
; ----------------------------------------------

	LIST P=18F4550			; Indica que las instrucciones a utilizar
							; corresponden al PIC18F4550
	#include <P18F4550.inc> ; Archivo que contiene los nombres
							; de los registros del PIC

; ----------------------------------------------
; BIT CONFIGURATIONS
; ----------------------------------------------

; Configuraciones de bit para opciones del PIC 
	CONFIG WDT = OFF		; Deshabilita el Watchdog Timer
	CONFIG MCLRE = ON 		; Habilita el Master Clear
	CONFIG DEBUG = ON 		; Habilita el Debug del PIC
	CONFIG LVP = OFF		; Deshabilita 
	CONFIG FOSC = XT_XT		; Selecciona el tipo de oscilador
							; XT_XT := Oscilador 4[MHz]

; ----------------------------------------------
; PROGRAM INSTRUCTIONS
; ----------------------------------------------

; Dirección de programa 0x0000
; La instruccion "org DIR" indica que las siguientes instrucciones
; seran guardadas partir de la direccion "DIR"
	org 0x0000
	goto start				; Salta a la etiqueta "start"

; Dirección de programa dedicada a interrupciones
	org 0x0008

; Esta rutina esta encargada de manejar las interrupciones ocurridas en el PIC
ISR							; Etiqueta "ISR"
							; ISR := Interrupt Service Routine
	bsf ADCON0, GO_DONE		; Inicia la siguiente conversion
	bcf PIR1, ADIF			; Avisa que la interrupcion ya fue atendida
	movff ADRESH, PORTD		; Mueve los 8 bits mas significados del dato convertido
							; al puerto D
	retfie					; Sale de la interrupcion

; Funcion que configura el ADC y los registros de salida
config_proc					; Etiqueta "config_proc"
	bsf TRISA, 0 			; Fija el bit 0 del puerto A como entrada
	clrf TRISC				; Fija los bits del puerto C como salida
	clrf TRISD				; Fija los bits del puerto D como salida
	movlw b'00001110' 		; Mueve el literal binario '00001110' al WREG
	movwf ADCON1			; Mueve el WREG al registro ADCON1
							; ADCON1 maneja algunas configuraciones del
							; conversor ADC
	movlw b'00000000' 		; Mueve el literal binario '00000000' al WREG
	movwf ADCON2			; ADCON2 maneja algunas configuraciones del
							; conversor analogo-digital
	bsf INTCON, PEIE		; Habilita las interrupciones de los perifericos
	bsf INTCON, GIE			; Habilita las interrupciones en el PIC
	bsf PIE1, ADIE			; Habilita las interrupciones del ADC
	bsf ADCON0, ADON 		; Habilita el conversor analogo-digital
	return					; Vuelve a la linea donde se llamo a la
							; funcion "config_proc"

; Aqui se inicia el programa principal
start						; Etiqueta "start"
	call config_proc		; Llama a la funcion "config_proc"
	bsf ADCON0, GO_DONE		; Inicia la conversion del dato

; Este loop se repite infinitamente esperando que ocurra la interrupcion
; dada por el termino de la conversion del conversor analogo-digital
loop						; Etiqueta "loop"
	goto loop				; Salta a la etiqueta "loop"

	end 					; Esta linea indica el termino del programa