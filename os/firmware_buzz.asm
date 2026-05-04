; A simple buzzer for sound

DEVICE_BUZZ: equ Device_A

BUZZ_PIN_MASK:   equ 255     ; TODO reduce to the exact pin on the bus but this is OK for testing


; HL - Duration
; B - Freq

sound_buzzer: 
	ld a, BUZZ_PIN_MASK

	out (DEVICE_BUZZ), a

	push bc
	ld a, b
	call aDelayInMS
	pop bc

	dec hl
	call ishlzero
	ret z
	jr sound_buzzer
	

; eof
	

