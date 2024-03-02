; the core word dictionary

; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Notation.html#Notation

; this is a linked list for each of the system words used
; user defined words will follow the same format but will be in ram


; TODO how to handle the ram linked list creation
; TODO compiler can create structure in ram

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


NEXT: macro 
	ld hl,(cli_origptr)   ; move to next token to parse in the input stream
	jp parsenext
      endm

; op code 1 is a flag for user define words which are to be handled differently


sysdict:

.PLUS:	db 2     
	dw .NEG
        db 2
	db "+",0          ; | + ( u u -- u )    Add two numbers and push result   |DONE
		; add top two values and push back result


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		; one value on hl get other one back

		pop de

		; do the add

		add hl,de

		; save it

		push hl	

		;

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; TODO push value back onto stack for another op etc

		pop hl

		call forth_push_numhl

		NEXT
.NEG:	db 3
	dw .DIV
        db 2
	db "-",0    ; | - ( u1 u2 -- u )    Subtract u2 from u1 and push result  |
		NEXT
.DIV:	db 4
	dw .MUL
	db 2
	db "/",0     ; | / ( u1 u2 -- u )     Divide u1 by u2 and push result |
		NEXT
.MUL: 	db 5
	dw .DUP
	db 2
	db "*",0     ; | * ( u1 u2 -- u )     Multiply TOS and push result |
		NEXT
.DUP:	db 6
	dw .EMIT
	db 4
	db "DUP",0   ; | DUP ( u -- u u )     Duplicate whatever item is on TOS |
		NEXT
.EMIT:	db 7
	dw .DOT
	db 5
	db "EMIT",0  ;|  EMIT ( u -- )        Display TOS   |DONE
		jp .print
		NEXT
.DOT:	db 8
	dw .SWAP
	db 2
	db ".",0         ;| . ( u -- )    Display TOS   |DONE
		; get value off TOS and display it

		.print:

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		
		; write value to screen     
		; TODO display it on its own briefly for now. need cursor control etc


;	push hl
;	call clear_display
;	pop hl
	push hl
	ld a,h
	ld hl, os_word_scratch
	call hexout
	pop hl
	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
		ld a, (f_cursor_ptr)
		call str_at_display

;	call update_display
;	call delay1s
;	call delay1s

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		NEXT
.SWAP:	db 9
	dw .IF
	db 5
	db "SWAP",0    ; |SWAP ( w1 w2 -- w2 w1 )    Swap top two items (of whatever type) on TOS
;		FORTH_DSP
;		ex de, hl
;		ld hl,(de)
;
;		push hl
;		FORTH_DSP
;		dec hl
;		dec hl

		NEXT
.IF:	db 10
	dw .THEN
	db 3
	db "IF",0     ;  |IF ( w -- f )     If TOS is true exec code following before??
		NEXT
.THEN:	db 11
	dw .ELSE
	db 5
	db "THEN",0    ; |THEN ( -- )     control????
		NEXT
.ELSE: 	db 12
	dw .DO
	db 5
	db "ELSE",0      ; |ELSE ( -- )     control???
		NEXT
.DO:	db 13
	dw .LOOP
	db 3
	db "DO",0       ; |DO ( u -- )        TOS has loop count until LOOP
		NEXT
.LOOP:	db 14
	dw .COLN
	db 5
	db "LOOP",0      ; |LOOP ( -- )     Current loop end marker
		NEXT
.COLN:	db 15
	dw .SCOLN
	db 2
	db ":",0     ; |: ( -- )         Create new word
		NEXT
.SCOLN:	db 16
	dw .DROP
	db 2
	db ";",0          ; |; ( -- )     Terminate new word



		NEXT
.DROP:   db 17
	dw .DUP2
	db 5
	db "DROP",0        ; |DROP ( w -- )   drop the TOS item   |DONE
		FORTH_DSP_POP
		NEXT
.DUP2:	db 18
	dw .DROP2
	db 5
	db "2DUP",0      ; |2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  
		NEXT
.DROP2:	db 19
	dw .SWAP2
	db 6
	db "2DROP",0      ; |2DROP ( w w -- )    Double drop
		NEXT
.SWAP2:	db 20
	dw .AT
	db 5
	db "2SWAP",0      ; |2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items
		NEXT
.AT:	db 21
	dw .CAT
	db 2
	db "@",0         ;| @ ( w -- ) Push onto TOS byte stored at address   | DONE

.getbyteat:	
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		
		push hl
	
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop hl

		ld a, (hl)

		ld l, a
		ld h, 0
		call forth_push_numhl

		NEXT           
.CAT:	db 22
	dw .BANG
	db 3
	db "C@",0        ; |C@  ( w -- ) Push onto TOS byte stored at address   |DONE
		jp .getbyteat
		NEXT
.BANG:   db 23
	dw .CBANG
	db 2
	db "!",0        ; |! ( x w -- ) Store x at address w      | DONE

.storebyteat:		
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		
		push hl
	
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to poke

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		push hl


		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		pop de
		pop hl

		ld (hl),e


		NEXT
.CBANG:	db 24
	dw .LZERO
	db 3
	db "C!",0       ; |C!  ( x w -- ) Store x at address w  | DONE
		jp .storebyteat
		NEXT
.LZERO:	db 25
	dw .TZERO
	db 3
	db "0<",0       ; |0< ( u -- f ) Push true if u is less than o
		NEXT
.TZERO:  db 26
	dw .LESS
	db 3
	db "0=",0         ; |0= ( u -- f ) Push true if u equals 0
		NEXT
.LESS:   db 27
	dw .GT
	db 2
	db "<",0         ; |< ( u1 u2 -- f ) True if u1 is less than u2 
		NEXT
.GT:	db 28
	dw .EQUAL
	db 2
	db ">",0       ; |> ( u1 u2 -- f ) True if u1 is greater than u2
		NEXT
.EQUAL:  db 29
	dw .SCALL
	db 2
	db "=",0          ; |= ( u1 u2 -- f ) True if u1 equals u2
		NEXT
.SCALL:	db 30
	dw .SIN
	db 5
	db "CALL",0	; |CALL ( w -- ) machine code call to address w  
		NEXT
.SIN:	db 31
	dw .SOUT
	db 3
	db "IN",0       ; |IN ( u1-- u )    Perform z80 IN with u1 being the port number. Push result to TOS
		NEXT
.SOUT:   db 32
	dw .CLS
	db 4
	db "OUT",0      ;| OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1
		NEXT

.CLS:   db 33
	dw .DRAW
	db 4
	db "CLS",0     ; |CLS ( -- ) clear frame buffer    |DONE
		call clear_display
		NEXT

.DRAW:   db 34
	dw .DUMP
	db 5
	db "DRAW",0     ; |DRAW ( -- ) Draw contents of current frame buffer  | DONE
		call update_display
		NEXT

.DUMP:   db 35				; |DUMP ( x --  ) With address x display dump   |DONE
	dw .CDUMP
	db 5
	db "DUMP",0
; TODO pop address to use off of the stack
		call clear_display

		; get address

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
	
		; save it for cdump

		ld (os_cur_ptr),hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		call dumpcont	; skip old style of param parsing	
		ret			; TODO command causes end of remaining parsing so cant do: $0000 DUMP $8000 DUMP
		NEXT
.CDUMP:   db 36                      ; continue memory dump
	dw .DEPTH
	db 6
	db "CDUMP",0              ; |CDUMP ( -- ) continue dump of memory from DUMP |  DONE
		call clear_display
		call dumpcont	
		ret			; TODO command causes end of remaining parsing so cant do: $0000 DUMP CDUMP $8000 DUMP
		NEXT


.DEPTH:   db 37                     ; stack count
	dw .DIR
	db 6
	db "DEPTH",0             ; |DEPTH ( -- u ) Push count of stack
		NEXT

.DIR:   db 38                     ;
	dw .SAVE
	db 4
	db "DIR",0               ; |DIR ( u -- w... u )   Using bank number u push directory entries w with count u 
		NEXT
.SAVE:   db 39
	dw .LOAD
	db 5
	db "SAVE",0              ; |SAVE  ( w u -- )    Save user word memory to file name w on bank u
		NEXT
.LOAD:   db 40
	dw .DAT
	db 5
	db "LOAD",0               ;| LOAD ( w u -- )    Load user word memory from file name w on bank u
		NEXT
.DAT:   db 41                     
	dw .KEY
	db 3
	db "AT",0            ;| CURSOR ( u1 u2 -- )  Set next output via . or emit at row u2 col u1 |DONE
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol


		; TODO save cursor row
		ld a,l
		cp 2
		jr nz, .crow3
		ld a, display_row_2
		jr .ccol1
.crow3:		cp 3
		jr nz, .crow4
		ld a, display_row_3
		jr .ccol1
.crow4:		cp 4
		jr nz, .crow1
		ld a, display_row_4
		jr .ccol1
.crow1:		ld a,display_row_1
.ccol1:		push af			; got row offset
		ld l,a
		ld h,0
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		; TODO save cursor col
		pop af
		add l		; add col offset
		ld (f_cursor_ptr), a
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; calculate 

		NEXT
.KEY:   db 42               
	dw .WAITK
	db 4
	db "KEY",0     ; |KEY ( -- w f )      scan for keypress but do not wait true if next item on stack is key press
		NEXT
.WAITK:   db 43               
	dw .ACCEPT
	db 6
	db "WAITK",0     ;| WAITK ( -- w )      wait for keypress TOS is key press
		NEXT
.ACCEPT:   db 44               
	dw .V0
	db 7
	db "ACCEPT",0     ; |ACCEPT ( -- w )    Prompt for text input and push pointer to string
		NEXT

;;;; counter gap


.V0:   db 143               
	dw .V1
	db 3
	db "@0",0
		NEXT

.V1:   db 144               
	dw .V2
	db 3
	db "@1",0
		NEXT


.V2:   db 145               
	dw .V3
	db 3
	db "@2",0
		NEXT


.V3:   db 146               
	dw .V4
	db 3
	db "@3",0
		NEXT


.V4:   db 147              
	dw .V5
	db 3
	db "@4",0
		NEXT

.V5:   db 148               
	dw .V6
	db 3
	db "@5",0
		NEXT

.V6:   db 149               
	dw .V7
	db 3
	db "@6",0
		NEXT

.V7:   db 150               
	dw .V8
	db 3
	db "@7",0
		NEXT

.V8:   db 151               
	dw .V9
	db 3
	db "@8",0
		NEXT

.V9:   db 152               
	dw .I
	db 3
	db "@9",0
		NEXT
.I:   db 153               
	dw .END
	db 2
	db "I",0               ;| I ( -- ) Loop counter
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
