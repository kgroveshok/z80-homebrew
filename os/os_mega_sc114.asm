
; Hardware Platform

BASE_SC114: equ 1
BASE_KEV: equ 0

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
