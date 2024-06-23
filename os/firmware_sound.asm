; Sound abstraction layer

; support different sound chips through common interface

SOUND_DEVICE_AY: equ 1

SOUND_DEVICE: equ Device_A



if SOUND_DEVICE_AY
	include "firmware_sound_ay38910.asm"
else
	include "firmware_sound_sn76489an.asm"
endif


; Abstraction entry points

; init 

; sound_init in specific hardware files

; Play a note
; h = note
; l = duration
; a = channel

;note:    
;	ret




; eof

