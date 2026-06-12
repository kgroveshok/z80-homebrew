; Support for the DART serial chip. Might work with SIO(2) too.

Device_Dart: equ Device_A 

SIOA_D: equ    Device_Dart    ;SIO CHANNEL A DATA REGISTER
SIOA_C: equ    Device_Dart+2    ;SIO CHANNEL A CONTROL REGISTER
SIOB_D: equ    Device_Dart+1    ;SIO CHANNEL B DATA REGISTER
SIOB_C: equ    Device_Dart+3    ;SIO CHANNEL B CONTROL REGISTER

dart_init: 
; init Z80 SIO A
; Z80 SIO Register Mnemonics

; TODO CHANGEME
;;// initialize SIO port A CLK 1X 8N1

; TODO CHANGEME

        LD A,00H                ;REQUEST REGISTER #0
        OUT (SIOA_C),A
        LD A,18H                ;LOAD #0 WITH 18H - CHANNEL RESET
    	OUT (SIOA_C),A
;
        LD A,01H
        OUT (SIOA_C),A
        LD A,00H
    	OUT (SIOA_C),A
;
	    LD A,04H                ;REQUEST TRANSFER TO REGISTER #4
	    OUT (SIOA_C),A
        LD A,0C4H               ;WRITE #4 WITH X/0 CLOCK 1X STOP BIT
        OUT (SIOA_C),A          ;  AND NO PARITY
;
        LD A,03H                ;REQUEST TRANSFER TO REGISTER #3
        OUT (SIOA_C),A
        LD A,0C1H
        OUT (SIOA_C),A          ;WRITE #3 WITH COH - RECEIVER 8 BITS & RX ENABLE
;
        LD A,05H                ;REQUEST TRANSFER TO REGISTER #5
        OUT (SIOA_C),A
        LD A,068H
        OUT (SIOA_C),A          ;WRITE #5 WITH 60H - TRANSMIT 8 BITS & TX ENABLE

        ;SETUP PORT B
        LD A,00H                ;REQUEST REGISTER #0
        OUT (SIOB_C),A
        LD A,018H                ;LOAD #0 WITH 18H - CHANNEL RESET
	    OUT (SIOB_C),A
	ret

dart_send_byte: ret
dart_get_byte: ret




; eof

