/*  cd /mnt/e/MCU/stc/projects/hello-blink2/
    make clean NAME=hello-blink
    make build NAME=hello-blink

   // CPU clock 20MHz
   // 22Hz, Cycle 45ms (3 NOPs in inner loop)
   // 17Hz, Cycle 58ms (5 NOPs in inner loop)

   // CPU clock 27Mhz, blink 23Hz, cycle 43ms (5 NOPs) - doesnt work with battery
   // CPU clock 12MHz (11.059), blink 10Hz, cycle 98ms (5 NOPs)


*/

P0M0 EQU 94H
P0M1 EQU 93H

ORG 0000H
    LJMP MAIN

ORG 0100H
MAIN:
    ; P0.0 - quasi-bidirectional
    ; P0.1 to strong pull-output 
    ;      - up to 20mA (ex of connecting to a red led (Vf=2.5) + 1kOhm resistence, Takes 2.5mA I = (5V-2.5V)/1000Ohm = 2.5mA)
    ; P0.2 to input only (high impedance)
    MOV P0M0, #00000010B
    MOV P0M1, #00000100B
LOOP:
    CPL P0.0        ; Toggle LED pin
    ACALL DELAY     ; Wait
    ACALL DELAY     ; Wait one more
    SJMP LOOP       ; Repeat forever
DELAY:
    MOV R0, #255    ; Outer loop
D1: MOV R1, #255    ; Inner loop
D2: NOP               ; nops only for delay
    DJNZ R1, D2     ; Dec inner loop
    DJNZ R0, D1     ; Dec outer loop
    RET
END
