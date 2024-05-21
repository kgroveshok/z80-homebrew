

.CONCAT:
	CWHEAD .FIND 52 "CONCAT" 6 WORD_FLAG_CODE
;   db 52
;	  dw .MIN
 ;         db 7
;	  db "CONCAT",0	
; | CONCAT ( s1 s2 -- s3 ) A string of u spaces is pushed onto the stack
	       NEXTW


.FIND:
	CWHEAD .LEN 55 "FIND" 4 WORD_FLAG_CODE
;   db 55
;	  dw .LEN
 ;         db 5
;	  db "FIND",0	
; | FIND (  -- )  
	       NEXTW

.LEN:
	CWHEAD .CHAR 56 "LEN" 3 WORD_FLAG_CODE
;   db 56
;	  dw .CHAR
 ;         db 4
;	  db "LEN",0	
; | LEN (  u1 -- u2 ) Push the length of the string on TOS
	       NEXTW
.CHAR:
	CWHEAD .STRLEN 57 "CHAR" 4 WORD_FLAG_CODE
;   db 57
;	  dw .RND
 ;         db 5
;	  db "CHAR",0	
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
;   db 68
;	dw .STRCPY
;	db 7
;	db "STRLEN",0      
;| STRLEN ( u1 -- Using given address u1 push then zero term length string to TOS )   |

		NEXTW

.STRCPY:
	CWHEAD .ENDSTR 69 "STRCPY" 6 WORD_FLAG_CODE
;   db 69
;	dw .BSAVE
;	db 7
;	db "STRCPY",0      
;| STRCPY ( u1 u2 -- Copy string u2 to u1 )   |

		NEXTW


.ENDSTR:
; eof

