; display routines that use the physical hardware abstraction layer


; TODO windowing?

; TODO scroll line up

scroll_up:

	push hl
	push de
	push bc

	; get frame buffer 

	ld hl, (display_fb_active)
	push hl    ; future de destination

	ld  de, display_cols
	add hl, de

	pop de

	;ex de, hl
	ld bc, display_fb_len -1 
;if DEBUG_FORTH_WORDS
;	DMARK "SCL"
;	CALLMONITOR
;endif	
	ldir

	; wipe bottom row


	ld hl, (display_fb_active)
	ld de, display_cols*display_rows
	add hl, de
	ld b, display_cols
	ld a, ' '
.scwipe:
	ld (hl), a
	dec hl
	djnz .scwipe

	;pop hl

	pop bc
	pop de
	pop hl

	ret


;scroll_upo:
;	ld de, display_row_1
 ;	ld hl, display_row_2
;	ld bc, display_cols
;	ldir
;	ld de, display_row_2
 ;	ld hl, display_row_3
;	ld bc, display_cols
;	ldir
;	ld de, display_row_3
 ;	ld hl, display_row_4
;	ld bc, display_cols
;	ldir

; TODO clear row 4

;	ret

	
scroll_down:

	push hl
	push de
	push bc

	; get frame buffer 

	ld hl, (display_fb_active)

	ld de, display_fb_len - 1
	add hl, de

push hl    ; future de destination

	ld  de, display_cols
	sbc hl, de


	pop de

;	ex de, hl
	ld bc, display_fb_len -1 


	

	ldir

	; wipe bottom row


;	ld hl, (display_fb_active)
;;	ld de, display_cols*display_rows
;;	add hl, de
;	ld b, display_cols
;	ld a, ' '
;.scwiped:
;	ld (hl), a
;	dec hl
;	djnz .scwiped

	;pop hl

	pop bc
	pop de
	pop hl

	ret
;scroll_down:
;	ld de, display_row_4
;	ld hl, display_row_3
;	ld bc, display_cols
;	ldir
;	ld de, display_row_3
; 	ld hl, display_row_2
;	ld bc, display_cols
;	ldir
;	ld de, display_row_2
;	ld hl, display_row_1
;	ld bc, display_cols
;	ldir
;;; TODO clear row 1
;	ret





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


; Display a menu and allow item selection (optional toggle items)
;
; format:
; hl pointer to word array with zero term for items
; e.g.    db item1
;         db ....
;         db 0
;
; a = starting menu item 
;
; de = pointer item toggle array   (todo)
;
; returns item selected in a 1-...
; returns 0 if back button pressed
;
; NOTE: Uses system frame buffer to display






menu:

		; keep array pointer

		ld (store_tmp1), hl
		ld (store_tmp2), a

		; check for key bounce

if BASE_KEV

.mbounce:	call cin
		cp 0
		jr nz, .mbounce
endif
		; for ease use ex

		; use menu on fb0 so as not to disrupt user screens ie a menu popup
		ld hl, display_fb0
		ld (display_fb_active), hl

.mloop:		call clear_display
		call update_display

		; draw selection id '>' at 1

		; init start of list display

		ld a, 5
		ld (store_tmp3), a   ; display row count
		ld a,( store_tmp2)
		ld (store_tmp2+1), a   ; display item count

		
.mitem:	


		ld a,(store_tmp2+1)
		ld l, a
		ld h, 0
		add hl, hl
		ld de, (store_tmp1)
		add hl, de
		ld a, (hl)
		inc hl
		ld h,(hl)
		ld l, a

		call ishlzero
		jr z, .mdone

		ex de, hl
		ld a, (store_tmp3)
		call str_at_display
		

		; next item
		ld a, (store_tmp2+1)
		inc a
		ld (store_tmp2+1), a   ; display item count

 		; next row

		ld a, (store_tmp3)
		add display_cols
		ld (store_tmp3), a

		; at end of screen?

		cp display_rows*4
		jr nz, .mitem


.mdone:
		call ishlzero
		jr z, .nodn

		ld a, display_row_4
		ld de, .mdown
		call str_at_display

		; draw options to fill the screens with active item on line 1
		; if current option is 2 or more then display ^ in top

.nodn:		ld a, (store_tmp2)
		cp 0
		jr z, .noup

		ld a, 0
		ld de, .mup
		call str_at_display

.noup:		ld a, 2
		ld de, .msel
		call str_at_display

		; if current option + 1 is not null then display V in bottom
		; get key
		call update_display


		; handle key

		call cin_wait

		cp KEY_UP
		jr z, .mgoup
		cp 'a'
		jr z, .mgoup
		cp KEY_DOWN
		jr z, .mgod
		cp 'z'
		jr z, .mgod
		cp ' '
		jr z, .goend
		cp KEY_CR
		jr z, .goend
		cp 'q'
		jr z, .goback

		cp KEY_LEFT
		jr z, .goback
		cp KEY_BS
		jr z, .goback
		jp .mloop

.goback:
	ld a, 0
	jr .goend2

	; move up one
.mgoup:
		ld a, (store_tmp2)
		cp 0
		jp z, .mloop
		dec a
		ld (store_tmp2), a
		jp .mloop

	; move down one
.mgod:
		ld a, (store_tmp2)
		inc a
		ld (store_tmp2), a
		jp .mloop


.goend:
		; get selected item number

		ld a, (store_tmp2)
		inc a

.goend2:
		push af

		; restore active fb
		; TODO BUG assumes fb1

		ld hl, display_fb1
		ld (display_fb_active), hl

		; restore main regs


		call update_display

		pop af

	ret

.msel:   db ">",0
.mup:   db "^",0
.mdown:   db "v",0


; eof

