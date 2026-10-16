

ORG 0000h
    LJMP LMATRIX_1388A
	
	
ORG 0100h
	
LMATRIX_1388A:
	MOV P0,#0
	MOV P1,#0
	
	; print the VRAM content to P0.0-8 and P1.0-8
	MOV DPTR, #VRAM_DATA
	CLR A
	MOVC A, @A+DPTR

	MOV R0,#8
PRINT_RAWS:
	MOV R1,#8
PRINT_COLLS:
	CLR C ; clear the carry
	RRC A ; rotate right throu carry, bit 0 -> C
	JC LEDON
CONT:	
	DJNZ R1, PRINT_COLLS
	DJNZ R0, PRINT_RAWS
	LJMP MAIN_LOOP
	
LEDON:
	NOP
	; switch on the LED at position R0 (row 1-8) and R1 (col 1-8)
	; dont change the values of the acculmulator and R0, R1
	LJMP CONT


MAIN_LOOP:
	NOP
	LJMP MAIN_LOOP


VRAM_DATA:
DB 01h, 02h, 03h, 04h, 05h, 06h, 07h, 08h
   
END
	
	