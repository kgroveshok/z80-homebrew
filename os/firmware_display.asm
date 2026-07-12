; display routines that use the physical hardware abstraction layer


; Display an activity indicator
; Each call returns the new char pointed to in hl

active:
	ld a, (display_active)
	cp 6

	jr nz, .sne
	; gone past the last one reset sequence
	ld a, 255

.sne:  
	; get the next char in seq
	inc a
	ld (display_active), a

	; look up the string in the table
	ld hl, actseq
	sla a
	call addatohl
	call loadwordinhl

	; forth will write the to string when pushing so move from rom to ram

	ld de, display_active+1
	ld bc, 2
	ldir

	ld hl, display_active+1
	ret
	
	


;db "|/-\|-\"

actseq:

dw spin0
dw spin1
dw spin2
dw spin3
dw spin2
dw spin1
dw spin0

spin0: db " ", 0
spin1: db "-", 0
spin2: db "+", 0
spin3: db "#", 0


; information window

; pass hl with 1st string to display
; pass de with 2nd string to display

info_panel:
	push hl

	ld hl, (display_fb_active)
	push hl    ; future de destination
		ld hl, display_fb0
		ld (display_fb_active), hl

;	call clear_display

	if BASE_CPM
	ld a, '.'
	else
	ld a, 165
	endif
	call fill_display


	ld a, display_row_3 + 5
	call str_at_display

	pop hl
	pop de

	push hl


	ld a, display_row_2 + 5
	call str_at_display


	call update_display
	call next_page_prompt
	call clear_display

	
		ld hl, display_fb1
		ld (display_fb_active), hl
	call update_display

	pop hl

	ret




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
;	ld a, ' '
.scwipe:
	ld (hl), ' '
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
;	ld a,0
	ld (hl),0


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

		; detect if about to print past the bottom right char
	push hl
	push de
	ld de, display_row_4+display_cols
	call cmp16
	jr nz, .skipscroll
	call scroll_up
	pop de
	pop hl ;; get rid and replace with hl moving to start of bottom row
	ld hl, display_row_4
	push hl
	push de
.skipscroll: pop de
		pop hl

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
;
; LEFT, Q = go back
; RIGHT, SPACE, CR = select
; UP, A - Up
; DOWN, Z - Down


MENU_ARRAY_PTR: equ store_tmp1
MENU_CUR_ITEM: equ store_tmp2
MENU_ITEM_CT: equ store_tmp2+1
MENU_ROW_TMP: equ store_tmp3

MENU_TOP_ITEM: equ store_tmp3+1
MENU_MORE_ITEMS: equ store_tmp4
MENU_ITEM_LAST_SHOWN: equ store_tmp4+1

menu:

		; keep array pointer

		;ld (store_tmp1), hl
		ld (MENU_ARRAY_PTR), hl
		;ld (store_tmp2), a
		ld (MENU_CUR_ITEM), a
		ld (MENU_TOP_ITEM), a

		; check for key bounce

if BASE_KEV

.mbounce:	call cin
;		cp 0
		or a
		jr nz, .mbounce
endif
		; for ease use ex

		; use menu on fb0 so as not to disrupt user screens ie a menu popup
		ld hl, display_fb0
		ld (display_fb_active), hl

.mloop:		call clear_display
		;call update_display

		; draw selection id '>' at 1

		; init start of list display

		ld a, 5
		ld (MENU_ROW_TMP), a   ; display row count
		;ld (store_tmp3), a   ; display row count
		;ild a,( MENU_CUR_ITEM)
		;ld ( MENU_TOP_ITEM), a
		;ld a,( store_tmp2)
		;ld (MENU_ITEM_CT), a   ; display item count
		;ld (store_tmp2+1), a   ; display item count


		ld a,(MENU_TOP_ITEM)
		ld (MENU_ITEM_LAST_SHOWN), a
		ld (MENU_ITEM_CT), a
		or a
		ld (MENU_MORE_ITEMS), a
		ld b, 4
.mitemlp:	push bc
		ld a, (MENU_ITEM_CT)
		;ld a,(store_tmp2+1)
		ld l, a
		ld h, 0
		add hl, hl
		ld de, (MENU_ARRAY_PTR)
		;ld de, (store_tmp1)
		add hl, de
		ld a, (hl)
		inc hl
		ld h,(hl)
		ld l, a


		call ishlzero
		jr z, .nodn

		ex de, hl
		ld a, (MENU_ROW_TMP)
		;ld a, (store_tmp3)
		call str_at_display
		
		ld a, (MENU_ROW_TMP)
		sub 4
		ld de, .mbar
		call str_at_display

		;  TODO if the current displayed row is what we are currently on then display pointer

		ld a, (MENU_ITEM_CT)
		ld hl, MENU_CUR_ITEM
		cp (hl)
		jr nz, .notonrow

	;	ld b, c     ; save current line counter for easier row location rather than screen pos
		ld a, (MENU_ROW_TMP)
		dec a
		;dec a
		dec a
		dec a
		ld de, .msel
		call str_at_display


		; if current option + 1 is not null then display V in bottom
		; get key
		;call update_display
.notonrow:	


		; next item
		ld hl, MENU_ITEM_CT
;		ld a, (store_tmp2+1)
;		inc a
;		ld (store_tmp2+1), a   ; display item count
		inc (hl)

		
		ld hl, MENU_ITEM_LAST_SHOWN
		inc (hl)


 		; next row
;		ld hl, MENU_ROW_BOT
;		inc (hl)      ; increase line counter
	
		ld a, (MENU_ROW_TMP)
		;ld a, (store_tmp3)
		add display_cols
		ld (MENU_ROW_TMP), a
		;ld (store_tmp3), a

		; at end of screen?

;		cp display_rows*3
;		jr nz, .mitemlp
		pop bc
		djnz .mitemlp
		push bc

;   not exhusted the item list so display a down arrow

		ld a, 1
		ld (MENU_MORE_ITEMS), a

		; draw options to fill the screens with active item on line 1
		; if current option is 2 or more then display ^ in top

.nodn:		pop bc

		ld a, (MENU_MORE_ITEMS)
;		or a
		cp 0
		jr z, .nomore
		ld a, display_row_4
		ld de, .mdown
		call str_at_display
.nomore:
	ld a, (MENU_TOP_ITEM)
		cp 0
;		or a
		jr z, .noup
;
		ld a, 0
		ld de, .mup
		call str_at_display

.noup:	
;	ld a, 2
;		ld de, .msel
;		call str_at_display

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
		cp KEY_RIGHT
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
		ld a, (MENU_CUR_ITEM)
;		cp 0
		or a
		jp z, .mgscup
		dec a
		ld (MENU_CUR_ITEM), a
		jp .mloop

.mgscup:	ld hl, MENU_TOP_ITEM
		or a
		cp (hl)
		jp z, .mloop
		dec (hl)
		ld a, (hl)
		ld (MENU_CUR_ITEM), a
		jp .mloop


	; move down one
.mgod:
		ld a, (MENU_ITEM_LAST_SHOWN)
;		dec a
		ld b, a

		ld a, (MENU_CUR_ITEM)
		cp b
		jp z, .mgods

		inc a
		ld (MENU_CUR_ITEM), a
		jp .mloop

		; can we scroll down?
		

		; on last row

.mgods:		ld a, (MENU_TOP_ITEM)
		ld b, a
		ld a, (MENU_CUR_ITEM)
		sub 1
		sub b
		cp 3
		jp nz, .mloop
		; and there are more items we can scroll up...
		ld a, (MENU_MORE_ITEMS)
		cp 0
		jp z, .mloop

	        ld hl, MENU_TOP_ITEM
		inc (hl)	

;	        ld hl, MENU_CUR_ITEM
;		inc (hl)	


		jp .mloop


.goend:
		; get selected item number

		ld a, (MENU_CUR_ITEM)
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

.mbar: db "|", 0
if BASE_KEV
.msel:   db 126,0
.mup:   db "^",0
.mdown:   db "v",0
endif
if BASE_CPM
.msel:   db ">",0
.mup:   db "^",0
.mdown:   db "v",0
endif
if BASE_SC114
.msel:   db ">",0
.mup:   db "^",0
.mdown:   db "v",0
endif



; eof

