; Button 1 : P3.2 -> INT0
; Button 2 : P3.0 -> INT4
; Button 3 : P3.6 -> INT2
; Button 4 : P3.3 -> INT1
; Button 5 : P3.7 -> INT3
;
; Active LOW: Button connects input to GND (Trigger: Falling edge)

; STC15F2K60S2 specifies 1,792 bytes of on-chip XRAM at 0000H–06FFH.	
VRAM_ADDR EQU 0600H; ; just some 16bit address in the OnChip internal RAM

; SFR DEFINITIONS
;already defined P3          DATA    0B0H
;already defined IE          DATA    0A8H
;already defined TCON        DATA    088H
P4 DATA 0C0h

AUXR	DATA	08EH
AUXR2   DATA    08FH
; Interrupt Enable Register IE
;already defined EX0         BIT     0A8H
;already defined EX1         BIT     0AAH
;already defined EA          BIT     0AFH
; Timer Control Register TCON
;already defined IT0         BIT     088H
;already defined IT1         BIT     08AH

; TIMER0 config see MCU Datasheet Page 436
; 1T mode, the timing value of 1ms is (65536-18432000/1000) by 18MHz
;12T mode, the timing value of 1ms is (65536-18432000/1000/12)
T0MS  EQU  05000H  ;the Timer will start counting up from this nr.  

; ================================================================
ORG     0000H 
LJMP    START
ORG     0003H
LJMP    INT0_ISR
ORG 000BH ; TIMER0 Interrupt entry in Datasheet
LJMP TIMER0_ROW_REFRESH_ISR
ORG     0013H
LJMP    INT1_ISR
ORG     0053H
LJMP    INT2_ISR
ORG     005BH
LJMP    INT3_ISR
ORG     0083H
LJMP    INT4_ISR
;========================================================
; MAIN PROGRAM
;========================================================
ORG     0100H

START:
MOV     SP,#60H

; Configure all five button pins as inputs Quasi-bidir input: write logic 1
SETB    P3.2
SETB    P3.0
SETB    P3.6
SETB    P3.3
SETB    P3.7

; INT0 and INT1: falling-edge triggered IT0 = 1; IT1 = 1
;--------------------------------------------------------
SETB    IT0
SETB    IT1

; Enable INT0 and INT1
SETB    EX0
SETB    EX1

;--------------------------------------------------------
; Enable INT2, INT3 and INT4
; AUXR2 = 8FH
;
; Bit 6 = EX4; Bit 5 = EX3; Bit 4 = EX2
; Set bits 4, 5 and 6
;--------------------------------------------------------
MOV     A,AUXR2
ORL     A,#070H
MOV     AUXR2,A

;--------------------------------------------------------
; Configure TIMER0 and enable it
;--------------------------------------------------------
ORL    AUXR, #80H    ;1T Mode  (The clock source of Timer 0 is SYSclk/1)
;ANL    AUXR, #7FH   ;12T Mode (The clock source of Timer 0 is SYSclk/12)
MOV    TMOD, #00H    ; Datasheet page 435 Timer Mode (C/notT bit) (04h counter) CLR TMOD.3
MOV    TL0, #LOW T0MS
MOV    TH0, #HIGH T0MS
SETB   TR0  ; Timer/Counter 0 Run Control bit.
SETB   ET0  ; Enable Timer 0 Interrupt

; global rowcounter for display row REFRESH 
; IMPORTANT: Value should be changed ONLY by TIMER0_ROW_REFRESH_ISR )
MOV R7,0 
	
	
;--------------------------------------------------------
; Display Digits configuration
;--------------------------------------------------------
CLR  P4.2  ; first digit from right
CLR  P2.5  ; second digit
CLR  P2.3  ; third digit
SETB P4.1
SETB P2.4
SETB P2.1
SETB P2.0
SETB P4.4
SETB P2.2
SETB P1.4

;--------------------------------------------------------
; Display 16x8 matrix configuration
;--------------------------------------------------------
CLR P2.6 ;row0 (CLR to switch off)
CLR P4.5 ;row1
CLR P0.4 ;row2
CLR P2.7 ;row3
CLR P0.0 ;row4
CLR P0.3 ;row5
CLR P0.1 ;row6
CLR P0.2 ;row7

CLR P0.5 ;row8
CLR P0.7 ;row9
CLR P1.3 ;row10
CLR P0.6 ;row11
CLR P1.0 ;row12
CLR P1.2 ;row13
CLR P1.1 ;row14
CLR P1.6 ;row15
; switch all columns high - switch all off
ORL P1, #00110000b ;P1.4, P1.5 high
ORL P2, #00010111b ;P2.0, P2.1,P2.2,P2.4 high
ORL P4, #00010010b ;P4.1, P4.4 high 


;========================================================
; OTHER SETUP CODE
;========================================================

MOV R1, #0
ACALL COPY_PICT_TO_VRAM ; initial image (absolute call within 2kb code-memory block)

; Global interrupt enable
SETB    EA

;========================================================
; MAIN LOOP
;========================================================
MAIN_LOOP:
NOP
SJMP    MAIN_LOOP

; ========== Procedures ===========
COPY_PICT_TO_VRAM:	
	; param R1 the code offset for picture
	; Copy the PICTURE_8x8 from CODE to a "VRAM" (MOVC -> A -> MOVX)
	PUSH 00h ; R0
	PUSH 01h ; R1
	MOV R0,#0 ; index from 0 - 15
	CPV_01:
	MOV A, R1
	MOV DPTR, #PICTURES
	MOVC A, @A+DPTR   ; from CODE to Accumulator
	MOV DPTR, #VRAM_ADDR
	MOV DPL, R0
	MOVX @DPTR, A  ; the Accumulator to VRAM
	INC R0
	INC R1
	CJNE R0, #16, CPV_01
	POP 01h ; R1
	POP 00h ; R0
	RET



PICTURES:
DB 001h, 002h, 004h, 008h, 010h, 020h, 040h, 080h, 080h, 040h, 020h, 010h, 008h, 004h, 002h, 001h


;========================================================
; INTERRUPT SERVICE ROUTINES
;========================================================

;--------------------------------------------------------
; TIMER0 Display Refresh
;--------------------------------------------------------
TIMER0_ROW_REFRESH_ISR:	
	; --- Start the 'display refresh code ----
	; the display will be a fast col by col display ("column scan")
	; in one loop only one column active
	; print the VRAM content
	PUSH DPH
	PUSH DPL
	PUSH ACC
	MOV DPTR, #VRAM_ADDR

	; switch all columns high - switch all off
	ORL P1, #00110000b ;P1.4, P1.5 high
	ORL P2, #00010111b ;P2.0, P2.1,P2.2,P2.4 high
	ORL P4, #00010010b ;P4.1, P4.4 high 
	
	CJNE R7,#0,COL2
	CLR P1.5 ; col1 on
	SJMP CX
	COL2:CJNE R7,#1,COL3
	CLR P4.1 ;col2 on
	SJMP CX
	COL3:CJNE R7,#2,COL4
	CLR P2.2 ;col3 on
	SJMP CX
	COL4:CJNE R7,#3,COL5
	CLR P1.4
	SJMP CX
	COL5:CJNE R7,#4,COL6
	CLR P2.1
	SJMP CX
	COL6:CJNE R7,#5,COL7
	CLR P4.4
	SJMP CX
	COL7:CJNE R7,#6,COL8
	CLR P2.0
	SJMP CX
	COL8:CLR P2.4
	CX:
	; loop mit R6 from 0 to 15
	;MOV R6,#0
	;MOV DPL, R6
	;MOVX A, @DPTR
	
	SETB P2.6 ; row 1 on
	SETB P4.5 ; row 2 on
	SETB P0.4 ; row 3 on
	SETB P2.7 ; row 4 on
	SETB P0.0 ; row 5 on
	SETB P0.3 ; row 6 on
	SETB P0.1 ; row 7 on
	SETB P0.2 ; row 8 on
	
	SETB P0.5 ; row 9 on
	SETB P0.7 ; row 10 on
	SETB P1.3 ; row 11 on
	SETB P0.6 ; row 12 on
	SETB P1.0 ; row 13 on
	SETB P1.2 ; row 14 on
	SETB P1.1 ; row 15 on
	SETB P1.6 ; row 16 on
	
	INC R7
	CJNE R7,#08h, TO_RETI ; 
	MOV R7,#0
	TO_RETI:
	POP ACC
	POP DPL
	POP DPH
RETI	


;--------------------------------------------------------
; BUTTON 1 - P3.2 - INT0
;--------------------------------------------------------
INT0_ISR:
SETB P2.3
NOP
RETI

;--------------------------------------------------------
; BUTTON 4 - P3.3 - INT1
;--------------------------------------------------------
INT1_ISR:
CLR P2.3
NOP
RETI

;--------------------------------------------------------
; BUTTON 3 - P3.6 - INT2
;--------------------------------------------------------
INT2_ISR:
SETB P2.6 ;row0,col0 set
CLR  P2.4 ;row0,col0 set
SETB P4.5 ;row1,col1 set
CLR  P2.0 ;row1,col1 set
SETB P0.4
CLR  P4.4
NOP
RETI

;--------------------------------------------------------
; BUTTON 5 - P3.7 - INT3
;--------------------------------------------------------
INT3_ISR:
NOP
RETI

;--------------------------------------------------------
; BUTTON 2 - P3.0 - INT4
;--------------------------------------------------------
INT4_ISR:
CLR  P2.6  ;row0,col0 clear
SETB P2.4 ;row0,col0 clear
CLR  P4.5
SETB P2.0
CLR  P0.4
SETB P4.4
NOP
RETI

END
