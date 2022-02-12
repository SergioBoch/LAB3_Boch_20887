; Archivo: Laboratorio 3.s
; Dispositivo: PIC16F887
; Autor: Sergio Boch
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: Contador hexadecimal de 4 bits
;
; Creado: 7 feb, 2022
; Última modificación: 12, 2022
    
    PROCESSOR 16F887
    #include <xc.inc>
    
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
  PSECT udata_bank0
  BANDERA: DS 1		; 1 Byte
  COUNTER: DS 1		; Contador de un bit
    
;--------------------Vector de Reseteo-----------------------------------
PSECT resVect, class=code, abs, delta=2
  ORG 00h				    ; posición del vector de reseteo
  resVect:
    PAGESEL main
    goto main
    
  PSECT code, delta=2, abs
  ORG 0100H

;----------------------Configuración---------------------------------------
main:
    banksel ANSEL	    ;Ir al registro donde se encuentra ANSEL
    clrf ANSEL
    clrf ANSELH
    
    banksel TRISA   ; Ir al banco donde se encuentra TRISA
    BSF TRISA, 0    ; Configuración de pines digitales
    BSF TRISA, 1    ; Puerto B configuradon como digital
    BCF TRISA, 3	; Salidas
    CLRF TRISB	    ; Limpia el valor inicial en los puertos
    CLRF TRISC
    CLRF TRISD
    
    banksel PORTA   ; Ir al banco donde se encuentra el PORTA
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC
    CLRF PORTD
    
    
    CLRWDT		    ;Limpia el watchdog timer
    banksel OPTION_REG	    
    MOVLW 11010000B	    ;
    ANDWF OPTION_REG, W
    IORLW 00000100B
    MOVWF OPTION_REG
    
    banksel OSCCON	    ; Configurando el oscilador
    BSF OSCCON, 4	    ; Configurando la frecuencia a 8MHz
    BSF OSCCON, 5
    BSF OSCCON, 6
    BSF SCS
    
    call TIMER		    ; Llamar a la subrutina TIMER
    
    LOOP:
    
    BTFSC PORTA, 0	    ; Verificación de los estados de los botones
    CALL ANTIRREBOTE
    BTFSS PORTA, 0
    CALL INCC
    BTFSC PORTA, 1
    CALL ANTIRREBOTE2
    BTFSS PORTA, 1
    CALL DECC
    
    ;-----------Inicia el contador con TIMER-----------------------------
    BTFSS INTCON, 2	   ; Verificando la bandera del INTCON
    GOTO $-1
    CALL TIMER		
    MOVLW 250		    ; Le ingresan 250 al registro W
    SUBWF COUNTER, 0	    ; Lo ingresado se le suma a la variable CONTADOR
    BTFSC STATUS, 2	    ; Realiza la siguiente acción, llama a las subrutinas
    CALL TEMPORIZADOR
    CALL INC_CONTADOR
    
    ;-------------Indicador-----------------------------------------------
    MOVF PORTB, W	  ; Toma el valor del puerto B 
    SUBWF PORTC, 0	   ; Resta el valor de B en C
    BTFSC STATUS, 2	   ; Ejecuta la siguiente acción
    CALL INDICADOR	   ; Llama a la subrutina INDICADOR
    GOTO LOOP
    
    TIMER:	    
    banksel TMR0	    ; Subrutina de timer
    MOVLW 131		    ; Cargando el valor de N calculado con la ecuación
    MOVF TMR0		    ; El timer 0 va a contar 10
    BCF INTCON, 2	    
    RETURN
    
    TEMPORIZADOR:
    INCF PORTB, F	    ; Incrementar el puerto B
    BTFSC PORTB, 4	    ; Va a verificar que no exceda 4 bits
    CLRF PORTB		    ; Limpia el puerto B
    BCF STATUS, 2
    RETURN
    
    INC_CONTADOR:	    ; Subrutina de incremento
    INCF COUNTER
    BCF INTCON, 2
    RETURN
    
    ANTIRREBOTE:	    ; Subrutina del antirrebote
    BSF BANDERA, 0
    RETURN
    
    INCC:		    ; Subrutina de incremento en puerto C
    BTFSS BANDERA, 0
    RETURN
    INCF PORTC, F
    BTFSC PORTC, 4
    CLRF PORTC
    CLRF BANDERA
    RETURN
    
    ANTIRREBOTE2:	    ; Subrutina de antirrebote
    BSF BANDERA, 1
    RETURN
    
    DECC:		    ; Subrutina de decremento en C
    BTFSS BANDERA, 1
    RETURN
    DECF PORTC, F
    MOVLW 0x0F
    BTFSC PORTC, 4
    MOVWF PORTC
    CLRF BANDERA 
    RETURN
	
    INDICADOR:		    ; 
    MOVLW 0x08		    ; Tomar el valor del 4 bit en el registro
    XORWF PORTA, F	    ; Variar la salida de A
    CLRF PORTB		    ; Limpiar el puerto B
    BCF STATUS, 2
    RETURN
    
    END
