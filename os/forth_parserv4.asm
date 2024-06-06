

; new parser. restructing to handle nested loops and better scanning of word tokens

WORD_SYS_LOWPRIM: equ 2    ; Offset for low level prim words opcode
WORD_SYS_BRANCH: equ 10    ; Offset for branching and loop words opcode
WORD_SYS_UWORD: equ 1   ; Opcode for all user words
WORD_SYS_DELETED: equ 2 ; Op code for a deleted UWORD
WORD_SYS_CORE: equ 20    ; Offset for dict core words opcode
WORD_FLAG_CODE: equ 0	   ; opcodeflag to exec pure code for this word
WORD_FLAG_JP: equ 1	   ; opcodeflag to list zero term jump table words

; Core word preamble macro

CWHEAD:   macro nxtword opcode lit len opflags
	db WORD_SYS_CORE+opcode            
	; internal op code number
	dw nxtword           
	; link to next dict word block
	db len + 1
	; literal length of dict word inc zero term
	db lit,0             
	; literal dict word
        ; TODO db opflags       
	endm


NEXTW: macro 
	jp macro_next
	endm

macro_next:
if DEBUG_FORTH_PARSE_KEY
	DMARK "NXT"
	CALLMONITOR
endif	
;	inc hl  ; skip token null term 
	ld bc,(cli_ptr)   ; move to next token to parse in the input stream
	ld de,(cli_origptr)   ; move to next token to parse in the input stream
	ld hl,(os_tok_ptr)   ; move to next token to parse in the input stream
if DEBUG_FORTH_PARSE_KEY
	DMARK "}AA"
	CALLMONITOR
endif	
	jp execnext
	;jp exec1
      




; Another go at the parser need to simplify the process

forthparse:

;
; line parse:
;       parse raw input buffer
;       tokenise the words
;       malloc new copy (for looping etc)
;       copy to malloc + current pc in line to start of string and add line term
;       save on new rsp
;

; hl to point to the line to tokenise

	push hl
	ld (os_tok_ptr), hl  ; save ptr to string

	ld a,0		; string term on input
	call strlent

	ld (os_tok_len), hl	 ; save string length

if DEBUG_FORTH_TOK
	ex de,hl		
endif

	pop hl 		; get back string pointer

if DEBUG_FORTH_TOK
			DMARK "TOK"
	CALLMONITOR
endif
.ptoken2:    ld a,(hl)
	inc hl
	cp FORTH_END_BUFFER
	jr z, .ptokendone2
	cp 0
	jr z, .ptokendone2
	cp '"'
	jr z, .ptokenstr2     ; will want to skip until end of string delim
	cp ' '
	jr nz,  .ptoken2

; TODO consume comments held between ( and )

	; we have a space so change to zero term for dict match later
	dec hl
	ld a,0
	ld (hl), a
	inc hl
	jr .ptoken2
	

.ptokenstr2:
	; skip all white space until either eol (because forgot to term) or end double quote
        ;   if double quotes spotted ensure to skip any space sep until matched doble quote
	;inc hl ; skip current double quote
	ld a,(hl)
	inc hl
	cp '"'
	jr z, .ptoken2
	cp FORTH_END_BUFFER
	jr z, .ptokendone2
	cp 0
	jr z, .ptokendone2
	cp ' '
	jr z, .ptmp2
	jr .ptokenstr2

.ptmp2:	; we have a space so change to zero term for dict match later
	;dec hl
	;ld a,"-"	; TODO remove this when working
	;ld (hl), a
	;inc hl
	jr .ptokenstr2

.ptokendone2:

if DEBUG_FORTH_TOK
	ld hl,(os_tok_ptr)
			DMARK "TK1"
	CALLMONITOR
endif

	; malloc size + buffer pointer + if is loop flag
	ld hl,(os_tok_len) 		 ; get string length

	ld a,l

	cp 0			; we dont want to use a null string
	ret z

;	add 3    ; prefix malloc with buffer for current word ptr

	add 5     ; TODO when certain not over writing memory remove

		

if DEBUG_FORTH_TOK
			DMARK "TKE"
	CALLMONITOR
endif

	ld l,a
	ld h,0
;	push hl   ; save required space for the copy later
	call malloc
if DEBUG_FORTH_TOK
			DMARK "TKM"
	CALLMONITOR
endif
	if DEBUG_FORTH_MALLOC_GUARD
		push af
		call ishlzero
;		ld a, l
;		add h
;		cp 0
		pop af
		
		call z,malloc_error
	endif
	ld (os_tok_malloc), hl	 ; save malloc ptr


if DEBUG_FORTH_TOK
			DMARK "TKR"
	CALLMONITOR
endif

	FORTH_RSP_NEXT

	;inc hl	 ; go past current buffer pointer
	;inc hl
	;inc hl   ; and past if loop flag
		; TODO Need to set flag 

	
	
	ex de,hl	; malloc is dest
	ld hl, (os_tok_len)
;	pop bc
	ld c, l               
	ld b,0
	ld hl, (os_tok_ptr)

if DEBUG_FORTH_TOK
			DMARK "TKT"
	CALLMONITOR
endif

	; do str cpy

	ldir      ; copy byte in hl to de

	; set end of buffer to high bit on zero term and use that for end of buffer scan

if DEBUG_FORTH_TOK

			DMARK "TKY"
	CALLMONITOR
endif
	;ld a,0
	;ld a,FORTH_END_BUFFER
	ex de, hl
	;dec hl			 ; go back over the space delim at the end of word
	;ld (hl),a
	;inc hl                    ;  TODO double check this. Going past the end of string to make sure end of processing buffer is marked
	ld a,FORTH_END_BUFFER
	ld (hl),a
	inc hl
	ld a,FORTH_END_BUFFER
	ld (hl),a

	; init the malloc area data
	; set pc for in current area
	;ld hl, (os_tok_malloc)
	;inc hl
	;inc hl
	;inc hl
	;ex de,hl
	;ld hl, (os_tok_malloc)
	;ld (hl),e
	;inc hl
	;ld (hl),d


	ld hl,(os_tok_malloc)
if DEBUG_FORTH_PARSE_KEY
			DMARK "TKU"
	CALLMONITOR
endif

	ret

forthexec:

; line exec:
; forth parser

;
;       get current exec line on rsp

	FORTH_RSP_TOS

;       restore current pc - hl points to malloc of data

	;ld e, (hl)
	;inc hl
	;ld d, (hl)
	;ex de,hl


exec1:
	ld (os_tok_ptr), hl

	; copy our PC to working vars 
	ld (cli_ptr), hl
	ld (cli_origptr), hl

	ld a,(hl)
	cp FORTH_END_BUFFER
	ret z

	; skip any nulls

	cp 0
	jr nz, .execword
	inc hl
	jr exec1


.execword:



if DEBUG_FORTH_PARSE_KEY
			DMARK "KYQ"
	CALLMONITOR
endif
;       while at start of word:
; get start of dict (in user area first)

ld hl, baseusermem
;ld hl, sysdict
ld (cli_nextword),hl
;           match word at pc
;           exec word
;           or push to dsp
;           forward to next token
;           if line term pop rsp and exit
;       


;
; word comp
;    get compiled byte and save it (need to decide if code is compiled or not for comparison)
;    if byte is 0 then end parsing and report failed lookup (or could be something to add to stack etc)
;    move to start of word 
;    compare word to cli_token

.execpnword:	; HL at start of a word in the dictionary to check
;	ld hl,(cli_origptr)	 ; reset start of word to look up
;	ld (cli_ptr), hl

	ld hl,(cli_nextword)
	; TODO skip compiled symbol for now

	inc hl

	; save pointer to next word

	; hl now points to the address of the next word pointer 
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc l

	ex de,hl
if DEBUG_FORTH_PARSE_NEXTWORD
	push bc
	ld bc, (cli_nextword)
			DMARK "NXW"
	CALLMONITOR
	pop bc
endif
	ld (cli_nextword), hl     ; save for next check if no match on this word
	ex de, hl


	; save the pointer of the current token - 1 to check against
	
	ld (cli_token), hl  
	; TODO maybe remove below save if no debug
	; save token string ptr for any debug later
	inc hl 
	ld (cli_origtoken), hl
	dec hl
	; save pointer to the start of the next dictionay word
	ld a,(hl)   ; get string length
	ld b,a
.execpnwordinc: 
	inc hl
	djnz .execpnwordinc
	ld (cli_execword), hl      ; save start of this words code

	; now check the word token against the string being parsed

	ld hl,(cli_token)
	inc hl     ; skip string length (use zero term instead to end)
	ld (cli_token), hl

if DEBUG_FORTH_PARSE_EXEC
	; see if disabled

	ld a, (os_view_disable)
	cp '*'
	jr z, .skip

	push hl
	push hl
	call clear_display
	ld de, .compword
	ld a, display_row_1
	call str_at_display
	pop de
	ld a, display_row_2
	call str_at_display
	ld hl,(cli_ptr)
	ld a,(hl)
        ld hl, os_word_scratch
	ld (hl),a
	ld a,0
	inc hl
	ld (hl),a 	
	ld de, os_word_scratch
	ld a, display_row_2+10
	call str_at_display
	call update_display
	ld a, 100
	call aDelayInMS
	if DEBUG_FORTH_PARSE_EXEC_SLOW
	call delay250ms
	endif
	pop hl
.skip: 
endif	
.execpnchar:    ; compare char between token and string to parse

if DEBUG_FORTH_PARSE_EXEC
	; see if disabled

	ld a, (os_view_disable)
	cp '*'
	jr z, .skip2

;	call clear_display
ld hl,(cli_token)
ld a,(hl)
ld (os_word_scratch),a
	ld hl,(cli_ptr)
ld a,(hl)
	ld (os_word_scratch+1),a
	ld a,0
	ld (os_word_scratch+2),a
	ld de,os_word_scratch
	ld a,display_row_4
	call str_at_display
	call update_display
.skip2: 
endif
	ld hl,(cli_token)
	ld a, (hl)	 ; char in word token
	inc hl 		; move to next char
	ld (cli_token), hl ; and save it
	ld b,a

	ld hl,(cli_ptr) ;	get the char from the string to parse
	ld a,(hl)
	inc hl
	ld (cli_ptr), hl		; move to next char
	call toUpper 		; make sure the input string matches case

if DEBUG_FORTH_PARSE
endif

	; input stream end of token is a space so get rid of it

;	cp ' '
;	jr nz, .pnskipspace
;
;	ld a, 0		; make same term as word token term
;
;.pnskipspace:

	cp b
	jp nz, .execpnskipword	 ; no match so move to next word
	
;    if same
;       scan for string terms 0 for token and 32 for input

	

	add b			
	cp 0			 ; add both chars together, if 32 then other must be 0 so at end of string we are parsing?
				; TODO need to make sure last word in zero term string is accounted for
	jr nz, .execpnchar 		 ; not at end of strings yet


	; at end of both strings so both are exact match

;       skip ptr for next word

	ld hl,(cli_ptr) 	; at input string term
	inc hl			 ; at next char
	ld (cli_ptr), hl     ; save for next round of the parser
	ld (cli_origptr), hl     ; save for any restart of current string ie a number or string to push to data stack
	
	



;       exec code block
if DEBUG_FORTH_JP
	call clear_display
	call update_display
	call delay1s
	ld hl, (cli_execword)     ; save for next check if no match on this word
	ld a,h
	ld hl, os_word_scratch
	call hexout
	ld hl, (cli_execword)     ; save for next check if no match on this word
	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
	call str_at_display
		ld a, display_row_2
		call str_at_display
	ld de, (cli_origtoken)
	ld a, display_row_1+10
		call str_at_display

	ld a,display_row_1
	ld de, .foundword
	ld a, display_row_3
	call str_at_display
	call update_display
	call delay1s
	call delay1s
	call delay1s
endif

	; TODO save the word pointer in this exec

	ld hl,(cli_execword)
	jp (hl)


;    if not same
;	scan for zero term
;	get ptr for next word
;	goto word comp

.execpnskipword:	; get pointer to next word
	ld hl,(cli_nextword)

	ld a,(hl)
	cp 0
	jr z, .execendofdict			 ; at end of words

if DEBUG_FORTH_PARSE_EXEC

	; see if disabled

	ld a, (os_view_disable)
	cp '*'
	jr z, .noskip


	ld de, .nowordfound
	ld a, display_row_3
	call str_at_display
	call update_display
	ld a, 100
	call aDelayInMS
	
	if DEBUG_FORTH_PARSE_EXEC_SLOW
		call delay250ms
	endif
.noskip: 

endif	

	ld hl,(cli_origptr)
	ld (cli_ptr),hl

	jp .execpnword			; else go to next word

.execendofdict: 

if DEBUG_FORTH_PARSE_EXEC
	; see if disabled

	ld a, (os_view_disable)
	cp '*'
	jr z, .ispskip

	call clear_display
	call update_display
	call delay1s
	ld de, (cli_origptr)
	ld a, display_row_1
	call str_at_display
	
	ld de, .enddict
	ld a, display_row_3
	call str_at_display
	call update_display
	ld a, 100
	call aDelayInMS
	if DEBUG_FORTH_PARSE_EXEC_SLOW
	call delay1s
	call delay1s
	call delay1s
	endif
.ispskip: 
	
endif	



	; if the word is not a keyword then must be a literal so push it to stack

; push token to stack to end of word


ld hl,(os_tok_ptr)
call forth_apush

execnext:

; move past token to next word

ld hl, (os_tok_ptr)
ld a, 0
ld bc, 255     ; input buffer size
cpir

if DEBUG_FORTH_PARSE_KEY
			DMARK "KY!"
	CALLMONITOR
endif	
; TODO this might place hl on the null, so will need to forward on???
;inc hl   ; see if this gets onto the next item


; TODO pass a pointer to the buffer to push
; TODO call function to push

; look for end of input

;inc hl
;ld a,(hl)
;cp FORTH_END_BUFFER
;ret z


jp exec1








; push a number held in HL onto the data stack

forth_push_numhl:

	jp .faprawhl
	ret

; move cli_ptr to start of next word in cli_buffer 


; TODO ascii push input onto stack given hl to start of input

; identify type
; if starts with a " then a string
; otherwise it is a number
; 
; if a string
;     scan for ending " to get length of string to malloc for + 1
;     malloc
;     put pointer to string on stack first byte flags as string
;
; else a number
;    look for number format identifier
;    $xx hex
;    bxxxxx bin
;    xxxxx decimal
;    convert number to 16bit word. 
;    malloc word + 1 with flag to identiy as num
;    put pointer to number on stack
;  
; 
 
forth_apush:
	; kernel push

if DEBUG_FORTH_PUSH
			DMARK "PSH"
	CALLMONITOR
endif	
	; identify input type

	ld a,(hl)
	cp '"'
	jr z, .fapstr
	cp '$'
	jp z, .faphex
;	cp 'b'
;	jp z, .fabin
	; else decimal

	; TODO do decimal conversion
	; decimal is stored as a 16bit word

	; by default everything is a string if type is not detected
	jp .defstr


.fapstr:

if DEBUG_FORTH_PUSH
			DMARK "PSQ"
	CALLMONITOR
endif	
   
	; get string length
	inc hl ; skip past current double quote and look for the last one
	ld (cli_origptr), hl
	push hl
	push hl

if DEBUG_FORTH_PUSH
			DMARK "PQ1"
	CALLMONITOR
endif	
	ld a, 0   ; find end of string
	call strlent      
if DEBUG_FORTH_PUSH
			DMARK "PQ2"
	CALLMONITOR
endif	
	ex de, hl
	pop hl   ; get ptr to start of string
if DEBUG_FORTH_PUSH
			DMARK "PQ3"
	CALLMONITOR
endif	
	add hl,de
if DEBUG_FORTH_PUSH
			DMARK "PQE"
	CALLMONITOR
endif	

	dec hl    ; see if there is an optional trailing double quote
	ld a,(hl)
	cp '"'
	jr nz, .strnoq
	ld a, 0      ; get rid of double quote
	ld (hl), a
.strnoq: inc hl

	ld a, 0
	ld (hl), a     ; add null term and get rid of trailing double quote

	pop hl
.defstr:	
if DEBUG_FORTH_PUSH
			DMARK "PDF"
	CALLMONITOR
endif	
	ld a, 0    ; set null string term
	call strlent      

	ld a,l

	inc a ; add one for the type string
	inc a ; add one for null term???

if DEBUG_FORTH_PUSH
			DMARK "PH1"
	CALLMONITOR
endif	
	;push af
if DEBUG_FORTH_PUSH
	; see if disabled
	push af

	ld a, (os_view_disable)
	cp '*'
	jr z, .pskip1

	call clear_display
	ld de, (cli_origptr)
	ld a, display_row_2
	call str_at_display
	pop af
	push af
	ld hl, os_word_scratch
	call hexout
	ld hl,os_word_scratch+2
	ld a,0
	ld (hl),a  
	ld de, os_word_scratch
	ld a, display_row_3
	call str_at_display


	ld de, .push_str
	ld a, display_row_1
	call str_at_display
	call update_display
	call delay1s
	call delay1s
.pskip1:
	pop af
endif	

	; TODO malloc + 1

	add 5    ; to be safe for some reason - max of 255 char for string
	ld h,0
	ld l,a
if DEBUG_FORTH_PUSH
			DMARK "PH2"
	CALLMONITOR
endif	
	call malloc	; on ret hl now contains allocated memory
if DEBUG_FORTH_PUSH
			DMARK "PH3"
	CALLMONITOR
endif	
	if DEBUG_FORTH_MALLOC_GUARD
		call z,malloc_error
	endif

	push hl
if DEBUG_FORTH_PUSH
			DMARK "PH4"
	CALLMONITOR
endif	

	; flag set as str


	ld (hl), DS_TYPE_STR
	inc hl

	; copy string to malloc area

	ex de,hl
	ld hl, (cli_origptr)
	ld b,0
	ld c, a

; BUG memory over write of malloc structures. This dec resolves the issue - not a huge problem as 5 bytes are added to any string length above.
; is it related to ldir doing zer0 inclusive and so the length of data should be less one?
; Furthermore it appears the number push has this flaw. it is possible my counter sound be 0 index based
; will make changes to malloc to handle this possiblity
;dec bc

	ldir


	; push malloc to data stack     macro????? 

	pop hl ; get malloc root
;	ld (hl), e
;	inc hl
;	ld (hl), d		


	FORTH_DSP_NEXT

;	ld hl,(cli_data_sp)
;	inc hl
;	inc hl
;	ld (cli_data_sp), hl


if DEBUG_FORTH_PUSH
			DMARK "PH4"
	CALLMONITOR
;	ex de,hl
endif	
	; in case of spaces, skip the ptr past the copied string
	;pop af
	;ld (cli_origptr),hl

	ret

.faphex:   ; hex is always stored as a 16bit word
	; skip number prefix
	inc hl
	; turn ascii into number
	call get_word_hl	; ret 16bit word in hl

.faprawhl:		; entry point for pushing a value when already in hl used in function above
	push hl

if DEBUG_FORTH_PUSH
	; see if disabled


	push af
	ld a, (os_view_disable)
	cp '*'
	jr z, .pskip2
	push hl
push hl
	call clear_display
pop hl
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
		ld a, display_row_2
		call str_at_display
	ld de, .push_num
	ld a, display_row_1

		call str_at_display


	call update_display
	call delay1s
	call delay1s
.pskip2: 

	pop af
endif	

	; get malloc for the storage (a bit of an overhead but makes it compatible with string push

	ld hl, 5
	call malloc
	if DEBUG_FORTH_MALLOC_GUARD
		call z,malloc_error
	endif

	push hl		; once to save on to data stack
	push hl		; once to save word into

;if DEBUG_FORTH_MALLOC
;	call display_data_malloc 
;endif
	
	; push malloc to data stack     macro????? 

	ld hl,(cli_data_sp)
	inc hl
	inc hl
	ld (cli_data_sp),hl

	pop de ; get malloc root
	ld (hl), e
	inc hl
	ld (hl), d		

	; save value and type

	pop hl

	ld a,  DS_TYPE_INUM
	ld (hl), a
	inc hl

	; get word off stack
	pop de
	ld a,e
	ld (hl), a
	inc hl
	ld a,d
	ld (hl), a

if DEBUG_FORTH_PUSH
			DMARK "PH5"
	CALLMONITOR
endif	



	ret
	 nop

.fabin:   ; TODO bin conversion



	ret


; get either a string ptr or a 16bit word from the data stack

FORTH_DSP: macro
	call macro_forth_dsp
	endm

macro_forth_dsp:
	; data stack pointer points to current word on tos

	ld hl,(cli_data_sp)

	if DEBUG_FORTH_PUSH
			DMARK "DSP"

		call display_data_sp
	;call break_point_state
	;rst 030h
	CALLMONITOR
	endif

	ret

; return hl to start of value on stack

FORTH_DSP_VALUE: macro
	call macro_forth_dsp_value
	endm

macro_forth_dsp_value:

	FORTH_DSP

	push de

	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de,hl 

	pop de

	ret

; return hl to start of value to second item on stack

FORTH_DSP_VALUEM1: macro
	call macro_forth_dsp_value_m1
	endm

macro_forth_dsp_value_m1:

	FORTH_DSP

	dec hl
	dec hl

	push de

	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de,hl 

	pop de

	ret

	

; whatever the current top os stack points to, we are now done with it so return memory to malloc

FORTH_DSP_POP: macro
	call macro_forth_dsp_pop
	endm

macro_forth_dsp_pop:
	; release malloc data

	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
		FORTH_CHK_DSP_UNDER
	endif
	;ld hl,(cli_data_sp)
if DEBUG_FORTH_DOT
	DMARK "DPP"
	CALLMONITOR
endif	

	FORTH_DSP_VALUE


if DEBUG_FORTH_DOT_KEY
	DMARK "DP1"
	CALLMONITOR
endif	

if FORTH_ENABLE_FREE
	call free
endif

if DEBUG_FORTH_DOT_KEY
	DMARK "DP2"
	CALLMONITOR
endif	

	; move pointer down

	ld hl,(cli_data_sp)
	dec hl
	dec hl
	ld (cli_data_sp), hl

	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
		FORTH_CHK_DSP_UNDER
	endif
	ret

; get the tos data type

FORTH_DSP_TYPE:   macro

	FORTH_DSP_VALUE
	
	; hl points to value
	; check type

	ld a,(hl)

	endm

; load the tos value into hl


FORTH_DSP_VALUEHL:  macro
	call macro_dsp_valuehl
	endm



macro_dsp_valuehl:
	FORTH_DSP_VALUE

	FORTH_ERR_TOS_NOTNUM

	inc hl   ; skip type id

	push de

	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de,hl 

	pop de

	if DEBUG_FORTH_PUSH
			DMARK "DVL"
	CALLMONITOR
	endif
	ret



findnexttok:

	; hl is pointer to move
	; de is the token to locate

		if DEBUG_FORTH
			DMARK "NTK"
			CALLMONITOR
		endif
	push de

.fnt1:	
	; find first char of token to locate

	ld a, (de)
	ld c,a
	ld a,(hl)
	call toUpper
		if DEBUG_FORTH
			DMARK "NT1"
			CALLMONITOR
		endif
	cp c

	jr z, .fnt2cmpmorefirst	

	; first char not found move to next char

	inc hl
	jr .fnt1

.fnt2cmpmorefirst:	
	; first char of token found. 

	push hl     ; save start of token just in case it is the right one
	exx
	pop hl        ; save it to hl'
	exx


.fnt2cmpmore:	
	; compare the rest
	
	inc hl
	inc de
	
	ld a, (de)
	ld c,a
	ld a,(hl)
	call toUpper

		if DEBUG_FORTH
			DMARK "NT2"
			CALLMONITOR
		endif
	; c has the token to find char
	; a has the mem to scan char

	cp c
	jr z,.fntmatch1

	; they are not the same

		if DEBUG_FORTH
			DMARK "NT3"
			CALLMONITOR
		endif
	pop de	; reset de token to look for
	push de
	jr .fnt1
	
.fntmatch1:

	; is the same char a null which means we might have a full hit?
		if DEBUG_FORTH
			DMARK "NT4"
			CALLMONITOR
		endif

	cp 0
	jr z, .fntmatchyes

	; are we at the end of the token to find?

		if DEBUG_FORTH
			DMARK "NT5"
			CALLMONITOR
		endif
	ld a, 0
	cp c

	jp nz, .fnt2cmpmore    ; no, so keep going to a direct hit

		if DEBUG_FORTH
			DMARK "NT6"
			CALLMONITOR
		endif
	; token to find is exhusted but no match to stream

	; restore tok pointer and continue on
	pop de
	push de
	jp .fnt1


.fntmatchyes:

	; hl now contains the end of the found token

	; get rid of saved token pointer to find

	pop de

		if DEBUG_FORTH
			DMARK "NT9"
			CALLMONITOR
		endif

	; hl will be on the null term so forward on

	; get back the saved start of the token

	exx
	push hl     ; save start of token just in case it is the right one
	exx
	pop hl        ; save it to hl

	ret


forth_apushstrhl:     
	; push of string requires use of cli_origptr
	; bodge use

	; get current cli_origptr, save, update with temp pointer 
	ld de, (cli_origptr)
	ld (cli_origptr), hl
	push de
	call forth_apush
	pop de
	ld (cli_origptr), de
        ret	


; increase loop stack pointer and save hl to it
	
FORTH_LOOP_NEXT: macro
	call macro_forth_loop_next
	;nop
	endm

macro_forth_loop_next:
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	push hl
	push de
	ex de,hl
	ld hl,(cli_loop_sp)
	inc hl
	inc hl
		if DEBUG_FORTH_WORDS
			DMARK "LNX"
			CALLMONITOR
		endif
	ld (cli_loop_sp),hl
	ld (hl), e
	inc hl
	ld (hl), d
	pop de    ; been reversed so save a swap on restore
	pop hl
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	ret

; get current ret stack pointer and save to hl 
	
FORTH_LOOP_TOS: macro
	call macro_forth_loop_tos
	endm

macro_forth_loop_tos:
	push de
	ld hl,(cli_loop_sp)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	pop de
	ret

; pop loop stack pointer
	
FORTH_LOOP_POP: macro
	call macro_forth_loop_pop
	endm


macro_forth_loop_pop:
	if DEBUG_FORTH_STACK_GUARD
		DMARK "LPP"
		call check_stacks
		FORTH_CHK_LOOP_UNDER
	endif
	push hl
	ld hl,(cli_loop_sp)
	dec hl
	dec hl
	ld (cli_loop_sp), hl
	; TODO do stack underflow checks
	pop hl
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
		FORTH_CHK_LOOP_UNDER
	endif
	ret

; eof
