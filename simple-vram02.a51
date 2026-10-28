/*
Simple 8x8 LED Matrix 1088AS Display Driver 
Assembly Intel8051 (C51)

The LED Matrix is connected directly to an MCU STC15F2K60S2
Pins P0.0-7 to 1088AS first 8 pins, and P1.0-7 to 1088AS pins 9-15
The Pins connected to COLS are protected with an 800Ohm Resistor

Display LED 8x8 pins 1388AS
  0, 1, 2, 3, 4, 5, 6, 7  ...  A, B, C, D, E, F, G, H
  C8,C7,R2,C1,R4,C6,C4,C7  ... R5,R7,C2,C3,R8,C5,R6,R3
 (die A... is printed at bottom..)
*/

; STC15F2K60S2 specifies 1,792 bytes of on-chip XRAM at 0000H–06FFH.	
VRAM_ADDR EQU 0600H; ; just some 16bit address in the OnChip internal RAM

; Register values from Datasheet
AUXR EQU 8Eh
P0M1 EQU 93h
P0M0 EQU 94h
P1M1 EQU 91h
P1M0 EQU 92h

; TIMER0 config see MCU Datasheet Page 436
; 1T mode, the timing value of 1ms is (65536-18432000/1000)
;12T mode, the timing value of 1ms is (65536-18432000/1000/12)
T0MS  EQU  05000H  ;the Timer will start counting up from this nr.  

ORG 0000h
    LJMP SETUP
	
ORG 000BH ; TIMER0 Interrupt entry in Datasheet
	LJMP TIMER0_ROW_REFRESH_ISR
	
ORG 0100h
SETUP:
	; After resert SP is 07H. set to 3Fh for: 
	; 1 To Protect the 4 Register Banks (00H - 1FH),
	; 2 To Protect Bit-Addressable RAM (20H - 2FH),
	; 3 To Maximize Scratchpad RAM (30H - 3FH)
    MOV SP, #3Fh
	
    ; configure  P0 and P1 cols and rows to strong push pull output "01" 
	MOV P0M1, #00000000b
	MOV P0M0, #11111111b
	MOV P1M1, #00000000b
	MOV P1M0, #11111111b
	
; Copy the PICTURE_8x8 from CODE to a "VRAM" (MOVC -> A -> MOVX)
	MOV R0, 0 ; byte nr for picture 1..8
COPY_PICT_TO_VRAM:	
	MOV A, R0
	MOV DPTR, #PICTURE_8x8
	MOVC A, @A+DPTR   ; from CODE to Accumulator
	MOV DPTR, #VRAM_ADDR
	MOV DPL, R0
	MOVX @DPTR, A  ; the Accumulator to VRAM
	INC R0
	CJNE R0, #08, COPY_PICT_TO_VRAM
	
; Configure TIMER0 and enable it
	ORL    AUXR, #80H    ;1T Mode  (The clock source of Timer 0 is SYSclk/1)
	;ANL    AUXR, #7FH   ;12T Mode (The clock source of Timer 0 is SYSclk/12)
	MOV    TMOD, #00H    ; Datasheet page 435 Timer Mode (C/notT bit) (04h counter) CLR TMOD.3
	MOV    TL0, #LOW T0MS
	MOV    TH0, #HIGH T0MS
	SETB   TR0  ; Timer/Counter 0 Run Control bit.
	SETB   ET0  ; Enable Interrupt
	SETB   EA
	
	; global rowcounter for display row REFRESH (value should be changed only by TIMER0_ROW_REFRESH_ISR )
	MOV R7,0 
	
; MAIN loop
	LJMP $

TIMER0_ROW_REFRESH_ISR:	
	; --- Start the 'display refresh code ----
	; the display will be a fast row by row display 
	; in one loop only one row active
	; print the VRAM content to P0.0-8 and P1.0-8
	MOV DPTR, #VRAM_ADDR
	; switch all rows to high (will switch off all rows)
	ORL P0,#10010100b
	ORL P1,#11010011b
	CJNE R7,#0,RW2
	CLR P0.7 ; row1 on
	LJMP CX
	RW2:	
    CJNE R7,#1,RW3
	CLR P0.2 ; row2
	LJMP CX
	RW3:CJNE R7,#2,RW4
	CLR P1.7; row3
	LJMP CX
	RW4:CJNE R7,#3,RW5
	CLR P0.4; row4
	LJMP CX
	RW5:CJNE R7,#4,RW6
	CLR P1.0; row5
	LJMP CX
	RW6:CJNE R7,#5,RW7
	CLR P1.6; row6
	LJMP CX
	RW7:CJNE R7,#6,RW8
	CLR P1.1; row7
	LJMP CX
	RW8:CLR P1.4; row 8
	CX:	
	MOV DPL, R7
	MOVX A, @DPTR
	COLS:
	MOV C, ACC.7; Copy the state of ACC.7 (1 or 0) into the Carry Flag
	MOV P0.3,C  ;  col1 (Copy the Carry Flag state directly into P0.3)
	MOV C, ACC.6
	MOV P1.2,C  ; col2
	MOV C, ACC.5
	MOV P1.3,C ; col3
	MOV C,ACC.4
	MOV P0.6,C ; col4
	MOV C,ACC.3
	MOV P1.5,C ; col5
	MOV C,ACC.2
	MOV P0.5,C  ; col6
	MOV C,ACC.1
	MOV P0.1,C ; col7
	MOV C, ACC.0
	MOV P0.0,C ; col8

 	INC R7
	CJNE R7,#08h, TO_RETI ; Compare R0 with 8. If NOT equal, leave the ISR
	MOV R7,#0 ; all row is refreshed - switch back to first row
	TO_RETI:
RETI
; --- ENDS 'display refresh code' ----


PICTURE_8x8:
DB 10101010b, 01010101b, 01100110b, 11010110b, 11110000b, 00100111b, 11100011b, 11111111b   

END
