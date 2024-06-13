
.KEY:
	CWHEAD .WAITK 42 "KEY" 3 WORD_FLAG_CODE
; | KEY ( -- w f ) Scan for keypress but do not wait true if next item on stack is key press | TODO

; TODO currently waits
		call cin_wait
		ld l, a
		ld h, 0
		call forth_push_numhl
		NEXTW
.WAITK:
	CWHEAD .ACCEPT 43 "WAITK" 5 WORD_FLAG_CODE
; | WAITK ( -- w ) Wait for keypress TOS is key press | DONE
		call cin_wait
		ld l, a
		ld h, 0
		call forth_push_numhl
		NEXTW
.ACCEPT:
	CWHEAD .EDIT 44 "ACCEPT" 6 WORD_FLAG_CODE
; | ACCEPT ( -- w ) Prompt for text input and push pointer to string | DONE
		; TODO crashes on push
		if DEBUG_FORTH_WORDS_KEY
			DMARK "ACC"
			CALLMONITOR
		endif
		ld hl, os_input
		ld a, 0
		ld (hl),a
		ld a,(f_cursor_ptr)
		ld d, 100
		ld c, 0
		ld e, 40
		call input_str
		; TODO perhaps do a type check and wrap in quotes if not a number
		ld hl, os_input
		if DEBUG_FORTH_WORDS
			DMARK "AC1"
			CALLMONITOR
		endif
		call forth_apushstrhl
		NEXTW

.EDIT:
	CWHEAD .ENDKEY 44 "EDIT" 4 WORD_FLAG_CODE
; | EDIT ( u -- u ) Takes string on TOS and allows editing of it. Pushes it back once done. | TO TEST 

		; TODO does not copy from stack
		if DEBUG_FORTH_WORDS_KEY
			DMARK "EDT"
			CALLMONITOR
		endif

		FORTH_DSP_VALUE
		inc hl    ; TODO do type check

		push hl
		ld a, 0
		call strlent

		ld b, 0
		ld c, l

		pop hl
		ld de, os_input
		if DEBUG_FORTH_WORDS_KEY
			DMARK "EDc"
			CALLMONITOR
		endif
		ldir


		ld hl, os_input
		ld a, 0
		ld (hl),a
		ld a,(f_cursor_ptr)
		ld d, 100
		ld c, 0
		ld e, 40
		call input_str
		; TODO perhaps do a type check and wrap in quotes if not a number
		ld hl, os_input
		if DEBUG_FORTH_WORDS
			DMARK "ED1"
			CALLMONITOR
		endif
		call forth_apushstrhl
		NEXTW



.ENDKEY:
; eof

