;========================================================
; STC15K2F60
; External Interrupt Skeleton Keil A51 assembler
;
; Buttons:
; INT0 -> P3.2
; INT1 -> P3.3
; INT2 -> P3.0
; INT3 -> P3.6
; INT4 -> P3.7
;
; Active LOW (button connects pin to GND)
;========================================================

$NOMOD51
$INCLUDE (STC15.H)

;========================================================
; Interrupt Vector Table
;========================================================

            ORG     0000H
            LJMP    START

; INT0
            ORG     0003H
            LJMP    INT0_ISR

; INT1
            ORG     0013H
            LJMP    INT1_ISR

; INT2
            ORG     004BH
            LJMP    INT2_ISR

; INT3
            ORG     0053H
            LJMP    INT3_ISR

; INT4
            ORG     005BH
            LJMP    INT4_ISR


;========================================================
; Main program
;========================================================

            ORG     0100H

START:
            MOV     SP, #60H

            ; Configure external interrupts
            ; Falling edge triggered

            SETB    IT0         ; INT0 falling edge
            SETB    IT1         ; INT1 falling edge

            ; Enable external interrupts
            SETB    EX0
            SETB    EX1
            SETB    EX2
            SETB    EX3
            SETB    EX4

            ; Global interrupt enable
            SETB    EA

MAIN_LOOP:
            NOP
            SJMP    MAIN_LOOP


;========================================================
; INT0 - P3.2
;========================================================

INT0_ISR:
            NOP
            RETI


;========================================================
; INT1 - P3.3
;========================================================

INT1_ISR:
            NOP
            RETI


;========================================================
; INT2 - P3.0
;========================================================

INT2_ISR:
            NOP
            RETI


;========================================================
; INT3 - P3.6
;========================================================

INT3_ISR:
            NOP
            RETI


;========================================================
; INT4 - P3.7
;========================================================

INT4_ISR:
            NOP
            RETI


END