;
; Hardware Platform

BASE_SC114: equ 0
BASE_KEV: equ 1
BASE_CPM: equ 0

STARTUP_V1: equ 1
STARTUP_V2: equ 0

ENABLE_BASIC: equ 0
; CPU clock
;
CPU_CLOCK_4MHZ: equ 1
CPU_CLOCK_8MHZ: equ 0
CPU_CLOCK_10MHZ: equ 0

; use microchip serial eeprom for storage

STORAGE_SE: equ 1
SOUND_ENABLE: equ 0

tos:	equ 0fffdh
baseram: equ 08000h
endofcode: equ 08000h
heap_start: equ 0800eh  ; Starting address of heap
free_list:  equ 0800ah      ; Block struct for start of free list (MUST be 4 bytes)
heap_size: equ  heap_end-heap_start      ; Number of bytes available in heap   TODO make all of user ram


; Full OS but with the small 4x4 keypad

display_rows: equ 4     ; move out to mini and mega files
display_cols: equ 20

key_rows: equ 4     ; TODO move out to mini and mega
key_cols: equ 4    ; TODO move out to mini and mega

include "main.asm"
include "firmware_lcd_4x20.asm"
include "firmware_key_4x4.asm"
