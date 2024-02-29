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
	jp parsenext
      endm




sysdict:

PLUS:	db 1
        db 2
	db "+",0
	dw NEG
		NEXT
NEG:	db 2
        db 2
	db "-",0
	dw DIV
		NEXT
DIV:	db 3
	db 2
	db "/",0
	dw MUL
		NEXT
MUL: 	db 4
	db 2
	db "*",0
	dw DUP
		NEXT
DUP:	db 5
	db 4
	db "DUP",0
	dw EMIT
		NEXT
EMIT:	db 6
	db 5
	db "EMIT",0
	dw DOT
		NEXT
DOT:	db 7
	db 2
	db ".",0
	dw SWAP
		NEXT
SWAP:	db 8
	db 5
	db "SWAP",0
	dw IF
		NEXT
IF:	db 9
	db 3
	db "IF",0
	dw THEN
		NEXT
THEN:	db 10
	db 5
	db "THEN",0
	dw ELSE
		NEXT
ELSE: 	db 11
	db 5
	db "ELSE",0
	dw DO
		NEXT
DO:	db 12
	db 3
	db "DO",0
	dw LOOP
		NEXT
LOOP:	db 13
	db 5
	db "LOOP",0
	dw COLN
		NEXT
COLN:	db 14
	db 2
	db ":",0
	dw SCOLN
		NEXT
SCOLN:	db 15
	db 2
	db ";",0
	dw DROP
		NEXT
DROP:   db 16
	db 5
	db "DROP",0
	dw DUP2
		NEXT
DUP2:	db 17
	db 5
	db "2DUP",0
	dw DROP2
		NEXT
DROP2:	db 18
	db 6
	db "2DROP",0
	dw SWAP2
		NEXT
SWAP2:	db 19
	db 5
	db "2SWAP",0
	dw AT
		NEXT
AT:	db 20
	db 2
	db "@",0
	dw CAT
		NEXT
CAT:	db 21
	db 3
	db "C@",0
	dw BANG
		NEXT
BANG:   db 22
	db 2
	db "!",0
	dw CBANG
		NEXT
CBANG:	db 23
	db 3
	db "C!",0
	dw LZERO
		NEXT
LZERO:	db 24
	db 3
	db "0<",0
	dw TZERO
		NEXT
TZERO:  db 25
	db 3
	db "0=",0
	dw LESS
		NEXT
LESS:   db 26
	db 2
	db "<",0
	dw GT
		NEXT
GT:	db 27
	db 2
	db ">",0
	dw EQUAL
		NEXT
EQUAL:  db 28
	db 2
	db "=",0
	dw SCALL
		NEXT
SCALL:	db 29
	db 5
	db "CALL",0
	dw SIN
		NEXT
SIN:	db 30
	db 3
	db "IN",0
	dw SOUT
		NEXT
SOUT:   db 31
	db 4
	db "OUT",0
	dw END
		NEXT


; Hardware specific words I may need
;
; IN OUT 
; calls to key util functions
; calls to hardward abstraction stuff
; easy control of frame buffers and lcd i/o
; keyboard 
NOP:    db 1
	db "NOP",0
	dw END
	nop
	NEXT

END:    db 0
	db 0
	db 0
	dw 0




; eof
