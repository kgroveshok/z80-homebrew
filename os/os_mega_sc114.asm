
; Hardware Platform

BASE_SC114: equ 1
BASE_KEV: equ 0
BASE_CPM: equ 0

ENABLE_BASIC: equ 0

STARTUP_V1: equ 1
STARTUP_V2: equ 0

tos:	equ 0f000h
; Using SCM API instead
;SC114_SIO_1_OUT: equ 81
;SC114_SIO_1_IN: equ 80
;
;
; CPU clock
;
CPU_CLOCK_4MHZ: equ 1
CPU_CLOCK_8MHZ: equ  0
CPU_CLOCK_10MHZ: equ  0

; use microchip serial eeprom for storage

STORAGE_SE: equ 0
SOUND_ENABLE: equ 0

; the port where the PIO using the SC103 card is located

SC103_PIO: equ 068h

; Full OS but with the 5x10 fullsized keyboard

display_rows: equ 4    
;display_cols: equ 20
display_cols: equ 40

key_rows: equ 5     
key_cols: equ 10   


include "main.asm"
;include "firmware_lcd_4x40.asm"
;;include "firmware_lcd_4x20.asm"
include "firmware_serial_display.asm"
;include "firmware_key_5x10.asm"
;;include "firmware_key_4x10.asm"
include "firmware_key_serial.asm"
endofcode: 
baseram: 
	nop

heap_start: equ baseram+15  ; Starting address of heap
free_list:  equ baseram+10      ; Block struct for start of free list (MUST be 4 bytes)
heap_size: equ  heap_end-heap_start      ; Number of bytes available in heap   TODO make all of user ram
;VDU:  EQU     endofcode           ; BASIC Work space
; eof

