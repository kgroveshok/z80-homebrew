
; | ## Keyboard Words

.KEY:
	CWHEAD .KEYDB 42 "KEY" 3 WORD_FLAG_CODE
; | KEY ( -- u ) A non-blocking read of keypress | DONE
; | | The ASCII key (or key code) is pushed to stack. If no key is currently held down then push a 0
; | | Can use something like this to process:
; | | > repeat active . key ?dup if emit then #1 until 

		if DEBUG_FORTH_WORDS_KEY
			DMARK "KEY"
			CALLMONITOR
		endif
; TODO currently waits
		call cinndb
		;call cin_wait
		ld l, a
		ld h, 0
		call forth_push_numhl
		NEXTW
.KEYDB:
	CWHEAD .WAITK 42 "KEYDB" 5 WORD_FLAG_CODE
; | KEYDB ( -- u ) A non-blocking read of keypress with key release debounce | DONE
; | | The ASCII key (or key code) is pushed to stack. If no key is currently held down then push a 0
; | | Can use something like this to process:
; | | > repeat active . key ?dup if emit then #1 until 

		if DEBUG_FORTH_WORDS_KEY
			DMARK "KEB"
			CALLMONITOR
		endif
; TODO currently waits
		call cin
		;call cin_wait
		ld l, a
		ld h, 0
		call forth_push_numhl
		NEXTW
.WAITK:
	CWHEAD .ACCEPT 43 "WAITK" 5 WORD_FLAG_CODE
; | WAITK ( -- w ) Wait for keypress TOS is key press | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "WAI"
			CALLMONITOR
		endif
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
		call forth_push_str
		NEXTW

.EDIT:
	CWHEAD .DEDIT 44 "EDIT" 4 WORD_FLAG_CODE
; | EDIT ( u -- u ) Takes string on TOS and allows editing of it. Pushes it back once done. | DONE

		; TODO does not copy from stack
		if DEBUG_FORTH_WORDS_KEY
			DMARK "EDT"
			CALLMONITOR
		endif

		;FORTH_DSP
		FORTH_DSP_VALUEHL
;		inc hl    ; TODO do type check

;		call get_word_hl
		push hl
		if DEBUG_FORTH_WORDS
			DMARK "EDp"
			CALLMONITOR
		endif
	;	ld a, 0
		call strlenz
		inc hl

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
		;ld a, 0
		;ld (hl),a
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
		call forth_push_str
		NEXTW

.DEDIT:
	CWHEAD .ENDKEY 44 "DEDIT" 5 WORD_FLAG_CODE
; | DEDIT ( ptr --  ) Takes an address for direct editing in memory. | DONE

		; TODO does not copy from stack
		if DEBUG_FORTH_WORDS_KEY
			DMARK "DED"
			CALLMONITOR
		endif

		;FORTH_DSP
		FORTH_DSP_VALUEHL
;		inc hl    ; TODO do type check

;		call get_word_hl
		push hl
		push hl
		FORTH_DSP_POP
		pop hl
		if DEBUG_FORTH_WORDS
			DMARK "EDp"
			CALLMONITOR
		endif
	;	ld a, 0
		call strlenz
		inc hl

		ld b, 0
		ld c, l

		pop hl

		;ld a, 0
		;ld (hl),a
		ld a,(f_cursor_ptr)
		ld d, 100
		ld c, 0
		ld e, 40
		call input_str
		; TODO perhaps do a type check and wrap in quotes if not a number
		NEXTW


.ENDKEY:
; eof

