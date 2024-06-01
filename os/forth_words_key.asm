
.KEY:
	CWHEAD .WAITK 42 "KEY" 3 WORD_FLAG_CODE
; | KEY ( -- w f )      scan for keypress but do not wait true if next item on stack is key press
		NEXTW
.WAITK:
	CWHEAD .ACCEPT 43 "WAITK" 5 WORD_FLAG_CODE
; | WAITK ( -- w )      wait for keypress TOS is key press | DONE
		call cin_wait
		ld l, a
		ld h, 0
		call forth_push_numhl
		NEXTW
.ACCEPT:
	CWHEAD .ENDKEY 44 "ACCEPT" 6 WORD_FLAG_CODE
; | ACCEPT ( -- w )    Prompt for text input and push pointer to string | TEST
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


.ENDKEY:
; eof

