;
; use microchip serial eeprom for storage
STORAGE_SE: equ 1
SOUND_ENABLE: equ 0
; Full OS but with the small 4x4 keypad

include "main.asm"
include "firmware_key_4x4.asm"
