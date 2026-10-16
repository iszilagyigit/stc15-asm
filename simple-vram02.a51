P0M1 EQU 93h
P0M0 EQU 94h
P1M1 EQU 91h
P1M0 EQU 92h

;Display LED 8x8 pins 1388AS
;  0, 1, 2, 3, 4, 5, 6, 7  ...  A, B, C, D, E, F, G, H
; C8,C7,R2,C1,R4,C6,C4,C7  ... R5,R7,C2,C3,R8,C5,R6,R3
; (die A... is die untere Seite...)

ORG 0000h
    LJMP LMATRIX_1388A
	
ORG 0100h
LMATRIX_1388A:
    ; configure cols to strong push pull output "01" 
    ; and raws to open drain "11" 
	MOV P0M1, #10010100b
	MOV P0M0, #11111111b
	MOV P1M1, #11010011b
	MOV P1M0, #11111111b
	
	; switch all leds on
	MOV P0,#01101011b
	MOV P1,#00101100b

; ungefähr 1 sec bei 20MHz Tackt
DELAY1S:
	MOV R0,#03Fh
INNERLOOP1:
	MOV R1,#0FFh
INNERLOOP2:
	MOV B,#0FFh
	DJNZ B, $  ; a loop for delay
	DJNZ R1, INNERLOOP2
	DJNZ R0, INNERLOOP1
	
	;-- switch off the rows by setting the pins high
	;ORL P0,#10010100b 
	;ORL P1,#11010011b
	
	;CPL P0 and P1 (to switch on/off all leds
	MOV A, P0
	CPL A
	MOV P0, A
	MOV A, P1
	CPL A
	MOV P1, A
	LJMP DELAY1S
	
	; print the VRAM content to P0.0-8 and P1.0-8
	MOV DPTR, #VRAM_DATA
	
	CLR A
	MOVC A, @A+DPTR  ; MOVC  Move Code!
	/*
ROW1:
	SETB P1.3 ; first row!
COL01:
	JNB ACC.7, COL02 ; Jump of bit not set (Accumulator A) bit 7
	SETB P0.5 ; col1
COL02:
	JNB ACC.6, COL03
	SETB P0.1 ; col2
COL03:
	JNB ACC.5, COL04
	SETB P0.7 ; col3
COL04:
	JNB ACC.4, COL05
	SETB P0.0 ; col4
COL05:
	JNB ACC.3, COL06
	SETB P1.4 ; col5
COL06:
	JNB ACC.2, COL07
	SETB P0.7  ; col6
COL07:
	JNB ACC.1, COL08
	SETB P1.2 ;  col7
COL08:
	JNB ACC.0, ROW2
	SETB P1.7 ;  col8

ROW2:
 	MOV A,#1
	MOVC A, @A+DPTR
	
	SETB P0.2 ; 2nd row
 */
MAIN_LOOP:
	NOP
	LJMP MAIN_LOOP

VRAM_DATA:
DB 10101010b, 02h, 03h, 04h, 05h, 06h, 07h, 08h   
END
	
	