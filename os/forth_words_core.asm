
; | ## Core Words

;if MALLOC_4

.HEAP:
	CWHEAD .EXEC OPCODE_HEAP "HEAP" 4 WORD_FLAG_CODE
; | HEAP ( -- u1 u2 )   Pushes u1 the current number of bytes in the heap and u2 the remaining bytes - Only present if using my MALLOC | DONE
; | | u1 - Current number of bytes in the heap
; | | u2 - Remaining bytes left on the heap
; | | 
; | | The heap is used for storing user defined words as well as any values pushed to stack.


		if DEBUG_FORTH_WORDS_KEY
			DMARK "HEP"
			CALLMONITOR
		endif
		ld hl, (free_list )     
		ld de, heap_start

		sbc hl, de 

		call forth_push_numhl


		ld de, (free_list )     
		ld hl, heap_end

		sbc hl, de

		call forth_push_numhl
		

		



		NEXTW
;endif

.EXEC:
	CWHEAD .STKEXEC OPCODE_EXEC "EXEC" 4 WORD_FLAG_CODE
; | EXEC ( u -- )    Execs the string on TOS as a FORTH expression | CRASHES ON NEXTW
; | | u - A qutoed string which can consist of any valid Forth expression excluding : defintions (use LOAD instead)
; | |
; | |  
	STACKFRAME OFF $5efe $5f9f

		if DEBUG_FORTH_WORDS_KEY
			DMARK "EXE"
			CALLMONITOR
		endif

	FORTH_DSP_VALUEHL

	FORTH_DSP_POP

		if DEBUG_FORTH_WORDS
			DMARK "EX1"
			CALLMONITOR
		endif
;	ld e,(hl)
;	inc hl
;	ld d,(hl)
;	ex de,hl

		if DEBUG_FORTH_WORDS
			DMARK "EX2"
			CALLMONITOR
		endif
	push hl

	;ld a, 0
	;ld a, FORTH_END_BUFFER
	call strlenz
	inc hl   ; include zero term to copy
	ld b,0
	ld c,l
	pop hl
	ld de, execscratch
		if DEBUG_FORTH_WORDS
			DMARK "EX3"
			CALLMONITOR
		endif
	ldir


	ld hl, execscratch

		if DEBUG_FORTH_WORDS
			DMARK "EXe"
			CALLMONITOR
		endif

	call forthparse
	call forthexec
;	call forthexec_cleanup
;	call forthparse
;	call forthexec

	STACKFRAMECHK OFF $5efe $5f9f

	; an immediate word so no need to process any more words
	ret
	NEXTW

; dead code - old version 
;	FORTH_RSP_NEXT

; 
;	ld bc,(cli_ptr)   ; move to next token to parse in the input stream
;	ld de,(cli_origptr)   ; move to next token to parse in the input stream
;	ld hl,(os_tok_ptr)   ; move to next token to parse in the input stream
;	push hl
;	push de
;	push bc
;
;
;		if DEBUG_FORTH_WORDS_KEY
;			DMARK "EXR"
;			CALLMONITOR
;		endif
;
;
;
;	;v5 FORTH_DSP_VALUE
;	FORTH_DSP_VALUEHL
;
;	; TODO do string type checks
;
;;v5	inc hl   ; skip type
;
;	push hl  ; source code 
;		if DEBUG_FORTH_WORDS
;			DMARK "EX1"
;			CALLMONITOR
;		endif
;	ld a, 0
;	call strlent
;
;	inc hl
;	inc hl
;	inc hl
;	inc hl
;
;	push hl    ; size
;
;		if DEBUG_FORTH_WORDS
;			DMARK "EX2"
;			CALLMONITOR
;		endif
;	call malloc
;
;	ex de, hl    ; de now contains malloc area
;	pop bc   	; get byte count
;	pop hl      ; get string to copy
;
;	push de     ; save malloc for free later
;
;		if DEBUG_FORTH_WORDS
;			DMARK "EX3"
;			CALLMONITOR
;		endif
;	ldir       ; duplicate string
;
;	; at the end of the string so go back the three extra spaces and fill in with extra terms
;	
;	; TODO fix the parse would be better than this... 
;	ex de, hl
;	dec hl
;	ld a, 0
;	ld (hl), a
;	dec hl
;	ld a, ' '
;	ld (hl), a
;	dec hl
;	ld (hl), a
;
;	dec hl
;	ld (hl), a
;
;
;	FORTH_DSP_POP 
;
;	pop hl    
;	push hl    ; save malloc area
;
;		if DEBUG_FORTH_WORDS
;			DMARK "EX4"
;			CALLMONITOR
;		endif
;
;	call forthparse
;	call forthexec
;	
;	pop hl
;	if DEBUG_FORTH_WORDS
;		DMARK "EX5"
;		CALLMONITOR
;	endif
;
;	if FORTH_ENABLE_FREE
;	call free
;	endif
;
;	if DEBUG_FORTH_WORDS
;		DMARK "EX6"
;		CALLMONITOR
;	endif
;
;	pop bc
;	pop de
;	pop hl
;;	FORTH_RSP_POP	 
;	ld (cli_ptr),bc   ; move to next token to parse in the input stream
;	ld (cli_origptr),de   ; move to next token to parse in the input stream
;	ld (os_tok_ptr),hl   ; move to next token to parse in the input stream
;
;	if DEBUG_FORTH_WORDS
;		DMARK "EX7"
;		CALLMONITOR
;	endif
;	NEXTW

.STKEXEC:
	CWHEAD .ZDUP 43 "STKEXEC" 7 WORD_FLAG_CODE
; | STKEXEC ( u .. u c -- ) Taking c count of strings off of the stack the strings are evaluated as code | TO TEST


		if DEBUG_FORTH_WORDS_KEY
			DMARK "STX"
			CALLMONITOR
		endif

	FORTH_DSP_VALUEHL

	ld (store_tmp1), hl    ; count

	FORTH_DSP_POP
.stkexec1:
	ld hl, (store_tmp1)   ; count
	ld a, 0
	cp l
	ret z

	dec hl
	ld (store_tmp1), hl    ; count
	
	FORTH_DSP_VALUEHL
	push hl
	
	FORTH_DSP_POP

	call strlenz
	inc hl   ; include zero term to copy
	ld b,0
	ld c,l
	pop hl
	ld de, execscratch
		if DEBUG_FORTH_WORDS
			DMARK "EX3"
			CALLMONITOR
		endif
	ldir


	ld hl, execscratch

		if DEBUG_FORTH_WORDS
			DMARK "EXe"
			CALLMONITOR
		endif

	call forthparse
	call forthexec

	jp .stkexec1

	ret


.DUP:
	CWHEAD .ZDUP OPCODE_DUP "DUP" 3 WORD_FLAG_CODE
; | DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE

		FORTH_DSP

		ld a, (HL)
		cp DS_TYPE_STR
		jr nz, .dupinum

		; push another string

		FORTH_DSP_VALUEHL     		

	if DEBUG_FORTH_WORDS
		DMARK "DUs"
		CALLMONITOR
	endif
		call forth_push_str

		NEXTW


.dupinum:
		


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

	; TODO add floating point number detection

	if DEBUG_FORTH_WORDS
		DMARK "DUi"
		CALLMONITOR
	endif

		call forth_push_numhl
		NEXTW
.ZDUP:
	CWHEAD .SWAP OPCODE_ZDUP "?DUP" 4 WORD_FLAG_CODE
; | ?DUP ( u -- u u )     Duplicate item on TOS if the item is non-zero | DONE

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; is it a zero?

		ld a, 0
		add h
		add l

		pop hl

		cp 0
		jr z, .dup2orig


		call forth_push_numhl


	; TODO add floating point number detection

.dup2orig:

		NEXTW
.SWAP:
	CWHEAD .COLN OPCODE_SWAP "SWAP" 4 WORD_FLAG_CODE
; | SWAP ( w1 w2 -- w2 w1 )    Swap top two items on TOS | DONE

		FORTH_DSP_VALUEHL
		push hl     ; w2

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

		pop de     ; w2	, hl = w1

		ex de, hl
		push de

		call forth_push_numhl

		pop hl

		call forth_push_numhl
		

		NEXTW
.COLN:
	CWHEAD .SCOLN OPCODE_COLN ":" 1 WORD_FLAG_CODE
; | : ( -- )         Create new word | DONE

	STACKFRAME OFF $8efe $989f
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
			DMARK ":01"
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
			DMARK ":02"
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
			DMARK ":0x"
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
			DMARK ":0A"
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

			DMARK ":0B"
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
			DMARK ":0+"
	CALLMONITOR
endif

	STACKFRAMECHK OFF $8efe $989f

ret    ; dont process any remaining parser tokens as they form new word




;		NEXT
.SCOLN:
;	CWHEAD .DROP 17 '\;' 1 WORD_FLAG_CODE
	db OPCODE_SCOLN
	dw .DROP
	db 2
	db ";",0          
; | ; ( -- )     Terminate new word and return exec to previous exec level | DONE
		FORTH_RSP_TOS
		push hl
		FORTH_RSP_POP
		pop hl
;		ex de,hl
		ld (os_tok_ptr),hl

if DEBUG_FORTH_UWORD
			DMARK "SCL"
	CALLMONITOR
endif
		NEXTW

.DROP:
	CWHEAD .DUP2 OPCODE_DROP "DROP" 4 WORD_FLAG_CODE
; | DROP ( w -- )   drop the TOS item   | DONE
		FORTH_DSP_POP
		NEXTW
.DUP2:
	CWHEAD .DROP2 OPCODE_DUP2 "2DUP" 4 WORD_FLAG_CODE
; | 2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  | DONE
		FORTH_DSP_VALUEHL
		push hl      ; 2

		FORTH_DSP_POP
		
		FORTH_DSP_VALUEHL
;		push hl      ; 1

		FORTH_DSP_POP

;		pop hl       ; 1
		pop de       ; 2

		call forth_push_numhl
		ex de, hl
		call forth_push_numhl

		
		ex de, hl

		call forth_push_numhl
		ex de, hl
		call forth_push_numhl


		NEXTW
.DROP2:
	CWHEAD .SWAP2 OPCODE_DROP2 "2DROP" 5 WORD_FLAG_CODE
; | 2DROP ( w w -- )    Double drop | DONE
		FORTH_DSP_POP
		FORTH_DSP_POP
		NEXTW
.SWAP2:
	CWHEAD .AT OPCODE_SWAP2 "2SWAP" 5 WORD_FLAG_CODE
; | 2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items | TODO
		NEXTW
.AT:
	CWHEAD .CAT OPCODE_AT "@" 1 WORD_FLAG_CODE
; | @ ( w -- ) Push onto TOS byte stored at address   | DONE

.getbyteat:	
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		
;		push hl
	
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

;		pop hl

		ld a, (hl)

		ld l, a
		ld h, 0
		call forth_push_numhl

		NEXTW
.CAT:
	CWHEAD .BANG OPCODE_CAT "C@" 2 WORD_FLAG_CODE
; | C@  ( w -- ) Push onto TOS byte stored at address   | DONE
		jp .getbyteat
		NEXTW
.BANG:
	CWHEAD .CBANG OPCODE_BANG "!" 1 WORD_FLAG_CODE
; | ! ( x w -- ) Store x at address w      | DONE

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
	CWHEAD .SCALL OPCODE_CBANG "C!" 2 WORD_FLAG_CODE
; | C!  ( x w -- ) Store x at address w  | DONE
		jp .storebyteat
		NEXTW
.SCALL:
	CWHEAD .DEPTH OPCODE_SCALL "CALL" 4 WORD_FLAG_CODE
; | CALL ( w -- w  ) machine code call to address w  push the result of hl to stack | DONE

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

			
;		pop hl

		; how to do a call with hl???? save SP?
		call forth_call_hl


		; TODO push value back onto stack for another op etc

		call forth_push_numhl
		NEXTW
.DEPTH:
	CWHEAD .OVER OPCODE_DEPTH "DEPTH" 5 WORD_FLAG_CODE
; | DEPTH ( -- u ) Push count of stack | DONE
		; take current TOS and remove from base value div by two to get count


	ld hl, (cli_data_sp)
	ld de, cli_data_stack
	sbc hl,de
	
	; div by size of stack item

	ld e,l
	ld c, 3
	call Div8

	ld l,a
	ld h,0

	;srl h
	;rr l

		call forth_push_numhl
		NEXTW
.OVER:
	CWHEAD .PAUSE 46 "OVER" 4 WORD_FLAG_CODE
; | OVER ( n1 n2 -- n1 n2 n1 )  Copy one below TOS onto TOS | DONE

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
; | PAUSEMS ( n -- )  Pause for n millisconds | DONE
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
;		push hl    ; n2
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
;		pop hl

		ld a, l
		call aDelayInMS
	       NEXTW
.PAUSES: 
	CWHEAD .ROT 48 "PAUSE" 5 WORD_FLAG_CODE
; | PAUSE ( n -- )  Pause for n seconds | DONE
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
;		push hl    ; n2
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
;		pop hl
		ld b, l
		if DEBUG_FORTH_WORDS
			DMARK "PAU"
			CALLMONITOR
		endif
.pauses1:	push bc
		call delay1s
		pop bc
		if DEBUG_FORTH_WORDS
			DMARK "PA1"
			CALLMONITOR
		endif
		djnz .pauses1

	       NEXTW
.ROT:
	CWHEAD .UWORDS 49 "ROT" 3 WORD_FLAG_CODE
; | ROT ( u1 u2 u3 -- u2 u3 u1 ) Rotate top three items on stack | DONE

		FORTH_DSP_VALUEHL
		push hl    ; u3 

		FORTH_DSP_POP
  
		FORTH_DSP_VALUEHL
		push hl     ; u2

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL
		push hl     ; u1

		FORTH_DSP_POP

		pop bc      ; u1
		pop hl      ; u2
		pop de      ; u3


		push bc
		push de
		push hl


		pop hl
		call forth_push_numhl

		pop hl
		call forth_push_numhl

		pop hl
		call forth_push_numhl
		





	       NEXTW

.UWORDS:
	CWHEAD .BP 60 "UWORDS" 6 WORD_FLAG_CODE
; | UWORDS (  -- s1 ... sn u )   List user word dict | DONE
; | | After use the TOS will have a count of the number of user words that have been pushed to stack.
; | | Following the count are the individual words.
; | |
; | | e.g. UWORDS
; | | BOX DIRLIST 2
; | | 
; | | Can be used to save the words to storage via:
; | | UWORDS $01 DO $01 APPEND LOOP
	if DEBUG_FORTH_WORDS
		DMARK "UWR"
		CALLMONITOR
	endif
		ld hl, baseram
		;ld hl, baseusermem
		ld bc, 0    ; start a counter

	; skip dict stub

		call forth_tok_next


; while we have words to look for

.douscan:	ld a, (hl)     
	if DEBUG_FORTH_WORDS
		DMARK "UWs"
		CALLMONITOR
	endif
		cp WORD_SYS_END
		jr z, .udone
		cp WORD_SYS_UWORD
		jr nz, .nuword

	if DEBUG_FORTH_WORDS
		DMARK "UWu"
		CALLMONITOR
	endif
		; we have a uword so push its name to the stack

	   	push hl  ; save so we can move to next dict block

		; skip opcode
		inc hl 
		; skip next ptr
		inc hl 
		inc hl
		; skip len
		inc hl
	if DEBUG_FORTH_WORDS
		DMARK "UWt"
		CALLMONITOR
	endif
		inc bc

		push bc
		call forth_push_str
		pop bc

		pop hl 	

.nuword:	call forth_tok_next
		jr .douscan 

.udone:		 ; push count of uwords found
		push bc
		pop hl

	if DEBUG_FORTH_WORDS
		DMARK "UWc"
		CALLMONITOR
	endif
		call forth_push_numhl


	       NEXTW

.BP:
	CWHEAD .MONITOR 64 "BP" 2 WORD_FLAG_CODE
; | BP ( u1 -- ) Enable or disable break point monitoring | DONE
; | | $00 Will enable the break points within specific code paths
; | | $01 Will disable break points
; | | 
; | | By default break points are off. Either the above can be used to enable them
; | | or if a key is held down during start up the spashscreen will appear to freeze
; | | and on release of the pressed key a message will be disaplayed to notify
; | | that break points are enabled. Pressing any key will then continue boot process.
		; get byte count

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

;		pop hl

		ld a,0
		cp l
		jr z, .bpset
		ld a, '*'

.bpset:		ld (os_view_disable), a


		NEXTW


.MONITOR:
	CWHEAD .MALLOC 65 "MONITOR" 7 WORD_FLAG_CODE
; | MONITOR ( -- ) Display system breakpoint/monitor | DONE
; | | At start the current various registers will be displayed with contents.
; | | Top right corner will show the most recent debug marker seen.
; | | The bottom of the screen will also show the values of the data stack pointer (DSP)
; | | and the return stack pointer (RSP).
; | | Pressing:
; | |    1 - Initial screen
; | |    2 - Display a data dump of HL
; | |    3 - Display a data dump of DE
; | |    4 - Display a data dump of BC
; | |    5 - Display a data dump of HL
; | |    6 - Display a data dump of DSP
; | |    7 - Display a data dump of RSP
; | |    8 - Display a data dump of what is at DSP
; | |    9 - Display a data dump of what is at RSP
; | |    0 - Exit monitor and continue running. This will also enable break points
; | |    * - Disable break points
; | |    # - Enter traditional monitor mode
; | |
; | | Monitor Mode
; | | ------------
; | | A prompt of '>' will be shown for various commands:
; | |    D xxxx - Display a data dump starting from hex address xxxx
; | |    C - Continue display a data dump from the last set address
; | |    M xxxx - Set start of memory edit at address xx
; | |    U xx - Poke the hex byte xx into the address set by M and increment the address to the next location
; | |    Q - Return to previous
		ld a, 0
		ld (os_view_disable), a

		CALLMONITOR

;	call monitor

		NEXTW


.MALLOC:
	CWHEAD .MALLOC2 66 "ALLOT" 5 WORD_FLAG_CODE
; | ALLOT ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | DONE
		jp .mallocc
.MALLOC2:
	CWHEAD .FREE 66 "MALLOC" 6 WORD_FLAG_CODE
; | MALLOC ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | DONE
		; get byte count
.mallocc:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

;		pop hl
		call malloc
	if DEBUG_FORTH_MALLOC_GUARD
		push af
		call ishlzero
;		ld a, l
;		add h
;		cp 0
		pop af
		
		call z,malloc_error
	endif

		call forth_push_numhl
		NEXTW

.FREE:
	CWHEAD .LIST 67 "FREE" 4 WORD_FLAG_CODE
; | FREE ( u --  ) Free memory block from malloc given u address  | DONE
		; get address

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

;		pop hl
if FORTH_ENABLE_MALLOCFREE
		call free
endif
		NEXTW
.LIST:
	CWHEAD .FORGET 72 "LIST" 4 WORD_FLAG_CODE
; | LIST ( uword -- u )    List the code to the word that is quoted (so as not to exec) on TOS | DONE
; | | The quoted word must be in upper case.
	if DEBUG_FORTH_WORDS
		DMARK "LST"
		CALLMONITOR
	endif

		FORTH_DSP_VALUEHL

		push hl
		pop bc

; Start format of scratch string

		ld hl, scratch

		ld a, ':'
		ld (hl),a
		inc hl
		ld a, ' '
		ld (hl), a

		; Get ptr to the word we need to look up

;		FORTH_DSP_VALUEHL
		;v5 FORTH_DSP_VALUE
	; TODO type check
;		inc hl    ; Skip type check 
;		push hl
;		ex de, hl    ; put into DE


		ld hl, baseram
		;ld hl, baseusermem

push hl   ; sacreifical push

.ldouscanm:
	pop hl
.ldouscan:
	if DEBUG_FORTH_WORDS
		DMARK "LSs"
		CALLMONITOR
	endif
	; skip dict stub
		call forth_tok_next


; while we have words to look for

	ld a, (hl)     
	if DEBUG_FORTH_WORDS
		DMARK "LSk"
		CALLMONITOR
	endif
		cp WORD_SYS_END
		jp z, .lunotfound
		cp WORD_SYS_UWORD
		jp nz, .ldouscan

	if DEBUG_FORTH_WORDS
		DMARK "LSu"
		CALLMONITOR
	endif

		; found a uword but is it the one we want...

		push bc     ; uword to find is on bc
		pop de

		push hl  ; to save the ptr

		; skip opcode
		inc hl 
		; skip next ptr
		inc hl 
		inc hl
		; skip len
		inc hl

	if DEBUG_FORTH_WORDS
		DMARK "LSc"
		CALLMONITOR
	endif
		call strcmp
		jp nz, .ldouscanm
	


		; we have a uword so push its name to the stack

;	   	push hl  ; save so we can move to next dict block
pop hl

	if DEBUG_FORTH_WORDS
		DMARK "LSm"
		CALLMONITOR
	endif

		; skip opcode
		inc hl 
		; skip next ptr
		inc hl 
		inc hl
		; skip len
		ld a, (hl)   ; save length to add
	if DEBUG_FORTH_WORDS
		DMARK "LS2"
		CALLMONITOR
	endif

		; save this location
	
		push hl

		inc hl
		ld de, scratch+2
		ld c, a
		ld b, 0

	if DEBUG_FORTH_WORDS
		DMARK "LSn"
		CALLMONITOR
	endif

		; copy uword name to scratch

		ldir

		dec de
		ld a, ' '    ; change null to space
		ld (de), a

		inc de

		push de
		pop bc     ; move scratch pointer to end of word name and save it

		pop hl
		ld a, (hl)
		;inc hl
		; skip word string
		call addatohl

		inc hl

	if DEBUG_FORTH_WORDS
		DMARK "LS3"
		CALLMONITOR
	endif
		; should now be at the start of the machine code to setup the eval of the uword
		; now locate the ptr to the string defintion

		; skip ld hl,
		; then load the ptr

		inc hl
		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl


	if DEBUG_FORTH_WORDS
		DMARK "LSt"
		CALLMONITOR
	endif

; cant push right now due to tokenised strings 

; get the destination of where to copy this definition to.

		push bc
		pop de

.listl:         ld a,(hl)
		cp 0
		jr z, .lreplsp     ; replace zero with space
		cp FORTH_END_BUFFER
		jr z, .listdone    ; at end of uword defination to close of scratch and finish
	
		; just copy this char as is then

		ld (de), a

.listnxt:	inc hl
		inc de
		jr .listl

.lreplsp:	ld a,' '
		ld (de), a
		jr .listnxt

; close up uword def

.listdone:
		ld a, 0
		ld (de), a

; now have def so clean up and push to stack

		ld hl, scratch
	if DEBUG_FORTH_WORDS
		DMARK "Ltp"
		CALLMONITOR
	endif

	jr .listpush

;.lnuword:	pop hl
;		call forth_tok_next
;		jp .ldouscan 

.lunotfound:		 


		
		FORTH_DSP_POP
		ld hl, .luno
			

.listpush:
		call forth_push_str



		NEXTW

.luno:    db "Not found",0





;		push hl   ; save pointer to start of uword def string
;
;; look for FORTH_EOL_LINE
;		ld a, FORTH_END_BUFFER
;		call strlent
;
;		inc hl		 ; space for coln def
;		inc hl
;		inc hl          ; space for terms
;		inc hl
;
;		ld a, 20   ; TODO get actual length
;		call addatohl    ; include a random amount of room for the uword name
;
;		
;	if DEBUG_FORTH_WORDS
;		DMARK "Lt1"
;		CALLMONITOR
;	endif
;		
;
;; malloc space for the string because we cant change it
;
;		call malloc
;	if DEBUG_FORTH_MALLOC_GUARD
;		push af
;		call ishlzero
;		pop af
;		
;		call z,malloc_error
;	endif
;
;	if DEBUG_FORTH_WORDS
;		DMARK "Lt2"
;		CALLMONITOR
;	endif
;		pop de
;		push hl    ; push the malloc to release later
;		push hl   ;  push back a copy for the later stack push
;		
;; copy the string swapping out the zero terms for spaces
;
;		; de has our source
;		; hl has our dest
;
;; add the coln def
;
;		ld a, ':'
;		ld (hl), a
;		inc hl
;		ld a, ' '
;		ld (hl), a
;		inc hl
;
;; add the uname word
;		push de   ; save our string for now
;		ex de, hl
;
;		FORTH_DSP_VALUE
;		;v5 FORTH_DSP_VALUE
;
;		inc hl   ; skip type but we know by now this is OK
;
;.luword:	ld a,(hl)
;		cp 0
;		jr z, .luword2
;		ld (de), a
;		inc de
;		inc hl
;		jr .luword
;
;.luword2:	ld a, ' '
;		ld (de), a
;;		inc hl
;;		inc de
;;		ld (de), a
;;		inc hl
;		inc de
;
;		ex de, hl
;		pop de
;		
;		
;
;; detoken that string and copy it
;
;	if DEBUG_FORTH_WORDS
;		DMARK "Lt2"
;		CALLMONITOR
;	endif
;.ldetok:	ld a, (de)
;		cp FORTH_END_BUFFER
;		jr z, .ldetokend
;		; swap out any zero term for space
;		cp 0
;		jr nz, .ldetoknext
;		ld a, ' '
;
;	if DEBUG_FORTH_WORDS
;		DMARK "LtS"
;		CALLMONITOR
;	endif
;.ldetoknext:	ld (hl), a
;		inc de
;		inc hl
;		jr .ldetok
;
;.ldetokend:	ld a, 0    ; replace forth eol with string term for pushing
;		ld (hl), a 
;
;; free that temp malloc
;
;		pop hl   
;
;	if DEBUG_FORTH_WORDS
;		DMARK "Lt4"
;		CALLMONITOR
;	endif
;		call forth_apushstrhl
;
;		; get rid of temp malloc area
;
;		pop hl
;		call free
;
;		jr .ludone
;
;.lnuword:	pop hl
;		call forth_tok_next
;		jp .ldouscan 
;
;.ludone:		 pop hl
;
		NEXTW

.FORGET:
	CWHEAD .NOP 73 "FORGET" 6 WORD_FLAG_CODE
; | FORGET ( uword -- )    Forget the uword on TOS | DONE
; | | Will flag the word's op code to be deleted as well as replace the first char of the word with '_'.

	; find uword
        ; update start of word with "_"
	; replace uword with deleted flag


	if DEBUG_FORTH_WORDS
		DMARK "FOG"
		CALLMONITOR
	endif


		; Get ptr to the word we need to look up

		FORTH_DSP
		;v5 FORTH_DSP_VALUE
	; TODO type check
		inc hl    ; Skip type check 
		push hl
;		ex de, hl    ; put into DE


		ld hl, baseram
		;ld hl, baseusermem

	; skip dict stub
		call forth_tok_next


; while we have words to look for

.fdouscan:	ld a, (hl)     
	if DEBUG_FORTH_WORDS
		DMARK "LSs"
		CALLMONITOR
	endif
		cp WORD_SYS_END
		jp z, .fudone
		cp WORD_SYS_UWORD
		jp nz, .fnuword

	if DEBUG_FORTH_WORDS
		DMARK "FGu"
		CALLMONITOR
	endif

		; found a uword but is it the one we want...


	        pop de   ; get back the dsp name
		push de

		push hl  ; to save the ptr

		; skip opcode
		inc hl 
		; skip next ptr
		inc hl 
		inc hl
		; skip len
		inc hl

	if DEBUG_FORTH_WORDS
		DMARK "FGc"
		CALLMONITOR
	endif
		call strcmp
		jp nz, .fnuword
	
	if DEBUG_FORTH_WORDS
		DMARK "FGm"
		CALLMONITOR
	endif



		; we have a uword so push its name to the stack

;	   	push hl  ; save so we can move to next dict block
pop hl

		; update opcode to deleted
		ld a, WORD_SYS_DELETED
		ld (hl), a

		inc hl 
		; skip next ptr
		inc hl 
		inc hl
		; skip len
		inc hl

		; TODO change parser to skip deleted words but for now mark it out
		ld a, "_"
		ld  (hl),a

		jr .fudone

.fnuword:	pop hl
		call forth_tok_next
		jp .fdouscan 

.fudone:		 pop hl
		NEXTW
.NOP:
	CWHEAD .COMO 77 "NOP" 3 WORD_FLAG_CODE
; | NOP (  --  ) Do nothing | DONE
	       NEXTW
.COMO:
	CWHEAD .COMC 90 "(" 1 WORD_FLAG_CODE
; | ( ( -- )  Start of comment | DONE


		ld hl, ( os_tok_ptr)
	ld de, .closepar
		
		if DEBUG_FORTH_WORDS
			DMARK ").."
			CALLMONITOR
		endif
	call findnexttok 

		if DEBUG_FORTH_WORDS
			DMARK "IF5"
			CALLMONITOR
		endif
	; replace below with ) exec using tok_ptr
	ld (os_tok_ptr), hl
	jp exec1

	.closepar:   db ")",0

	       NEXTW
.COMC:
	CWHEAD .SCRATCH 91 ")" 1 WORD_FLAG_CODE
; | ) ( -- )  End of comment |  DONE 
	       NEXTW

.SCRATCH:
	CWHEAD .INC 91 "SCRATCH" 7 WORD_FLAG_CODE
; | SCRATCH ( u -- addr ) Pushes address of offset u to stack | DONE
; | | The scratch area provides 32 word array. Can be used as single byte or as a word by passing the offset on stack. Pushes the resulting address to stack. 
; | | When used with the direct storage writing/malloc and the !@ or word versions it is possible to construct an expanded and flexible variable system
; | | 
; | | e.g.    : score $00 scratch ;
; | | 
; | | $00 score !
; | | $01 score +!
; | | 
; | | e.g.   : varword $0a scratch ; 
; | |
; | | $8000 varword !

		FORTH_DSP_VALUEHL
	
		FORTH_DSP_POP

		ld a, l
		ld hl, os_var_array
		call addatohl

		call forth_push_numhl

	       NEXTW

.INC:
	CWHEAD .DEC 91 "+!" 2 WORD_FLAG_CODE
; | +! ( u a -- )  Increment byte at address a by the value u | DONE

		FORTH_DSP_VALUEHL

		push hl   ; save address

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

		; hl contains value to add to byte at a
	
		ex de, hl

		pop hl

		if DEBUG_FORTH_WORDS
			DMARK "INC"
			CALLMONITOR
		endif

		ld a,(hl)
		add e
		ld (hl),a



	       NEXTW

.DEC:
	CWHEAD .INC2 91 "-!" 2 WORD_FLAG_CODE
; | -! ( u a -- )  Decrement byte at address a by the value u | DONE

		FORTH_DSP_VALUEHL

		push hl   ; save address

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		; hl contains value to add to byte at a
	
		ex de, hl

		pop hl

		if DEBUG_FORTH_WORDS
			DMARK "DEC"
			CALLMONITOR
		endif

		ld a,(hl)
		sub e
		ld (hl),a



	       NEXTW

.INC2:
	CWHEAD .DEC2 91 "+2!" 3 WORD_FLAG_CODE
; | +2! ( u a -- )  Increment word at address a by the value u | DONE

		if DEBUG_FORTH_WORDS
			DMARK "+2!"
			CALLMONITOR
		endif

		; Address

		FORTH_DSP_VALUEHL

		push hl    ; save address

		; load content into de

		ld e,(hl)
		inc hl
		ld d, (hl)

		if DEBUG_FORTH_WORDS
			DMARK "+2a"
			CALLMONITOR
		endif

		FORTH_DSP_POP

		; Get value to add

		FORTH_DSP_VALUE

		if DEBUG_FORTH_WORDS
			DMARK "+2v"
			CALLMONITOR
		endif

		add hl, de

		if DEBUG_FORTH_WORDS
			DMARK "+2+"
			CALLMONITOR
		endif

		; move result to de

		ex de, hl

		; Address

		pop hl

		; save it back

		ld (hl), e
		inc hl
		ld (hl), d

		if DEBUG_FORTH_WORDS
			DMARK "+2e"
			CALLMONITOR
		endif





	       NEXTW

.DEC2:
	CWHEAD .GET2 91 "-2!" 3 WORD_FLAG_CODE
; | -2! ( u a -- )  Decrement word at address a by the value u | DONE


		if DEBUG_FORTH_WORDS
			DMARK "-2!"
			CALLMONITOR
		endif

		; Address

		FORTH_DSP_VALUEHL

		push hl    ; save address

		; load content into de

		ld e,(hl)
		inc hl
		ld d, (hl)

		if DEBUG_FORTH_WORDS
			DMARK "-2a"
			CALLMONITOR
		endif

		FORTH_DSP_POP

		; Get value to remove

		FORTH_DSP_VALUE

		if DEBUG_FORTH_WORDS
			DMARK "-2v"
			CALLMONITOR
		endif

		ex de, hl
		sbc hl, de

		if DEBUG_FORTH_WORDS
			DMARK "-2d"
			CALLMONITOR
		endif

		; move result to de

		ex de, hl

		; Address

		pop hl

		; save it back

		ld (hl), e
		inc hl
		ld (hl), d

		if DEBUG_FORTH_WORDS
			DMARK "-2e"
			CALLMONITOR
		endif





	       NEXTW
.GET2:
	CWHEAD .BANG2 91 "2@" 2 WORD_FLAG_CODE
; | 2@ ( a -- u )  Push word at address a onto stack | DONE

		FORTH_DSP_VALUEHL

		ld e, (hl)
		inc hl
		ld d, (hl)

		ex de, hl

		call forth_push_numhl

	       NEXTW
.BANG2:
	CWHEAD .ENDCORE 91 "2!" 2 WORD_FLAG_CODE
; | 2! ( u a -- )  Store value u as a word at address a | DONE

		FORTH_DSP_VALUEHL

		push hl   ; save address


		FORTH_DSP_POP

		
		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

		ex de, hl    ; value now in de

		pop hl

		ld (hl), e

		inc hl

		ld (hl), d


	       NEXTW
.ENDCORE:

; eof


