; display routines that use the physical hardware abstraction layer


; TODO windowing
; TODO frame buffer





; clear active frame buffer

clear_display:
	ld a, ' '
	jp fill_display

; fill active frame buffer with a char in A

fill_display:
	ld b,display_fb_len
	ld hl, (display_fb_active)
.fd1:	ld (hl),a
	inc hl
	djnz .fd1
	inc hl
	ld a,0
	ld (hl),a


	ret
; Write string (DE) at pos (A) to active frame buffer

str_at_display:    ld hl,(display_fb_active)
			ld b,0
		ld c,a
		add hl,bc
.sad1: 		LD   A, (DE)        ;Get character from string
            OR   A              ;Null terminator?
            RET  Z              ;Yes, so finished
		ld (hl),a
	inc hl
            INC  DE             ;Point to next character
            JR   .sad1     ;Repeat
		ret

; using current frame buffer write to physical display

update_display:
	push de
	ld de, (display_fb_active)
	call write_display
	pop de
	ret

; TODO scrolling



; eof

