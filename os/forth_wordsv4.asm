
; the core word dictionary v4

; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Notation.html#Notation

; this is a linked list for each of the system words used
; user defined words will follow the same format but will be in ram


;
;
; define linked list:
;
; 1. compiled byte op code
; 2. len of text word
; 3. text word
; 4. ptr to next dictionary word
; 5. asm, calls etc for the word
;
;  if 1 == 0 then last word in dict 
;  
; set the start of dictionary scanning to be in ram and the last word point to the system dict
; 
; 
; create basic standard set of words
;
; 
; + - / * DUP EMIT . SWAP IF..THEN..ELSE DO..LOOP  : ; DROP 
; 2DUP 2DROP 2SWAP 
; @ C@ - get byte 
; ! C! - store byte
; 0< true if less than zero
; 0= true if zero
; < > 
; = true if same
; variables


; Hardware specific words I may need
;
; IN OUT 
; calls to key util functions
; calls to hardward abstraction stuff
; easy control of frame buffers and lcd i/o
; keyboard 


;DICT: macro
; op_code, len, word, next
;    word:
;    db op_code
;    ds word zero term
;    dw next
;    endm




; op code 1 is a flag for user define words which are to be handled differently


;
;
;    TODO on entry to a word this should be the expected environment
;    hl - tos value if number then held, if string this is the ptr
;    de - 


; opcode ranges
; 0 - end of word dict
; 255 - user define words

sysdict:


include "forth_words_core.asm"
include "forth_words_flow.asm"
include "forth_words_maths.asm"
include "forth_words_logic.asm"
include "forth_words_display.asm"
include "forth_words_str.asm"

if STORAGE_SE
   	include "forth_words_storage.asm"
	include "forth_words_device.asm"
endif

; var handler


.VARS:
	CWHEAD .V0Q 100 "V0!" 3 WORD_FLAG_CODE
;| V0! ( u1 -- )  Store value to v0  |
	       NEXTW
.V0Q:
	CWHEAD .V1S 101 "V0@" 3 WORD_FLAG_CODE
;| V0@ ( --u )  Put value of v0 onto stack |
	       NEXTW
.V1S:
	CWHEAD .V1Q 102 "V1!" 3 WORD_FLAG_CODE
;| V1! ( u1 -- )  Store value to v1 |
	       NEXTW
.V1Q:
	CWHEAD .V2S 103 "V1@" 3 WORD_FLAG_CODE
;| V1@ ( --u )  Put value of v1 onto stack |
	       NEXTW
.V2S:
	CWHEAD .V2Q 104 "V2!" 3 WORD_FLAG_CODE
;| V2! ( u1 -- )  Store value to v2 |
	       NEXTW
.V2Q:
	CWHEAD .END 105 "V2@" 3 WORD_FLAG_CODE
;| V2@ ( --u )  Put value of v2 onto stack |
	       NEXTW




; end of dict marker

.END:    db 0
	dw 0
	db 0

; use to jp here for user dict words to save on macro expansion 

user_dict_next:
	NEXTW


user_exec:
	;    ld hl, <word code>
	;    FORTH_RSP_NEXT - call macro_forth_rsp_next
	;    call forthexec
	;    jp user_dict_next   (NEXT)
        ;    <word code bytes>
	ex de, hl
	ld hl,(os_tok_ptr)
	
	FORTH_RSP_NEXT

if DEBUG_FORTH_UWORD
	push af
	ld a, '-'
	ld (debug_mark),a
	pop af
	CALLMONITOR
endif



	ex de, hl
	ld (os_tok_ptr), hl
	
	; Don't use next - Skips the first word in uword.

	jp exec1
;	NEXT


; eof
