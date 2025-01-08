; Hardware Platform

BASE_SC114: equ 1
BASE_KEV: equ 0

ENABLE_BASIC: equ 0
; Using SCM API instead
;SC114_SIO_1_OUT: equ 81
;SC114_SIO_1_IN: equ 80


tos:	equ 0f000h
;
; CPU clock
;
CPU_CLOCK_4MHZ: equ 1
CPU_CLOCK_8MHZ: equ 0
CPU_CLOCK_10MHZ: equ 0

; use microchip serial eeprom for storage

STORAGE_SE: equ 0
SOUND_ENABLE: equ 0

SC103_PIO: equ 068h
; Full OS but with the small 4x4 keypad

display_rows: equ 4     ; move out to mini and mega files
display_cols: equ 20

key_rows: equ 4     ; TODO move out to mini and mega
key_cols: equ 4    ; TODO move out to mini and mega

include "main.asm"
;include "firmware_lcd_4x20.asm"
;include "firmware_key_4x4.asm"
include "firmware_serial_display.asm"
include "firmware_key_serial.asm"

baseram: 
endofcode:
	nop

heap_start: equ baseram+15  ; Starting address of heap
free_list:  equ baseram+10      ; Block struct for start of free list (MUST be 4 bytes)
heap_size: equ  heap_end-heap_start      ; Number of bytes available in heap   TODO make all of user ram
;

