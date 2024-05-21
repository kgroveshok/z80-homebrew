
.KEY:
	CWHEAD .WAITK 42 "KEY" 3 WORD_FLAG_CODE
;   db 42               
;	dw .WAITK
;	db 4
;	db "KEY",0     
; |KEY ( -- w f )      scan for keypress but do not wait true if next item on stack is key press
		NEXTW
.WAITK:
	CWHEAD .ACCEPT 43 "WAITK" 5 WORD_FLAG_CODE
;   db 43               
;	dw .ACCEPT
;	db 6
;	db "WAITK",0     
;| WAITK ( -- w )      wait for keypress TOS is key press | DONE
		call cin_wait
		ld l, a
		ld h, 0
		call forth_push_numhl
		NEXTW
.ACCEPT:
	CWHEAD .ENDKEY 44 "ACCEPT" 6 WORD_FLAG_CODE
;   db 44               
;	dw .HOME
;	db 7
;	db "ACCEPT",0     
; |ACCEPT ( -- w )    Prompt for text input and push pointer to string | TEST
		; TODO crashes on push
		ld a,(f_cursor_ptr)
		ld d, 100
		ld hl, os_input
		call input_str
		; TODO perhaps do a type check and wrap in quotes if not a number
		ld hl, input_str
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'A'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_apush
		NEXTW


.ENDKEY:
; eof

