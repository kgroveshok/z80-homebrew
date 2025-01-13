; Serial keyboard interface for SC114


key_init:
	; no init as handled by the SCM bios
	ret


cin_wait:
;	ld a, 0
;	ret

	;in a,(SC114_SIO_1_IN)
        ; Use SCM API to get from whatever console device we are using

; TODO Replace with CP/M BIOS call
	push bc
	ld c, $01
	call 5
	pop bc
	ret

cin:


	push bc

	; any key waiting to process?
; TODO Replace with CP/M BIOS call
	ld c, $06
	call 5
	jr z, .cin_skip

	; yep, get it

	ld c, $01
; TODO Replace with CP/M BIOS call
	call 5

	cp $7f     ; back space
	jr nz, .skipbs
	ld a, KEY_BS
.skipbs:

	pop bc
	ret
.cin_skip:
	ld a, 0
	pop bc
	ret




