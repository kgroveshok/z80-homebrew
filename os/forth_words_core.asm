
.DUP:
	CWHEAD .SWAP 6 "DUP" 3 WORD_FLAG_CODE
;	db 6
;	dw .EMIT
;	db 4
;	db "DUP",0   
; | DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

	; TODO add floating point number detection
		call forth_push_numhl
		NEXTW
.SWAP:
	CWHEAD .COLN 9 "SWAP" 4 WORD_FLAG_CODE
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

		NEXTW
.COLN:
	CWHEAD .SCOLN 15 ":" 1 WORD_FLAG_CODE
;	db 15
;	dw .DROP
;	db 2
;	db ":",0     
; |: ( -- )         Create new word |  DONE

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
	inc hl     ; TODO how many do we really need?     maybe only 6
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

; update word dict linked list for new word


ld hl, (os_last_new_uword)		; get the start of the last added uword
inc hl     ; move to next work linked list ptr

ld de, (os_new_malloc)		 ; new next word
ld (hl), e
inc hl
ld (hl), d

if DEBUG_FORTH_UWORD
	ld bc, (os_last_new_uword)		; get the last word so we can check it worked in debug
endif

ld (os_last_new_uword), de      ; update last new uword ptr


if DEBUG_FORTH_UWORD
	push af
	ld a, '+'
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
; |; ( -- )     Terminate new word and return exec to previous exec level | DONE
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
		NEXTW

.DROP:
	CWHEAD .DUP2 17 "DROP" 4 WORD_FLAG_CODE
;   db 17
;	dw .DUP2
;	db 5
;	db "DROP",0        
; |DROP ( w -- )   drop the TOS item   |DONE
		FORTH_DSP_POP
		NEXTW
.DUP2:
	CWHEAD .DROP2 18 "2DUP" 4 WORD_FLAG_CODE
;	db 18
;	dw .DROP2
;	db 5
;	db "2DUP",0      i
; |2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  
		NEXTW
.DROP2:
	CWHEAD .SWAP2 19 "2DROP" 5 WORD_FLAG_CODE
;	db 19
;	dw .SWAP2
;	db 6
;	db "2DROP",0      
; |2DROP ( w w -- )    Double drop | DONE
		FORTH_DSP_POP
		FORTH_DSP_POP
		NEXTW
.SWAP2:
	CWHEAD .AT 20 "2SWAP" 5 WORD_FLAG_CODE
;	db 20
;	dw .AT
;	db 5
;	db "2SWAP",0      
; |2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items
		NEXTW
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

		NEXTW
.CAT:
	CWHEAD .BANG 22 "C@" 2 WORD_FLAG_CODE
;	db 22
;	dw .BANG
;	db 3
;	db "C@",0        
; |C@  ( w -- ) Push onto TOS byte stored at address   |DONE
		jp .getbyteat
		NEXTW
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


		NEXTW
.CBANG:
	CWHEAD .SCALL 24 "C!" 2 WORD_FLAG_CODE
;	db 24
;	dw .LZERO
;	db 3
;	db "C!",0       
; |C!  ( x w -- ) Store x at address w  | DONE
		jp .storebyteat
		NEXTW
.SCALL:
	CWHEAD .DEPTH 30 "CALL" 4 WORD_FLAG_CODE
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
		NEXTW
.DEPTH:
	CWHEAD .OVER 37 "DEPTH" 5 WORD_FLAG_CODE
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
		NEXTW
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
		NEXTW

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
	       NEXTW
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

	       NEXTW
.ROT:
	CWHEAD .WORDS 49 "ROT" 3 WORD_FLAG_CODE
;   db 49
;	  dw .SPACE
 ;         db 4
;	  db "ROT",0	
; | ROT (  -- )  
	       NEXTW
.WORDS:
	CWHEAD .UWORDS 59 "WORDS" 5 WORD_FLAG_CODE
;   db 59
;	  dw .UWORDS
 ;         db 6
;	  db "WORDS",0	
; | WORDS (  -- )   List the system and user word dict
	       NEXTW

.UWORDS:
	CWHEAD .BP 60 "UWORDS" 6 WORD_FLAG_CODE
;   db 60
;	  dw .SPIO
 ;         db 7
;	  db "UWORDS",0	
; | UWORDS (  -- )   List user word dict
	       NEXTW

.BP:
	CWHEAD .MONITOR 64 "BP" 2 WORD_FLAG_CODE
;   db 64
;	dw .MONITOR
;	db 3
;	db "BP",0      
;| BP ( u1 -- ) Enable or disable break point monitoring | DONE
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


		NEXTW


.MONITOR:
	CWHEAD .MALLOC 65 "MONITOR" 7 WORD_FLAG_CODE
;   db 65
;	dw .MALLOC
;	db 8
;	db "MONITOR",0      
;| MONITOR ( -- ) Display system breakpoint/monitor | DONE
	;	rst 030h
	CALLMONITOR

		NEXTW


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
		NEXTW

.FREE:
	CWHEAD .LIST 67 "FREE" 4 WORD_FLAG_CODE
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

		NEXTW
.LIST:
	CWHEAD .FORGET 72 "LIST" 4 WORD_FLAG_CODE
;| LIST ( uword -- )    List the code to the word on TOS
		NEXTW

.FORGET:
	CWHEAD .NOP 73 "FORGET" 6 WORD_FLAG_CODE
;| FORGET ( uword -- )    Forget the uword on TOS

		NEXTW
.NOP:
	CWHEAD .COMO 77 "NOP" 3 WORD_FLAG_CODE
; | NOP (  --  ) Do nothing | DONE
	       NEXTW
.COMO:
	CWHEAD .COMC 90 "(" 1 WORD_FLAG_CODE
;| ( ( -- )  Start of comment |
	       NEXTW
.COMC:
	CWHEAD .ENDCORE 91 ")" 1 WORD_FLAG_CODE
;| ) ( -- )  End of comment |
	       NEXTW



.ENDCORE:

; eof


