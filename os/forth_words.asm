; the core word dictionary


; this is a linked list for each of the system words used
; user defined words will follow the same format but will be in ram


; TODO how to handle the ram linked list creation
; TODO compiler can create structure in ram

;
;
; TODO define linked list:
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
; TODO create basic standard set of words
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


NEXT: macro 
	ld hl,(cli_origptr)
	jp parsenext
      endm




sysdict:

PLUS:	db 1
	dw NEG
        db 2
	db "+",0
		NEXT
NEG:	db 2
	dw DIV
        db 2
	db "-",0
		NEXT
DIV:	db 3
	dw MUL
	db 2
	db "/",0
		NEXT
MUL: 	db 4
	dw DUP
	db 2
	db "*",0
		NEXT
DUP:	db 5
	dw EMIT
	db 4
	db "DUP",0
		NEXT
EMIT:	db 6
	dw DOT
	db 5
	db "EMIT",0
		NEXT
DOT:	db 7
	dw SWAP
	db 2
	db ".",0
		NEXT
SWAP:	db 8
	dw IF
	db 5
	db "SWAP",0
		NEXT
IF:	db 9
	dw THEN
	db 3
	db "if",0
		NEXT
THEN:	db 10
	dw ELSE
	db 5
	db "THEN",0
		NEXT
ELSE: 	db 11
	dw DO
	db 5
	db "ELSE",0
		NEXT
DO:	db 12
	dw LOOP
	db 3
	db "DO",0
		NEXT
LOOP:	db 13
	dw COLN
	db 5
	db "LOOP",0
		NEXT
COLN:	db 14
	dw SCOLN
	db 2
	db ":",0
		NEXT
SCOLN:	db 15
	dw DROP
	db 2
	db ";",0
		NEXT
DROP:   db 16
	dw DUP2
	db 5
	db "DROP",0
		NEXT
DUP2:	db 17
	dw DROP2
	db 5
	db "2DUP",0
		NEXT
DROP2:	db 18
	dw SWAP2
	db 6
	db "2DROP",0
		NEXT
SWAP2:	db 19
	dw AT
	db 5
	db "2SWAP",0
		NEXT
AT:	db 20
	dw CAT
	db 2
	db "@",0
		NEXT
CAT:	db 21
	dw BANG
	db 3
	db "C@",0
		NEXT
BANG:   db 22
	dw CBANG
	db 2
	db "!",0
		NEXT
CBANG:	db 23
	dw LZERO
	db 3
	db "C!",0
		NEXT
LZERO:	db 24
	dw TZERO
	db 3
	db "0<",0
		NEXT
TZERO:  db 25
	dw LESS
	db 3
	db "0=",0
		NEXT
LESS:   db 26
	dw GT
	db 2
	db "<",0
		NEXT
GT:	db 27
	dw EQUAL
	db 2
	db ">",0
		NEXT
EQUAL:  db 28
	dw SCALL
	db 2
	db "=",0
		NEXT
SCALL:	db 29
	dw SIN
	db 5
	db "CALL",0
		NEXT
SIN:	db 30
	dw SOUT
	db 3
	db "IN",0
		NEXT
SOUT:   db 31
	dw END
	db 4
	db "OUT",0
		NEXT


; Hardware specific words I may need
;
; IN OUT 
; calls to key util functions
; calls to hardward abstraction stuff
; easy control of frame buffers and lcd i/o
; keyboard 
NOP:    db 1
	dw END
	db "NOP",0
	nop
	NEXT

END:    db 0
	dw 0
	db 0




; eof