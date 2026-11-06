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
	; switch all rows to high (will switch off all rows)
	ORL P0,#10010100b
	ORL P1,#11010011b
	

	
; Configure TIMER0 and enable it
	ORL    AUXR, #80H    ;1T Mode  (The clock source of Timer 0 is SYSclk/1)
	;ANL    AUXR, #7FH   ;12T Mode (The clock source of Timer 0 is SYSclk/12)
	MOV    TMOD, #00H    ; Datasheet page 435 Timer Mode (C/notT bit) (04h counter) CLR TMOD.3
	MOV    TL0, #LOW T0MS
	MOV    TH0, #HIGH T0MS
	SETB   TR0  ; Timer/Counter 0 Run Control bit.
	SETB   ET0  ; Enable Interrupt
	SETB   EA
	
	; global rowcounter for display row REFRESH 
	; IMPORTANT: Value should be changed ONLY by TIMER0_ROW_REFRESH_ISR )
	MOV R7,0 
	
	MOV R1, #0
	ACALL COPY_PICT_TO_VRAM ; initial image (absolute call within 2kb code-memory block)
	
	SETB P3.2;  bit 3.2 for push-button (Start-to-rotate) to high (button with a 1kOhm will bring to low)
	SETB P3.3;  bit 3.3 for push-button (switch image) to high 
MAIN: ; main loop
	JB P3.3, M2  ; jump if bit set (button not pressed!)
	; switch image (because button pressed!)
	CJNE R1, #65, N1 ; sets also the C(arry) as C=1 the first operand is smaller, C=0 the first operand is equal or greather ;(10pic - 2)*8 + 1
	N1: JC INC8
	MOV R1,#0
DISPLAY:
	ACALL COPY_PICT_TO_VRAM
	JNB P3.3, $ ; wait for P3.3 release (jump if bit not set)
	SJMP M2	
INC8:	
	MOV A,R1
	ADD A,#8
	MOV R1,A
	SJMP DISPLAY ; short relative jump (-128 to +128 bytes)
M2:
	JB P3.2, MAIN ; go to rotate only if P3.2 is low
	
	; rotate the eight byte in vram to left
	ROTATE:
	MOV R0, #0
	ROW_SHIFT:
	MOV DPTR, #VRAM_ADDR
	MOV DPL, R0
	MOVX A, @DPTR
	RL A
	MOVX @DPTR,A
	INC R0
	CJNE R0,#8,ROW_SHIFT
	
	; another delay to decrease rotation speed.
	MOV R3,#0FFh
	DELAY2: MOV B,#0FFh ; #0FFh
	DJNZ B, $  ; a loop for delay
	DJNZ R3, DELAY2

	SJMP MAIN

; ========== Procedures ===========
COPY_PICT_TO_VRAM:	
	; param R1 the code offset for picture
	; Copy the PICTURE_8x8 from CODE to a "VRAM" (MOVC -> A -> MOVX)
	PUSH 00h ; R0
	PUSH 01h ; R1
	MOV R0,#0 ; index from 0 - 7
	CPV_01:
	MOV A, R1
	MOV DPTR, #PICTURE_8x8
	MOVC A, @A+DPTR   ; from CODE to Accumulator
	MOV DPTR, #VRAM_ADDR
	MOV DPL, R0
	MOVX @DPTR, A  ; the Accumulator to VRAM
	INC R0
	INC R1
	CJNE R0, #08, CPV_01
	POP 01h ; R1
	POP 00h ; R0
	RET

TIMER0_ROW_REFRESH_ISR:	
	; --- Start the 'display refresh code ----
	; the display will be a fast row by row display 
	; in one loop only one row active
	; print the VRAM content to P0.0-8 and P1.0-8
	PUSH DPH
	PUSH DPL
	PUSH ACC
	MOV DPTR, #VRAM_ADDR
	; switch all rows to high (will switch off all rows)
	ORL P0,#10010100b
	ORL P1,#11010011b
	CJNE R7,#0,RW2
	CLR P0.7 ; row1 on
	SJMP CX
	RW2:	
    CJNE R7,#1,RW3
	CLR P0.2 ; row2
	SJMP CX
	RW3:CJNE R7,#2,RW4
	CLR P1.7; row3
	SJMP CX
	RW4:CJNE R7,#3,RW5
	CLR P0.4; row4
	SJMP CX
	RW5:CJNE R7,#4,RW6
	CLR P1.0; row5
	SJMP CX
	RW6:CJNE R7,#5,RW7
	CLR P1.6; row6
	SJMP CX
	RW7:CJNE R7,#6,RW8
	CLR P1.1; row7
	SJMP CX
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
	POP ACC
	POP DPL
	POP DPH
RETI
; --- ENDS 'display refresh code' ----


PICTURE_8x8: ; pictures saved in code, 
DB 001h, 002h, 004h, 008h, 010h, 020h, 040h, 080h ;1 a / slash
DB 03Ch, 042h, 081h, 081h, 081h, 081h, 042h, 03Ch ;2 a circle
DB 018h, 018h, 07Eh, 07Eh, 018h, 018h, 018h, 018h ;3 a cross
DB 010h, 028h, 044h, 082h, 041h, 022h, 014h, 008h ;4 rechtangle
DB 00Ch, 014h, 024h, 0C4h, 0C4h, 024h, 014h, 00Ch ;5 triangle
DB 000h, 000h, 020h, 041h, 0FEh, 041h, 020h, 000h ;6 arrow left
DB 000h, 000h, 004h, 082h, 07Fh, 082h, 004h, 000h ;7 arrow right
DB 010h, 038h, 054h, 010h, 010h, 010h, 010h, 028h ;8 arrow up
DB 028h, 010h, 010h, 010h, 010h, 054h, 038h, 010h ;9 arrow down
DB 03Ch, 042h, 0A5h, 081h, 0A5h, 099h, 042h, 03Ch ;10 smiley
	
END
