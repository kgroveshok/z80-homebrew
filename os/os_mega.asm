;
; use microchip serial eeprom for storage

STORAGE_SE: equ 1
SOUND_ENABLE: equ 0

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
