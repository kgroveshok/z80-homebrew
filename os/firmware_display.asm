; display routines that use the physical hardware abstraction layer


; TODO windowing?

; TODO scroll line up

scroll_up:
	ld de, display_row_1
 	ld hl, display_row_2
	ld bc, display_cols
	ldir
	ld de, display_row_2
 	ld hl, display_row_3
	ld bc, display_cols
	ldir
	ld de, display_row_3
 	ld hl, display_row_4
	ld bc, display_cols
	ldir

; TODO clear row 4

	ret
	
scroll_down:
	ld de, display_row_4
 	ld hl, display_row_3
	ld bc, display_cols
	ldir
	ld de, display_row_3
 	ld hl, display_row_2
	ld bc, display_cols
	ldir
	ld de, display_row_2
 	ld hl, display_row_1
	ld bc, display_cols
	ldir
; TODO clear row 1
	ret





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
	push hl
	ld hl, (display_fb_active)
	call write_display
	pop hl
	ret

; TODO scrolling


; move cursor right one char
cursor_right:

	; TODO shift right
	; TODO if beyond max col
	; TODO       cursor_next_line

	ret


cursor_next_line:
	; TODO first char
	; TODO line down
	; TODO if past last row
	; TODO    scroll up

	ret

cursor_left:
	; TODO shift left
	; TODO if beyond left 
	; TODO     cursor prev line
	
	ret

cursor_prev_line:
	; TODO last char
	; TODO line up
	; TODO if past first row
	; TODO   scroll down

	ret


cout:
	; A - char
	ret

; eof

