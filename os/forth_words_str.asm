

.TYPE:
	CWHEAD .UPPER 52 "TYPE" 4 WORD_FLAG_CODE
; | TYPE ( u -- iu s ) Push type of value on TOS - 's' string, 'i' integer...   | DONE
		FORTH_DSP_VALUE

		ld a, (hl)

		push af

		FORTH_DSP_POP

		pop af

		cp DS_TYPE_STR
		jr z, .typestr

		cp DS_TYPE_INUM
		jr z, .typeinum

		ld hl, .tna
		jr .tpush

.typestr:	ld hl, .tstr
		jr .tpush
.typeinum:	ld hl, .tinum
		jr .tpush

.tpush:

		call forth_apushstrhl

		NEXTW
.tstr:	db "s",0
.tinum:  db "i",0
.tna:   db "?", 0


.UPPER:
	CWHEAD .LOWER 52 "UPPER" 5 WORD_FLAG_CODE
; | UPPER ( s -- s ) Upper case string s  | TODO

		NEXTW
.LOWER:
	CWHEAD .SUBSTR 52 "LOWER" 5 WORD_FLAG_CODE
; | LOWER ( s -- s ) Lower case string s  | TODO

		NEXTW

.SUBSTR:
	CWHEAD .LEFT 52 "SUBSTR" 6 WORD_FLAG_CODE
; | SUBSTR ( s u1 u2 -- s sb ) Push to TOS chars starting at position u1 and ending at u2 from string s  | TODO

		NEXTW

.LEFT:
	CWHEAD .RIGHT 52 "LEFT" 4 WORD_FLAG_CODE
; | LEFT ( s u -- s sb ) Push to TOS string u long starting from left of s  | TODO

		NEXTW
.RIGHT:
	CWHEAD .STR2NUM 52 "RIGHT" 5 WORD_FLAG_CODE
; | RIGHT ( s u -- s sb ) Push to TOS string u long starting from right of s  | TODO

		NEXTW


.STR2NUM:
	CWHEAD .NUM2STR 52 "STR2NUM" 7 WORD_FLAG_CODE
; | STR2NUM ( s -- n ) Convert a string on TOS to number | DONE


; TODO STR type check to do
		if DEBUG_FORTH_WORDS
			DMARK "S2N"
			CALLMONITOR
		endif

		FORTH_DSP_VALUE
		inc hl

		ex de, hl
		if DEBUG_FORTH_WORDS
			DMARK "S2a"
			CALLMONITOR
		endif
		call string_to_uint16

		if DEBUG_FORTH_WORDS
			DMARK "S2b"
			CALLMONITOR
		endif
		push hl
		FORTH_DSP_POP
		pop hl
		
		if DEBUG_FORTH_WORDS
			DMARK "S2b"
			CALLMONITOR
		endif
		call forth_push_numhl	

	
	       NEXTW
.NUM2STR:
	CWHEAD .CONCAT 52 "NUM2STR" 7 WORD_FLAG_CODE
; | NUM2STR ( n -- s ) Convert a number on TOS to string | TODO

		FORTH_DSP_VALUEHL
		ld a, l
		call DispAToASCII  
;TODO need to chage above call to dump into string

	       NEXTW

.CONCAT:
	CWHEAD .FIND 52 "CONCAT" 6 WORD_FLAG_CODE
; | CONCAT ( s1 s2 -- s3 ) A string of u spaces is pushed onto the stack | TODO
	       NEXTW


.FIND:
	CWHEAD .LEN 55 "FIND" 4 WORD_FLAG_CODE
; | FIND (  -- )  | TODO
	       NEXTW

.LEN:
	CWHEAD .CHAR 56 "LEN" 3 WORD_FLAG_CODE
; | LEN (  u1 -- u2 ) Push the length of the string on TOS | DONE

		FORTH_DSP_VALUE

		inc hl

		ld a, 0
		call strlent

		call forth_push_numhl



	       NEXTW
.CHAR:
	CWHEAD .STRLEN 57 "CHAR" 4 WORD_FLAG_CODE
; | CHAR ( u -- n ) Get the ascii value of the first character of the string on the stack | DONE
		FORTH_DSP_VALUE
		inc hl      ; now at start of numeric as string

		push hl

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop hl

		; push the content of a onto the stack as a value

		ld a,(hl)   ; get char
		ld h,0
		ld l,a
		call forth_push_numhl

	       NEXTW


.STRLEN:
	CWHEAD .ENDSTR 69 "COPY" 4 WORD_FLAG_CODE
; | COPY ( u1 u2 -- Copy string u2 to u1 )   | TODO

		NEXTW


.ENDSTR:
; eof

