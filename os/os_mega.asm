
; Hardware Platform

BASE_SC114: equ 0
BASE_KEV: equ 1
BASE_CPM: equ 0

ENABLE_BASIC: equ 0

STARTUP_V1: equ 0
STARTUP_V2: equ 1

tos:	equ 0fffdh
;
;
; CPU clock
;
CPU_CLOCK_4MHZ: equ 1
CPU_CLOCK_8MHZ: equ  0
CPU_CLOCK_10MHZ: equ  0

; use microchip serial eeprom for storage

STORAGE_SE: equ 1
 
; now handled by SPI support
SOUND_ENABLE: equ 0   

; Number of bytes available in heap   TODO make all of user ram
baseram: equ 08000h
endofcode: equ 08000h
heap_start: equ 0800eh  ; Starting address of heap
free_list:  equ 0800ah      ; Block struct for start of free list (MUST be 4 bytes)

; Full OS but with the 5x10 fullsized keyboard

display_rows: equ 4    
;display_cols: equ 20
display_cols: equ 40

key_rows: equ 5     
key_cols: equ 10   

include "main.asm"
include "firmware_lcd_4x40.asm"
;include "firmware_lcd_4x20.asm"
include "firmware_key_5x10.asm"
;include "firmware_key_4x10.asm"

heap_size:    equ heap_end - heap_start
;eof
