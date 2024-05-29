;
; use microchip serial eeprom for storage

STORAGE_SE: equ 1
SOUND_ENABLE: equ 0

; Full OS but with the small 4x4 keypad

display_rows: equ 4     ; move out to mini and mega files
display_cols: equ 20

key_rows: equ 4     ; TODO move out to mini and mega
key_cols: equ 4    ; TODO move out to mini and mega

include "main.asm"
include "firmware_lcd_4x20.asm"
include "firmware_key_4x4.asm"
