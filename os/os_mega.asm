;
; use microchip serial eeprom for storage
STORAGE_SE: equ 1
; Full OS but with the 5x10 fullsized keyboard

include "os.asm"
include "firmware_key_5x10.asm"
;include "firmware_key_4x10.asm"