
; the core word dictionary v4

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

.PLUS:	
	CWHEAD .NEG 1 "+" 1 WORD_FLAG_CODE
;db 2     
;	dw .NEG
;        db 2
;	db "+",0          
; | + ( u u -- u )    Add two numbers and push result   | INT DONE
		; add top two values and push back result

		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .dot_inum

	if FORTH_ENABLE_FLOATMATH
			inc hl      ; now at start of numeric as string

		if DEBUG_FORTH_DOT
			push af
			ld a, 'C'
			ld (debug_mark),a
			pop af
	;		call break_point_state
	CALLMONITOR
			;call display_reg_state
			;call display_dump_at_hl
		endif

		;ld ix, hl
		call CON


		push hl
		
		

			FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get next number

			FORTH_DSP_VALUE

			inc hl      ; now at start of numeric as string

		;ld ix, hl
		call CON

		push hl


			FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

			; TODO do add

			call IADD

			; TODO get result back as ascii

			; TODO push result 



			jr .dot_done
	endif

.dot_inum:



		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

	; TODO add floating point number detection

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

.dot_done:
		call forth_push_numhl

		NEXT
.NEG:

	CWHEAD .DIV 3 "-" 1 WORD_FLAG_CODE
;	db 3
;	dw .DIV
;        db 2
;	db "-",0    
; | - ( u1 u2 -- u )    Subtract u2 from u1 and push result  | INT DONE


	; TODO add floating point number detection
		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .neg_inum

	if FORTH_ENABLE_FLOATMATH
		jr .neg_done

	endif
		

.neg_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		; one value on hl get other one back

		pop de

		; do the sub
;		ex de, hl

		sbc hl,de

		; save it

		push hl	

		;

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; TODO push value back onto stack for another op etc

		pop hl

		call forth_push_numhl
.neg_done:

		NEXT
.DIV:
	CWHEAD .MUL 4 "/" 1 WORD_FLAG_CODE
;	db 4
;	dw .MUL
;	db 2
;	db "/",0     
; | / ( u1 u2 -- result remainder )     Divide u1 by u2 and push result | INT DONE
	; TODO add floating point number detection
		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .div_inum

	if FORTH_ENABLE_FLOATMATH
		jr .div_done

	endif
.div_inum:

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; to go to bc

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		; hl to go to de

		push hl

		pop bc
		pop de		


		if DEBUG_FORTH_MATHS
			push af
			ld a, '/'
			ld (debug_mark),a
			pop af
	;		call break_point_state
	CALLMONITOR
		endif
		; one value on hl but move to a get other one back

       
	call Div16

;	push af	
	push hl
	push bc

		if DEBUG_FORTH_MATHS
			push af
			ld a, '1'
			ld (debug_mark),a
			pop af
	;		call break_point_state
	;rst 030h
	CALLMONITOR
		endif

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 



		pop hl    ; result

		call forth_push_numhl

		pop hl    ; reminder
;		ld h,0
;		ld l,d

		call forth_push_numhl
.div_done:
		NEXT
.MUL:
	CWHEAD .DUP 5 "*" 1 WORD_FLAG_CODE
; 	db 5
;	dw .DUP
;	db 2
;	db "*",0     
; | * ( u1 u2 -- u )     Multiply TOS and push result | INT DONE
	; TODO add floating point number detection
		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .mul_inum

	if FORTH_ENABLE_FLOATMATH
		jr .mul_done

	endif

.mul_inum:	

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		; one value on hl but move to a get other one back

		ld a, l

		pop de

		; do the mull
;		ex de, hl

		call Mult16
		; save it

		push hl	

		;

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; TODO push value back onto stack for another op etc

		pop hl

		call forth_push_numhl

.mul_done:
		NEXT
.DUP:
	CWHEAD .EMIT 6 "DUP" 3 WORD_FLAG_CODE
;	db 6
;	dw .EMIT
;	db 4
;	db "DUP",0   
; | DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

	; TODO add floating point number detection
		call forth_push_numhl
		NEXT
.EMIT:
	CWHEAD .DOT 7 "EMIT" 4 WORD_FLAG_CODE
;	db 7
;	dw .DOT
;	db 5
;	db "EMIT",0  
;|  EMIT ( u -- )        Display ascii character  TOS   |
		; get value off TOS and display it


		FORTH_DSP_VALUE 

		ld a,l
		; TODO write to display

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		NEXT
.DOT:
	CWHEAD .SWAP 8 "." 1 WORD_FLAG_CODE
;	db 8
;	dw .SWAP
;	db 2
;	db ".",0 
        ;| . ( u -- )    Display TOS   |DONE
		; get value off TOS and display it



		FORTH_DSP_VALUE 
if DEBUG_FORTH_DOT
	push af
	ld a, 'z'
	ld (debug_mark),a
	pop af
	;call break_point_state
	;rst 030h
	CALLMONITOR
;	call display_reg_state
;	call display_dump_at_hl
endif	
;		.print:

	ld a,(hl)  ; work out what type of value is on the TOS
	inc hl   ; position to the actual value
	cp DS_TYPE_STR
	jr nz, .dotnum1 

; display string
	ex de,hl
	jr .dotwrite

.dotnum1:
	cp DS_TYPE_INUM
	jr nz, .dotflot


; display number

;	push hl
;	call clear_display
;	pop hl

	ld e, (hl)
	inc hl
	ld d, (hl)
	ld hl, scratch
if DEBUG_FORTH_DOT
	push af
	ld a, 'I'
	ld (debug_mark),a
	pop af
	;call break_point_state
	;rst 030h
	CALLMONITOR
	;call display_reg_state
	;call display_dump_at_hl
endif	

	call uitoa_16
	ex de,hl

if DEBUG_FORTH_DOT
	push af
	ld a, 'i'
	ld (debug_mark),a
	pop af
	;call break_point_state
	;rst 030h
	CALLMONITOR
	;call display_reg_state
	;call display_dump_at_hl
endif	

;	ld de, os_word_scratch
	jr .dotwrite

.dotflot:   nop
; TODO print floating point number

.dotwrite:		ld a, (f_cursor_ptr)
		call str_at_display
		call update_display
if DEBUG_FORTH_DOT_KEY
		call next_page_prompt
endif	
; TODO this pop off the stack causes a crash. i dont know why


if DEBUG_FORTH_DOT
	push af
	ld a, 'h'
	ld (debug_mark),a
	pop af
	;call break_point_state
	;rst 030h
	CALLMONITOR
	;call display_reg_state
	;call display_dump_at_hl
endif	

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

if DEBUG_FORTH_DOT
	push af
	ld a, 'i'
	ld (debug_mark),a
	pop af
	;call break_point_state
	;rst 030h
	CALLMONITOR
	;call display_reg_state
	;call display_dump_at_hl
endif	


		NEXT
.SWAP:
	CWHEAD .IF 9 "SWAP" 4 WORD_FLAG_CODE
;	db 9
;	dw .IF
;	db 5
;	db "SWAP",0    
; |SWAP ( w1 w2 -- w2 w1 )    Swap top two items (of whatever type) on TOS
;		FORTH_DSP
;		ex de, hl
;		ld hl,(de)
;
;		push hl
;		FORTH_DSP
;		dec hl
;		dec hl

		NEXT
.IF:
	CWHEAD .THEN 10 "IF" 2 WORD_FLAG_CODE
;	db 10
;	dw .THEN
;	db 3
;	db "IF",0     
;  |IF ( w -- f )     If TOS is true exec code following before??
; TODO Eval stack
; TODO on result extract portion to exec, malloc it and start exec on that block
; TODO once exec, position next exec point past both blocks


		NEXT
.THEN:
	CWHEAD .ELSE 11 "THEN" 4 WORD_FLAG_CODE
;	db 11
;	dw .ELSE
;	db 5
;	db "THEN",0    
; |THEN ( -- )     control????
		NEXT
.ELSE:
	CWHEAD .DO 12 "ELSE" 2 WORD_FLAG_CODE
; 	db 12
;	dw .DO
;	db 5
;	db "ELSE",0      
; |ELSE ( -- )     control???



		NEXT
.DO:
	CWHEAD .LOOP 13 "DO" 2 WORD_FLAG_CODE
;	db 13
;	dw .LOOP
;	db 3
;	db "DO",0       
; |DO ( u1 u2 -- )   Loop starting at u2 with a limit of u1

; TODO push pc to rsp stack
; TODO save tos to i value
		NEXT
.LOOP:
	CWHEAD .COLN 14 "LOOP" 4 WORD_FLAG_CODE
;	db 14
;	dw .COLN
;	db 5
;	db "LOOP",0      
; |LOOP ( -- )     Current loop end marker

	; TODO pop tos as current loop count to hl
	; TODO if new tos (loop limit) is not same as hl, inc hl, push hl to tos, pop rsp and set pc to it
	; TODO else end of loop. pop rsp and bin

		NEXT
.COLN:
	CWHEAD .SCOLN 15 ":" 1 WORD_FLAG_CODE
;	db 15
;	dw .DROP
;	db 2
;	db ":",0     
; |: ( -- )         Create new word | TEST - Breaking dict linked list

	; get parser buffer length  of new word

	

		; move tok past this to start of name defintition
		; TODO get word to define
		; TODO Move past word token
		; TODO get length of string up to the ';'

	ld hl, (os_tok_ptr)
	inc hl
	inc hl

	ld a, ';'
	call strlent

	ld a,l
	ld (os_new_parse_len), a


if DEBUG_FORTH_UWORD
	ld de, (os_tok_ptr)
	push af
	ld a, ':'
	ld (debug_mark),a
	pop af
	CALLMONITOR
endif

;
;  new word memory layout:
; 
;    : adg 6666 ; 
;
;    db   1     ; user defined word 
	inc hl   
;    dw   sysdict
	inc hl
	inc hl
;    db <word len>+1 (for null)
	inc hl
;    db .... <word>
;

	inc hl    ; some extras for the word preamble before the above
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl     ; TODO how many do we really need?
;       exec word buffer
;	<ptr word>  
	inc hl
	inc hl
;       <word list><null term> 7F final term


if DEBUG_FORTH_UWORD
	push af
	ld a, 'z'
	ld (debug_mark),a
	pop af
	CALLMONITOR
endif

	
		; malloc the size

		call malloc
		ld (os_new_malloc), hl     ; save malloc start

;    db   1     ; user defined word 
		ld a, WORD_SYS_UWORD 
		ld (hl), a
	
	inc hl   
;    dw   sysdict
	ld de, sysdict       ; continue on with the scan to the system dict
	ld (hl), e
	inc hl
	ld (hl), d
	inc hl


;    Setup dict word

	inc hl
	ld (os_new_work_ptr), hl     ; save start of dict word 

	; 1. get length of dict word


	ld hl, (os_tok_ptr)
	inc hl
	inc hl    ; position to start of dict word
	ld a, 0
	call strlent


	inc hl    ; to include null???

	; write length of dict word

	ld de, (os_new_work_ptr)   ; get dest for copy of word
	dec de
	ex de, hl
	ld (hl), e
	ex de, hl

	

	; copy 
	ld c, l
	ld b, 0
	ld de, (os_new_work_ptr)   ; get dest for copy of word
	ld hl, (os_tok_ptr)
	inc hl
	inc hl    ; position to start of dict word
	
;	ldir       ; copy word - HL now is where we need to be for copy of the line
	
	; TODO need to convert word to upper case

ucasetok:	
	ld a,(hl)
	call toUpper
	ld (hl),a
	ldi
 	jp p, ucasetok



	; de now points to start of where the word body code should be placed
	ld (os_new_work_ptr), de
	; hl now points to the words to throw at forthexec which needs to be copied
	ld (os_new_src_ptr), hl

	; TODO add 'call to forthexec'

if DEBUG_FORTH_UWORD
	push bc
	ld bc, (os_new_malloc)
	push af
	ld a, 'x'
	ld (debug_mark),a
	pop af
	CALLMONITOR
	pop bc
endif


	; create word preamble which should be:

; TODO possibly push the current os_tok_ptr to rsp and the current rsp will be the start of the string and not current pc????

	;    ld hl, <word code>
	;    jp user_exec
        ;    <word code bytes>


;	inc de     ; TODO ??? or are we already past the word's null
	ex de, hl

	ld (hl), 021h     ; TODO get bytes poke "ld hl, "

	inc hl
	ld (os_new_exec_ptr),hl     ; save this location to poke with the address of the word buffer
	inc hl

	inc hl
	ld (hl), 0c3h     ; TODO get bytes poke "jp xx  "

	ld bc, user_exec
	inc hl
	ld (hl), c     ; poke address of user_exec
	inc hl
	ld (hl), b    
 ;
;	inc hl
;	ld (hl), 0cdh     ; TODO get bytes poke "call  "
;
;
;	ld bc, macro_forth_rsp_next
;	inc hl
;	ld (hl), c     ; poke address of FORTH_RSP_NEXT
;	inc hl
;	ld (hl), b    
 ;
;	inc hl
;	ld (hl), 0cdh     ; TODO get bytes poke "call  "
;
;
;	inc hl
;	ld bc, forthexec
;	ld (hl), c     ; poke address of forthexec
;	inc hl
;	ld (hl), b     
;
;	inc hl
;	ld (hl), 0c3h     ; TODO get bytes poke "jp  "
;
;	ld bc, user_dict_next
;	inc hl
;	ld (hl), c     ; poke address of forthexec
;	inc hl
;	ld (hl), b     

	; hl is now where we need to copy the word byte data to save this

	inc hl
	ld (os_new_exec), hl
	
	; copy definition

	ex de, hl
;	inc de    ; TODO BUG It appears the exec of a uword requires pc to be set
;	inc de    ; skip the PC for this parse
	ld a, (os_new_parse_len)
	ld c, a
	ld b, 0
	ldir		 ; copy defintion


	; poke the address of where the new word bytes live for forthexec

	ld hl, (os_new_exec_ptr)     ; TODO this isnt correct

	ld de, (os_new_exec)     
	
	ld (hl), e
	inc hl
	ld (hl), d

		; TODO copy last user dict word next link to this word
		; TODO update last user dict word to point to this word
;
; hl f923 de 812a ; bc 811a

if DEBUG_FORTH_UWORD
	push bc
	ld bc, (os_new_malloc)
	push af
	ld a, ';'
	ld (debug_mark),a
	pop af
	CALLMONITOR
	pop bc
endif
if DEBUG_FORTH_UWORD
	push bc
	ld bc, (os_new_malloc)
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc

	push af
	ld a, ';'
	ld (debug_mark),a
	pop af
	CALLMONITOR
	pop bc
endif

; TODO update word dict linked list for new word


ld hl, (os_last_new_uword)		; get the start of the last added uword
inc hl     ; move to next work linked list ptr

ld de, (os_new_malloc)		 ; new next word
ld (hl), e
inc hl
ld (hl), d

ld (os_last_new_uword), hl      ; update last new uword ptr


if DEBUG_FORTH_UWORD
	push af
	ld a, ';'
	ld (debug_mark),a
	pop af
	CALLMONITOR
endif


ret    ; dont process any remaining parser tokens as they form new word




;		NEXT
.SCOLN:
;	CWHEAD .DROP 17 '\;' 1 WORD_FLAG_CODE
	db 17
	dw .DROP
	db 2
	db ";",0          
; |; ( -- )     Terminate new word and return exec to previous exec level
		FORTH_RSP_TOS
		push hl
		FORTH_RSP_POP
		pop hl
;		ex de,hl
		ld (os_tok_ptr),hl

if DEBUG_FORTH_UWORD
	push af
	ld a, ';'
	ld (debug_mark),a
	pop af
	CALLMONITOR
endif
		NEXT
.DROP:
	CWHEAD .DUP2 17 "DROP" 4 WORD_FLAG_CODE
;   db 17
;	dw .DUP2
;	db 5
;	db "DROP",0        
; |DROP ( w -- )   drop the TOS item   |DONE
		FORTH_DSP_POP
		NEXT
.DUP2:
	CWHEAD .DROP2 18 "2DUP" 4 WORD_FLAG_CODE
;	db 18
;	dw .DROP2
;	db 5
;	db "2DUP",0      i
; |2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  
		NEXT
.DROP2:
	CWHEAD .SWAP2 19 "2DROP" 5 WORD_FLAG_CODE
;	db 19
;	dw .SWAP2
;	db 6
;	db "2DROP",0      
; |2DROP ( w w -- )    Double drop | DONE
		FORTH_DSP_POP
		FORTH_DSP_POP
		NEXT
.SWAP2:
	CWHEAD .AT 20 "2SWAP" 5 WORD_FLAG_CODE
;	db 20
;	dw .AT
;	db 5
;	db "2SWAP",0      
; |2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items
		NEXT
.AT:
	CWHEAD .CAT 21 "@" 1 WORD_FLAG_CODE
;	db 21
;	dw .CAT
;	db 2
;	db "@",0         
;| @ ( w -- ) Push onto TOS byte stored at address   | DONE

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
.CAT:
	CWHEAD .BANG 22 "C@" 2 WORD_FLAG_CODE
;	db 22
;	dw .BANG
;	db 3
;	db "C@",0        
; |C@  ( w -- ) Push onto TOS byte stored at address   |DONE
		jp .getbyteat
		NEXT
.BANG:
	CWHEAD .CBANG 23 "!" 1 WORD_FLAG_CODE
;   db 23
;	dw .CBANG
;	db 2
;	db "!",0        
; |! ( x w -- ) Store x at address w      | DONE

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
.CBANG:
	CWHEAD .LZERO 24 "C!" 2 WORD_FLAG_CODE
;	db 24
;	dw .LZERO
;	db 3
;	db "C!",0       
; |C!  ( x w -- ) Store x at address w  | DONE
		jp .storebyteat
		NEXT
.LZERO:
	CWHEAD .TZERO 25 "0<" 2 WORD_FLAG_CODE
;	db 25
;	dw .TZERO
;	db 3
;	db "0<",0       
; |0< ( u -- f ) Push true if u is less than o | CANT DO UNTIL FLOAT
		NEXT
.TZERO:
	CWHEAD .LESS 26 "0=" 2 WORD_FLAG_CODE
;  db 26
;	dw .LESS
;	db 3
;	db "0=",0         
; |0= ( u -- f ) Push true if u equals 0 | TEST NO DEBUG
	; TODO add floating point number detection
		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .tz_inum

	if FORTH_ENABLE_FLOATMATH
		jr .tz_done

	endif
		

.tz_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop hl

		ld a,0

		cp l
		jr nz, .tz_notzero

		cp h

		jr nz, .tz_notzero


		ld hl, FORTH_TRUE
		jr .tz_done

.tz_notzero:	ld hl, FORTH_FALSE

		; push value back onto stack for another op etc

.tz_done:
		call forth_push_numhl

		NEXT
.LESS:
	CWHEAD .GT 27 "<" 1 WORD_FLAG_CODE
;   db 27
;	dw .GT
;	db 2
;	db "<",0         
; |< ( u1 u2 -- f ) True if u1 is less than u2 | DONE
	; TODO add floating point number detection
		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .less_inum

	if FORTH_ENABLE_FLOATMATH
		jr .less_done

	endif
		

.less_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl  ; u2

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u1

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


 or a      ;clear carry flag
 ld bc, FORTH_FALSE
  pop hl    ; u1
  pop de    ; u2
  sbc hl,de
  jr nc,.lscont   	;	if hl >= de, carry flag will be cleared

 ld bc, FORTH_TRUE
.lscont: 
		push bc
		pop hl

		if DEBUG_FORTH_WORDS
			push af
			ld a, '<'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_push_numhl

		NEXT
.GT:
	CWHEAD .EQUAL 28 ">" 1 WORD_FLAG_CODE
;	db 28
;	dw .EQUAL
;	db 2
;	db ">",0       
; |> ( u1 u2 -- f ) True if u1 is greater than u2 | DONE
	; TODO add floating point number detection
		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .gt_inum

	if FORTH_ENABLE_FLOATMATH
		jr .gt_done

	endif
		

.gt_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl  ; u2

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u1

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


 or a      ;clear carry flag
 ld bc, FORTH_FALSE
  pop hl    ; u1
  pop de    ; u2
  sbc hl,de
  jr c,.gtcont   	;	if hl >= de, carry flag will be cleared

 ld bc, FORTH_TRUE
.gtcont: 
		push bc
		pop hl

		if DEBUG_FORTH_WORDS
			push af
			ld a, '>'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_push_numhl

		NEXT
.EQUAL:
	CWHEAD .SCALL 29 "=" 1 WORD_FLAG_CODE
;  db 29
;	dw .SCALL
;	db 2
;	db "=",0          
; |= ( u1 u2 -- f ) True if u1 equals u2 | DONE
	; TODO add floating point number detection
		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .eq_inum

	if FORTH_ENABLE_FLOATMATH
		jr .eq_done

	endif
		

.eq_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		; one value on hl get other one back

		push hl

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		ld c, FORTH_FALSE

		pop hl
		pop de

		ld a, e
		cp l

		jr nz, .eq_done

		ld a, d
		cp h

		jr nz, .eq_done

		ld c, FORTH_TRUE
		


.eq_done:

		; TODO push value back onto stack for another op etc

		ld h, 0
		ld l, c
		if DEBUG_FORTH_WORDS
			push af
			ld a, '='
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_push_numhl

		NEXT
.SCALL:
	CWHEAD .SIN 30 "CALL" 4 WORD_FLAG_CODE
;	db 30
;	dw .SIN
;	db 5
;	db "CALL",0	
; |CALL ( w -- w  ) machine code call to address w  push the result of hl to stack | TO TEST
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

			
		pop hl

		; how to do a call with hl???? save SP?
		call forth_call_hl


		; TODO push value back onto stack for another op etc

		call forth_push_numhl
		NEXT
.SIN:
	CWHEAD .SOUT 31 "IN" 2 WORD_FLAG_CODE
;	db 31
;	dw .SOUT
;	db 3
;	db "IN",0       
; |IN ( u1-- u )    Perform z80 IN with u1 being the port number. Push result to TOS | TO TEST
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop bc

		; do the sub
;		ex de, hl

		in l,(c)

		; save it

		ld h,0

		; TODO push value back onto stack for another op etc

		call forth_push_numhl
		NEXT
.SOUT:
	CWHEAD .CLS 32 "OUT" 3 WORD_FLAG_CODE
;   db 32
;	dw .CLS
;	db 4
;	db "OUT",0      
;| OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | TO TEST

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl

		pop bc

		out (c), l

		NEXT

.CLS:
	CWHEAD .DRAW 33 "CLS" 3 WORD_FLAG_CODE
;   db 33
;	dw .DRAW
;	db 4
;	db "CLS",0     
; |CLS ( -- ) clear frame buffer    |DONE
		call clear_display
		jp .home		; and home cursor
		NEXT

.DRAW:
	CWHEAD .DUMP 34 "DRAW" 4 WORD_FLAG_CODE
;   db 34
;	dw .DUMP
;	db 5
;	db "DRAW",0     
; |DRAW ( -- ) Draw contents of current frame buffer  | DONE
		call update_display
		NEXT

.DUMP:
	CWHEAD .CDUMP 35 "DUMP" 4 WORD_FLAG_CODE
;   db 35				
; |DUMP ( x --  ) With address x display dump   |DONE
;	dw .CDUMP
;	db 5
;	db "DUMP",0
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
.CDUMP:
	CWHEAD .DEPTH 36 "CDUMP" 5 WORD_FLAG_CODE
;   db 36                      ; continue memory dump
;	dw .DEPTH
;	db 6
;	db "CDUMP",0              
; |CDUMP ( -- ) continue dump of memory from DUMP |  DONE
		call clear_display
		call dumpcont	
		ret			; TODO command causes end of remaining parsing so cant do: $0000 DUMP CDUMP $8000 DUMP
		NEXT


.DEPTH:
	CWHEAD .DIR 37 "DEPTH" 5 WORD_FLAG_CODE
;   db 37                     ; stack count
;	dw .DIR
;	db 6
;	db "DEPTH",0             
; |DEPTH ( -- u ) Push count of stack | DONE
		; take current TOS and remove from base value div by two to get count


	ld hl, (cli_data_sp)
	ld de, cli_data_stack
	sbc hl,de
	
	; div by two?

	ld e,l
	ld c, 2
	call Div8

	ld l,a
	ld h,0

	;srl h
	;rr l

		call forth_push_numhl
		NEXT

.DIR:
	CWHEAD .SAVE 38 "DIR" 3 WORD_FLAG_CODE
;
;   db 38                     ;
;	dw .SAVE
;	db 4
;	db "DIR",0               
; |DIR ( u -- w... u )   Using bank number u push directory entries from persistent storage as w with count u 
		NEXT
.SAVE:
	CWHEAD .LOAD 39 "SAVE" 4 WORD_FLAG_CODE
;   db 39
;	dw .LOAD
;	db 5
;	db "SAVE",0              
; |SAVE  ( w u -- )    Save user word memory to file name w on bank u
		NEXT
.LOAD:
	CWHEAD .DAT 40 "LOAD" 4 WORD_FLAG_CODE
;   db 40
;	dw .DAT
;	db 5
;	db "LOAD",0               
;| LOAD ( w u -- )    Load user word memory from file name w on bank u
		NEXT
.DAT:
	CWHEAD .KEY 41 "KEY" 3 WORD_FLAG_CODE
;   db 41                     
;	dw .KEY
;	db 3
;	db "AT",0            
;| CURSOR ( u1 u2 -- )  Set next output via . or emit at row u2 col u1 |DONE
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
.KEY:
	CWHEAD .WAITK 42 "KEY" 3 WORD_FLAG_CODE
;   db 42               
;	dw .WAITK
;	db 4
;	db "KEY",0     
; |KEY ( -- w f )      scan for keypress but do not wait true if next item on stack is key press
		NEXT
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
		NEXT
.ACCEPT:
	CWHEAD .HOME 44 "ACCEPT" 6 WORD_FLAG_CODE
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
		NEXT

.HOME:
	CWHEAD .OVER 45 "HOME" 4 WORD_FLAG_CODE
;	db 45
;	dw .OVER
;	db 5
;	db "HOME",0	
; |HOME ( -- )    Reset the current cursor for output to home |DONE
.home:		ld a, 0		; and home cursor
		ld (f_cursor_ptr), a
		NEXT

.OVER:
	CWHEAD .PAUSE 46 "OVER" 4 WORD_FLAG_CODE
;  db 46
;	dw .PAUSE
;	db 5
;	db "OVER",0	
; |OVER ( n1 n2 -- n1 n2 n1 )  Copy one below TOS onto TOS | DONE

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		push hl    ; n2
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		push hl    ; n1
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop de     ; n1
		pop hl     ; n2

		push de
		push hl
		push de

		; push back 

		pop hl
		call forth_push_numhl
		pop hl
		call forth_push_numhl
		pop hl
		call forth_push_numhl
		NEXT

.PAUSE:
	CWHEAD .PAUSES 47 "PAUSEMS" 7 WORD_FLAG_CODE
;   db 47
;	  dw .PAUSES
 ;         db 8
;	  db "PAUSEMS",0	
; | PAUSEMS ( n -- )  Pause for n millisconds | DONE
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		push hl    ; n2
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		pop hl

		ld a, l
		call aDelayInMS
	       NEXT
.PAUSES: 
	CWHEAD .ROT 48 "PAUSE" 5 WORD_FLAG_CODE
;  db 48
;	  dw .ROT
 ;         db 8
;	  db "PAUSES",0	
; | PAUSE ( n -- )  Pause for n seconds | DONE
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		push hl    ; n2
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		pop hl
		ld b, l
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'P'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
.pauses1:	push bc
		call delay1s
		pop bc
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'p'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		djnz .pauses1

	       NEXT
.ROT:
	CWHEAD .SPACE 49 "ROT" 3 WORD_FLAG_CODE
;   db 49
;	  dw .SPACE
 ;         db 4
;	  db "ROT",0	
; | ROT (  -- )  
	       NEXT

.SPACE:
	CWHEAD .SPACES 50 "SPACE" 5 WORD_FLAG_CODE
;   db 50
;	  dw .SPACES
 ;         db 6
;	  db "SPACE",0	
; | SPACE (  -- c ) Push the value of space onto the stack as a string  | DONE
		ld hl, ' '
		call forth_push_numhl
		
	       NEXT

.SPACES:
	CWHEAD .CONCAT 51 "SPACES" 6 WORD_FLAG_CODE
;   db 51
;	  dw .CONCAT
 ;         db 7
;	  db "SPACES",0	
; | SPACES ( u -- str )  A string of u spaces is pushed onto the stack | TO TEST


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'S'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		pop hl
		ld c, l
		ld b, 0
		ld hl, scratch 

		if DEBUG_FORTH_WORDS
			push af
			ld a, 's'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		ld a, ' '
.spaces1:	push bc
		ld (hl),a
		inc hl
		pop bc
		djnz .spaces1
		ld a,0
		ld (hl),a
		ld hl, scratch
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'D'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_apush

	       NEXT
.CONCAT:
	CWHEAD .MIN 52 "CONCAT" 6 WORD_FLAG_CODE
;   db 52
;	  dw .MIN
 ;         db 7
;	  db "CONCAT",0	
; | CONCAT ( s1 s2 -- s3 ) A string of u spaces is pushed onto the stack
	       NEXT

.MIN:
	CWHEAD .MAX 53 "MIN" 3 WORD_FLAG_CODE
;   db 53
;	  dw .MAX
 ;         db 4
;	  db "MIN",0	
; | MIN (  u1 u2 -- u3 ) Whichever is the smallest value is pushed back onto the stack | TEST NO DEBUG
		; get u2

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl   ; u2

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get u1

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl  ; u1

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

 or a      ;clear carry flag
  pop hl    ; u1
  pop de    ; u2
	push hl   ; saved in case hl is lowest
  sbc hl,de
  jr nc,.mincont   	;	if hl >= de, carry flag will be cleared

	pop hl
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'm'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_push_numhl

	       NEXT

.mincont: 
	pop bc   ; tidy up
	ex de , hl 
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'M'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_push_numhl

	       NEXT
.MAX:
	CWHEAD .FIND 54 "MAX" 3 WORD_FLAG_CODE
;   db 54
;	  dw .FIND
 ;         db 4
;	  db "MAX",0	
; | MAX (  u1 u2 -- u3 )  Whichever is the largest value is pushed back onto the stack | TEST NO DEBUG
		; get u2

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl   ; u2

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get u1

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl  ; u1

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

 or a      ;clear carry flag
  pop hl    ; u1
  pop de    ; u2
	push hl   ; saved in case hl is lowest
  sbc hl,de
  jr c,.maxcont   	;	if hl <= de, carry flag will be cleared

	pop hl
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'm'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_push_numhl

	       NEXT

.maxcont: 
	pop bc   ; tidy up
	ex de , hl 
		if DEBUG_FORTH_WORDS
			push af
			ld a, 'M'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
		call forth_push_numhl
	       NEXT

.FIND:
	CWHEAD .LEN 55 "FIND" 4 WORD_FLAG_CODE
;   db 55
;	  dw .LEN
 ;         db 5
;	  db "FIND",0	
; | FIND (  -- )  
	       NEXT

.LEN:
	CWHEAD .CHAR 56 "LEN" 3 WORD_FLAG_CODE
;   db 56
;	  dw .CHAR
 ;         db 4
;	  db "LEN",0	
; | LEN (  u1 -- u2 ) Push the length of the string on TOS
	       NEXT
.CHAR:
	CWHEAD .RND 57 "CHAR" 4 WORD_FLAG_CODE
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

	       NEXT

.RND:
	CWHEAD .WORDS 58 "RND" 3 WORD_FLAG_CODE
;   db 58
;	  dw .WORDS
 ;         db 4
;	  db "RND",0	
; | RND (  -- )  | TO TEST
		call prng16 
		call forth_push_numhl
	       NEXT
.WORDS:
	CWHEAD .UWORDS 59 "WORDS" 5 WORD_FLAG_CODE
;   db 59
;	  dw .UWORDS
 ;         db 6
;	  db "WORDS",0	
; | WORDS (  -- )   List the system and user word dict
	       NEXT

.UWORDS:
	CWHEAD .SPIO 60 "UWORDS" 6 WORD_FLAG_CODE
;   db 60
;	  dw .SPIO
 ;         db 7
;	  db "UWORDS",0	
; | UWORDS (  -- )   List user word dict
	       NEXT

.SPIO:
	CWHEAD .SPII 61 "SPIO" 4 WORD_FLAG_CODE
;   db 61
;	dw .SPII
;	db 5
;	db "SPIO",0      
;| SPIO ( u1 u2 -- ) Send byte u1 to SPI device u2 |  WIP

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u2 - byte

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u1 - addr

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop de   ; u1 - byte

		pop hl   ; u2 - addr

		; TODO Send SPI byte

		ld a, e
		call se_writebyte
		

		NEXT

.SPII:
	CWHEAD .SCROLL 62 "SPII" 5 WORD_FLAG_CODE
;   db 62
;	dw .SCROLL
;	db 5
;	db "SPII",0      
;| SPII ( u1 -- ) Get a byte from SPI device u2 |  WIP

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl


		; TODO Get SPI byte

		call spi_read_byte

		ld h, 0
		ld l, a
		call forth_push_numhl

		NEXT
.SCROLL:
	CWHEAD .BP 63 "SCROLL" 6 WORD_FLAG_CODE
;   db 63
;	dw .BP
;	db 7
;	db "SCROLL",0      
;| SCROLL ( u1 c1 -- ) Scroll u1 lines/chars in direction c1 | WIP

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl

		pop bc

		; TODO Get SPI byte

		NEXT
.BP:
	CWHEAD .MONITOR 64 "BP" 2 WORD_FLAG_CODE
;   db 64
;	dw .MONITOR
;	db 3
;	db "BP",0      
;| BP ( u1 -- ) Enable or disable break point monitoring | TEST
		; get byte count

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop hl

		ld a,0
		cp l
		jr z, .bpset
		ld a, '*'

.bpset:		ld (os_view_disable), a


		NEXT


.MONITOR:
	CWHEAD .MALLOC 65 "MONITOR" 7 WORD_FLAG_CODE
;   db 65
;	dw .MALLOC
;	db 8
;	db "MONITOR",0      
;| MONITOR ( -- ) Display system breakpoint/monitor | DONE
	;	rst 030h
	CALLMONITOR

		NEXT


.MALLOC:
	CWHEAD .FREE 66 "MALLOC" 6 WORD_FLAG_CODE
;   db 66
;	dw .FREE
;	db 7
;	db "MALLOC",0      
;| MALLOC ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | TEST
		; get byte count

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop hl
		call malloc

		call forth_push_numhl
		NEXT

.FREE:
	CWHEAD .STRLEN 67 "FREE" 4 WORD_FLAG_CODE
;   db 67
;	dw .STRLEN
;	db 5
;	db "FREE",0      
;| FREE ( u --  ) Free memory block from malloc given u address  | TEST
		; get address

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop hl
		call free

		NEXT

.STRLEN:
	CWHEAD .STRCPY 68 "STRLEN" 6 WORD_FLAG_CODE
;   db 68
;	dw .STRCPY
;	db 7
;	db "STRLEN",0      
;| STRLEN ( u1 -- Using given address u1 push then zero term length string to TOS )   |

		NEXT

.STRCPY:
	CWHEAD .BSAVE 69 "STRCPY" 6 WORD_FLAG_CODE
;   db 69
;	dw .BSAVE
;	db 7
;	db "STRCPY",0      
;| STRCPY ( u1 u2 -- Copy string u2 to u1 )   |

		NEXT
.BSAVE:  

	CWHEAD .BLOAD 70 "BSAVE" 5 WORD_FLAG_CODE
; db 70
;	dw .BLOAD
;	db 6
;	db "BSAVE",0              ; |BSAVE  ( w u a s -- )    Save binary file to file name w on bank u starting at address a for s bytes
		NEXT
.BLOAD:
	CWHEAD .END 71 "BLOAD" 5 WORD_FLAG_CODE
;   db 71
;	dw .V0
;	db 6
;	db "BLOAD",0               
;| BLOAD ( w u a -- )    Load binary file from file name w on bank u into address u
		NEXT
;;;; counter gap


;.V0:   db 143               
;	dw .V1
;	db 3
;	db "@0",0
;		NEXT
;
;.V1:   db 144               
;	dw .V2
;	db 3
;	db "@1",0
;		NEXT
;
;
;.V2:   db 145               
;	dw .V3
;	db 3
;	db "@2",0
;		NEXT
;
;
;.V3:   db 146               
;	dw .V4
;	db 3
;	db "@3",0
;		NEXT
;
;
;.V4:   db 147              
;	dw .V5
;	db 3
;	db "@4",0
;		NEXT
;
;.V5:   db 148               
;	dw .V6
;	db 3
;	db "@5",0
;		NEXT
;
;.V6:   db 149               
;	dw .V7
;	db 3
;	db "@6",0
;		NEXT
;
;.V7:   db 150               
;	dw .V8
;	db 3
;	db "@7",0
;		NEXT
;
;.V8:   db 151               
;	dw .V9
;	db 3
;	db "@8",0
;		NEXT
;
;.V9:   db 152               
;	dw .I
;	db 3
;	db "@9",0
;		NEXT
;.I:   db 153               
;	dw .END
;	db 2
;	db "I",0               ;| I ( -- ) Loop counter
;		NEXT


; Hardware specific words I may need
;
; IN OUT 
; calls to key util functions
; calls to hardward abstraction stuff
; easy control of frame buffers and lcd i/o
; keyboard 
;.NOP:    db 1
;	dw .END
;	db "NOP",0
;	nop
;	NEXT
;
.END:    db 0
	dw 0
	db 0

; use to jp here for user dict words to save on macro expansion 

user_dict_next:
	NEXT


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
