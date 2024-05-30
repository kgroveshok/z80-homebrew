

.CONCAT:
	CWHEAD .FIND 52 "CONCAT" 6 WORD_FLAG_CODE
; | CONCAT ( s1 s2 -- s3 ) A string of u spaces is pushed onto the stack
	       NEXTW


.FIND:
	CWHEAD .LEN 55 "FIND" 4 WORD_FLAG_CODE
; | FIND (  -- )  
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
; | CHAR ( u -- n ) Get the ascii value of the first character of the string on the stack | TO TEST
		FORTH_DSP_VALUE
		inc hl      ; now at start of numeric as string

		ld a,(hl)   ; get char

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; push the content of a onto the stack as a value

		ld h,0
		ld l,a
		call forth_push_numhl

	       NEXTW


.STRLEN:
	CWHEAD .STRCPY 68 "STRLEN" 6 WORD_FLAG_CODE
; | STRLEN ( u1 -- Using given address u1 push then zero term length string to TOS )   |

		NEXTW

.STRCPY:
	CWHEAD .ENDSTR 69 "STRCPY" 6 WORD_FLAG_CODE
; | STRCPY ( u1 u2 -- Copy string u2 to u1 )   |

		NEXTW


.ENDSTR:
; eof

