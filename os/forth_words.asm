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

; op code 1 is a flag for user define words which are to be handled differently


sysdict:

.PLUS:	db 2
	dw .NEG
        db 2
	db "+",0
		NEXT
.NEG:	db 3
	dw .DIV
        db 2
	db "-",0
		NEXT
.DIV:	db 4
	dw .MUL
	db 2
	db "/",0
		NEXT
.MUL: 	db 5
	dw .DUP
	db 2
	db "*",0
		NEXT
.DUP:	db 6
	dw .EMIT
	db 4
	db "DUP",0
		NEXT
.EMIT:	db 7
	dw .DOT
	db 5
	db "EMIT",0
		NEXT
.DOT:	db 8
	dw .SWAP
	db 2
	db ".",0
		NEXT
.SWAP:	db 9
	dw .IF
	db 5
	db "SWAP",0
		NEXT
.IF:	db 10
	dw .THEN
	db 3
	db "IF",0
		NEXT
.THEN:	db 11
	dw .ELSE
	db 5
	db "THEN",0
		NEXT
.ELSE: 	db 12
	dw .DO
	db 5
	db "ELSE",0
		NEXT
.DO:	db 13
	dw .LOOP
	db 3
	db "DO",0
		NEXT
.LOOP:	db 14
	dw .COLN
	db 5
	db "LOOP",0
		NEXT
.COLN:	db 15
	dw .SCOLN
	db 2
	db ":",0
		NEXT
.SCOLN:	db 16
	dw .DROP
	db 2
	db ";",0
		NEXT
.DROP:   db 17
	dw .DUP2
	db 5
	db "DROP",0
		NEXT
.DUP2:	db 18
	dw .DROP2
	db 5
	db "2DUP",0
		NEXT
.DROP2:	db 19
	dw .SWAP2
	db 6
	db "2DROP",0
		NEXT
.SWAP2:	db 20
	dw .AT
	db 5
	db "2SWAP",0
		NEXT
.AT:	db 21
	dw .CAT
	db 2
	db "@",0
		NEXT
.CAT:	db 22
	dw .BANG
	db 3
	db "C@",0
		NEXT
.BANG:   db 23
	dw .CBANG
	db 2
	db "!",0
		NEXT
.CBANG:	db 24
	dw .LZERO
	db 3
	db "C!",0
		NEXT
.LZERO:	db 25
	dw .TZERO
	db 3
	db "0<",0
		NEXT
.TZERO:  db 26
	dw .LESS
	db 3
	db "0=",0
		NEXT
.LESS:   db 27
	dw .GT
	db 2
	db "<",0
		NEXT
.GT:	db 28
	dw .EQUAL
	db 2
	db ">",0
		NEXT
.EQUAL:  db 29
	dw .SCALL
	db 2
	db "=",0
		NEXT
.SCALL:	db 30
	dw .SIN
	db 5
	db "CALL",0
		NEXT
.SIN:	db 31
	dw .SOUT
	db 3
	db "IN",0
		NEXT
.SOUT:   db 32
	dw .PUSH
	db 4
	db "OUT",0
		NEXT

.PUSH:   db 33
	dw .POP
	db 5
	db "PUSH",0
		NEXT

.POP:   db 34
	dw .DUMP
	db 4
	db "POP",0
		NEXT

.DUMP:   db 35				; memory dump ( x --  )
	dw .CDUMP
	db 5
	db "DUMP",0
; TODO pop address to use off of the stack
		call clear_display

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		ld (os_cur_ptr),hl

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		call dumpcont	
		ret
		NEXT
.CDUMP:   db 36                      ; continue memory dump
	dw .DEPTH
	db 6
	db "CDUMP",0
		call clear_display
		call dumpcont	
		ret
		NEXT


.DEPTH:   db 37                     ; stack count
	dw .DIR
	db 6
	db "DEPTH",0
		NEXT

.DIR:   db 38                     ;
	dw .SAVE
	db 4
	db "DIR",0
		NEXT
.SAVE:   db 39
	dw .LOAD
	db 5
	db "SAVE",0
		NEXT
.LOAD:   db 40
	dw .DISPLAY
	db 5
	db "LOAD",0
		NEXT
.DISPLAY:   db 41                     
	dw .KEY
	db 8
	db "DISPLAY",0
		NEXT
.KEY:   db 42               
	dw .V0
	db 4
	db "KEY",0
		NEXT


.V0:   db 43               
	dw .V1
	db 3
	db "@0",0
		NEXT

.V1:   db 44               
	dw .V2
	db 3
	db "@1",0
		NEXT


.V2:   db 45               
	dw .V3
	db 3
	db "@2",0
		NEXT


.V3:   db 46               
	dw .V4
	db 3
	db "@3",0
		NEXT


.V4:   db 47              
	dw .V5
	db 3
	db "@4",0
		NEXT

.V5:   db 48               
	dw .V6
	db 3
	db "@5",0
		NEXT

.V6:   db 49               
	dw .V7
	db 3
	db "@6",0
		NEXT

.V7:   db 50               
	dw .V8
	db 3
	db "@7",0
		NEXT

.V8:   db 51               
	dw .V9
	db 3
	db "@8",0
		NEXT

.V9:   db 52               
	dw .I
	db 3
	db "@9",0
		NEXT
.I:   db 53               
	dw .END
	db 2
	db "I",0
		NEXT


; Hardware specific words I may need
;
; IN OUT 
; calls to key util functions
; calls to hardward abstraction stuff
; easy control of frame buffers and lcd i/o
; keyboard 
.NOP:    db 1
	dw .END
	db "NOP",0
	nop
	NEXT

.END:    db 0
	dw 0
	db 0




; eof
