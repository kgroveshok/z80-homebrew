;
; use microchip serial eeprom for storage

STORAGE_SE: equ 1
SOUND_ENABLE: equ 1

; Full OS but with the 5x10 fullsized keyboard

display_rows: equ 4     ; move out to mini and mega files
display_cols: equ 20
;display_cols: equ 40

key_rows: equ 5     ; TODO move out to mini and mega
key_cols: equ 10    ; TODO move out to mini and mega

include "main.asm"
;include "firmware_lcd_4x40.asm"
include "firmware_lcd_4x20.asm"
include "firmware_key_5x10.asm"
;include "firmware_key_4x10.asm"
