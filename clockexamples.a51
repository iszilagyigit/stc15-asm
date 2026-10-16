/*
Clock and Timing input examples
Datasheet - Page 206-208 

P5.4 MCLCK/4 Output 20MHz/4 = 5MHz
P3.5 (Pin 26) Output 14KHz
*/

CLK_DIV  EQU 097h ; Datasheet §2.1.3.1 page 206 
INT_CLK0 EQU 08Fh ; Datasheet page 207
	AUXR EQU 08Eh ; 


F14KHZ EQU 0FCA5h ; hex(int(0xFFFF - 24_000_000/2/14000)) by 24MHz CPU
	
F38_4KHz EQU 0FF10h //38.4KHz(1T mode, 65536-18432000/2/38400) by 18MHZ CPU
//F38_4KHz EQU 0FFECH ////38.4KHz(12T mode,(65536-18432000/2/12/38400)

ORG 0000h
    LJMP SETUP
	
ORG 0100H ; skipping from 00 to FF (first 256 bytes - mainly are SFRs or Interrupt handle code)
SETUP:

	MOV CLK_DIV,  #11000000b 
	; 11 - MCLK/4 output on MCLKO P5.4 (pint 17)
	MOV INT_CLK0, #00000111b 
		;  P3.5/T1 configured for Timer 0(T0) T0_CLK0
		;  P3.4/T0 configured for Timer 1(T1) T1_CLK0
		;  P3.0/T2 configured for Timer 2(T2) T2_CLK0
		
	ORL    AUXR, #10000000b ;Timer 0 in 1T mode
	MOV    TMOD, #00H ;set Timer0 in mode 0 (16 bit auto-reloadable mode)
	ANL    TMOD, #11111011b ;C/T0=0, count on internal system clock
	MOV   TL0, #LOW F14KHz //Initial timing value
	MOV   TH0, #HIGH F14KHz
	SETB  TR0
	; In P3.5 (Pin 26)
	; By 24MHZ CPU: TR0 - 14KHz, 50% Duty, Cycle:70us (0.070ms)
	
MAIN_LOOP:
	NOP
	LJMP MAIN_LOOP
	
END
