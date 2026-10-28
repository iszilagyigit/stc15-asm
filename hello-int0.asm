/*
 P0.1 should switch on or off, reacting to INT0 interrupt with a button.

 Datasheet reference:
 Interrupts - Chapter 6
 Power Management - Chapter 2.3

 Version 1 - Main loop in NOPs   : 10mA when light is on, 8mA when light is off (CPU by endless loop)
 Version 2 - Main loop in PD mode:  2mA when light is on, 0mA by power down mode
*/

;SFR Register addresses

P0M0 EQU 94h ;constant (text substitution)
P0M1 EQU 93h ;constant (text substitution)

; (already defined) PCON EQU 87h ; Power Control Register Address. (non bit settable)
; (already defined) IE EQU A8H ; page 392 - 00h value is after reset

ORG 0000h
    LJMP SETUP

ORG 0003h ; External Interrupt0
    LJMP EXTINT0

; After resert SP is 07H. set to 3Fh for: 
; 1 To Protect the 4 Register Banks (00H - 1FH),
; 2 To Protect Bit-Addressable RAM (20H - 2FH),
; 3 To Maximize Scratchpad RAM (30H - 3FH)

ORG 0100H ; skipping from 00 to FF (first 256 bytes - mainly are SFRs or Interrupt handle code)
SETUP:
    MOV SP, #3Fh 
    ; P0.1 to strong pull-output 
    ;      - up to 20mA (ex of connecting to a red led (Vf=2.5) + 1kOhm resistence, Takes 2.5mA I = (5V-2.5V)/1000Ohm = 2.5mA)
    MOV P0M0, #00000010b
    MOV P0M1, #00000000b

    ; enable global interrupts IE and enable INT0 (External Interrupt 0  IT0 = 0: both rising and falling edges)
    ;SETB EX0 ; IE.0
    ;SETB EA  ; IE.7 EA (enable interrupt) -  SETB -> Set Bit
    ORL IE,#10000001b ; Logical OR accumulator with immediate data to accumulator (Direct-Address-Destination Style where accumulator is bypassed!)
    SETB IT0 ; Setting INT0 interrupt type  - Falling only TCON.0

; Variant 1, Endless loop
;MAIN_LOOP:
;	NOP
;	LJMP MAIN_LOOP

; Variant 2 - main loop in PowerDown (PD mode): Datasheet Chapter 2.3
POWER_DOWN: 
    ORL PCON, #00000010b ; Power Down (bit 1 in PCON register)
	NOP
	
	; Execution is resumed here after the ISR..
	NOP
	NOP
    LJMP POWER_DOWN; go and Power Down again
    

EXTINT0:
    CPL P0.1 ; Led On/Off (CPL = Complement Accumulator (ex accumulator had 01011100b after CPL gets 10100011b))
WAIT_INTO_HIGH:
	NOP
	JNB P3.2, WAIT_INTO_HIGH; loop until INT0 pin goes high again
    RETI

END


