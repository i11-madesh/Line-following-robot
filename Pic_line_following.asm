LIST P=18F452
        #include <p18f452.inc>

        CONFIG OSC = HS
        CONFIG WDT = OFF
        CONFIG LVP = OFF
        CONFIG DEBUG = OFF

; =========================================
; PIC18F452 - SLOW LINE FOLLOWER
; 3 IR Sensors + L298N
; 20 MHz oscillator
;
; RB0 = LEFT IR
; RB1 = CENTER IR
; RB2 = RIGHT IR
;
; RD0 = IN1 (LEFT motor)
; RD1 = IN2
; RD2 = IN3 (RIGHT motor)
; RD3 = IN4
;
; RC2 = ENA
; RC1 = ENB
;
; BLACK = LOW (0)
; WHITE = HIGH (1)
; =========================================

FORWARD_SPEED EQU D'125'
INNER_SPEED   EQU D'90'
OUTER_SPEED   EQU D'145'
SEARCH_SPEED  EQU D'110'

SENSOR        EQU 0x20
LAST_DIR      EQU 0x21
LEFT_SPEED    EQU 0x22
RIGHT_SPEED   EQU 0x23
PWM_COUNT     EQU 0x24
TEMP          EQU 0x25

; LAST_DIR:
; 0 = CENTER
; 1 = LEFT
; 2 = RIGHT

        ORG 0x0000
        GOTO START

; =========================================
; INITIALIZATION
; =========================================

START:
        MOVLW 0x07
        MOVWF ADCON1, ACCESS

        ; RB0 RB1 RB2 are inputs
        MOVLW B'11111111'
        MOVWF TRISB, ACCESS

        ; Motor direction pins
        CLRF LATD, ACCESS
        CLRF TRISD, ACCESS

        ; Motor enable pins
        CLRF LATC, ACCESS
        CLRF TRISC, ACCESS

        CLRF LAST_DIR, ACCESS
        CLRF LEFT_SPEED, ACCESS
        CLRF RIGHT_SPEED, ACCESS

; =========================================
; READ IR SENSORS
; =========================================

MAIN:
        MOVF PORTB, W, ACCESS
        ANDLW B'00000111'
        MOVWF SENSOR, ACCESS

; Raw sensor order is RB2 RB1 RB0
; i.e. RIGHT CENTER LEFT

; -----------------------------------------
; Center BLACK, sides WHITE
; L=1 C=0 R=1 -> 101
; FORWARD
; -----------------------------------------

        MOVF SENSOR, W, ACCESS
        XORLW B'00000101'
        BZ GO_FORWARD

; -----------------------------------------
; LEFT + CENTER BLACK
; L=0 C=0 R=1 -> 100
; LEFT TURN
; -----------------------------------------

        MOVF SENSOR, W, ACCESS
        XORLW B'00000100'
        BZ GO_LEFT

; -----------------------------------------
; LEFT BLACK ONLY
; L=0 C=1 R=1 -> 110
; LEFT TURN
; -----------------------------------------

        MOVF SENSOR, W, ACCESS
        XORLW B'00000110'
        BZ GO_LEFT

; -----------------------------------------
; CENTER + RIGHT BLACK
; L=1 C=0 R=0 -> 001
; RIGHT TURN
; -----------------------------------------

        MOVF SENSOR, W, ACCESS
        XORLW B'00000001'
        BZ GO_RIGHT

; -----------------------------------------
; RIGHT BLACK ONLY
; L=1 C=1 R=0 -> 011
; RIGHT TURN
; -----------------------------------------

        MOVF SENSOR, W, ACCESS
        XORLW B'00000011'
        BZ GO_RIGHT

; -----------------------------------------
; ALL BLACK -> 000
; FORWARD
; -----------------------------------------

        MOVF SENSOR, W, ACCESS
        XORLW B'00000000'
        BZ GO_FORWARD

; -----------------------------------------
; LEFT + RIGHT BLACK, CENTER WHITE
; 010 -> FORWARD
; Keep previous direction memory
; -----------------------------------------

        MOVF SENSOR, W, ACCESS
        XORLW B'00000010'
        BZ GO_FORWARD_KEEP

; -----------------------------------------
; ALL WHITE -> 111
; RECOVERY
; -----------------------------------------

        GOTO RECOVER_LINE

; =========================================
; FORWARD
; Both motors forward
; =========================================

GO_FORWARD:
        CLRF LAST_DIR, ACCESS

GO_FORWARD_KEEP:
        MOVLW B'00000101'
        MOVWF LATD, ACCESS

        MOVLW FORWARD_SPEED
        MOVWF LEFT_SPEED, ACCESS
        MOVWF RIGHT_SPEED, ACCESS

        CALL PWM_FRAME
        GOTO MAIN

; =========================================
; GENTLE LEFT
; Left motor slower
; Right motor faster
; =========================================

GO_LEFT:
        MOVLW D'1'
        MOVWF LAST_DIR, ACCESS

        ; Both motors forward
        MOVLW B'00000101'
        MOVWF LATD, ACCESS

        MOVLW INNER_SPEED
        MOVWF LEFT_SPEED, ACCESS

        MOVLW OUTER_SPEED
        MOVWF RIGHT_SPEED, ACCESS

        CALL PWM_FRAME
        GOTO MAIN

; =========================================
; GENTLE RIGHT
; Left motor faster
; Right motor slower
; =========================================

GO_RIGHT:
        MOVLW D'2'
        MOVWF LAST_DIR, ACCESS

        ; Both motors forward
        MOVLW B'00000101'
        MOVWF LATD, ACCESS

        MOVLW OUTER_SPEED
        MOVWF LEFT_SPEED, ACCESS

        MOVLW INNER_SPEED
        MOVWF RIGHT_SPEED, ACCESS

        CALL PWM_FRAME
        GOTO MAIN

; =========================================
; LOST LINE RECOVERY
; =========================================

RECOVER_LINE:
        MOVF LAST_DIR, W, ACCESS
        XORLW D'1'
        BZ RECOVER_LEFT

        MOVF LAST_DIR, W, ACCESS
        XORLW D'2'
        BZ RECOVER_RIGHT

        ; No direction remembered
        ; Move forward slowly
        MOVLW B'00000101'
        MOVWF LATD, ACCESS
        GOTO RECOVER_SPEED

RECOVER_LEFT:
        ; Left motor reverse
        ; Right motor forward
        MOVLW B'00000110'
        MOVWF LATD, ACCESS
        GOTO RECOVER_SPEED

RECOVER_RIGHT:
        ; Left motor forward
        ; Right motor reverse
        MOVLW B'00001001'
        MOVWF LATD, ACCESS

RECOVER_SPEED:
        MOVLW SEARCH_SPEED
        MOVWF LEFT_SPEED, ACCESS
        MOVWF RIGHT_SPEED, ACCESS

        CALL PWM_FRAME
        GOTO MAIN

; =========================================
; SOFTWARE PWM
; 256 STEPS
; RC2 = LEFT ENABLE
; RC1 = RIGHT ENABLE
; =========================================

PWM_FRAME:
        CLRF PWM_COUNT, ACCESS

PWM_LOOP:
        ; LEFT MOTOR PWM
        MOVF PWM_COUNT, W, ACCESS
        CPFSGT LEFT_SPEED, ACCESS
        GOTO LEFT_OFF

        BSF LATC, 2, ACCESS
        GOTO CHECK_RIGHT

LEFT_OFF:
        BCF LATC, 2, ACCESS

CHECK_RIGHT:
        ; RIGHT MOTOR PWM
        MOVF PWM_COUNT, W, ACCESS
        CPFSGT RIGHT_SPEED, ACCESS
        GOTO RIGHT_OFF

        BSF LATC, 1, ACCESS
        GOTO PWM_DELAY

RIGHT_OFF:
        BCF LATC, 1, ACCESS

PWM_DELAY:
        MOVLW D'10'
        MOVWF TEMP, ACCESS

WAIT_LOOP:
        DECFSZ TEMP, F, ACCESS
        GOTO WAIT_LOOP

        INCF PWM_COUNT, F, ACCESS

        ; End frame when 255 wraps to 0
        MOVF PWM_COUNT, F, ACCESS
        BNZ PWM_LOOP

        RETURN

        END