; Serial keyboard interface for SC114

key_init:
	; no init as handled by the SCM bios
	ret


cin_wait:
;	ld a, 0
;	ret

	;in a,(SC114_SIO_1_IN)
        ; Use SCM API to get from whatever console device we are using
	push bc
	ld c, $01
	rst $30
	pop bc
	ret

cin:


	push bc

	; any key waiting to process?
	ld c, $03
	rst $30
	jr z, .cin_skip

	; yep, get it

	ld c, $01
	rst $30
	pop bc
	ret
.cin_skip:
	ld a, 0
	pop bc
	ret




