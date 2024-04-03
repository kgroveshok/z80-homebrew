
; new parser. restructing to handle nested loops and better scanning of word tokens


NEXT: macro 
	ld hl,(cli_origptr)   ; move to next token to parse in the input stream
	jp parsemallocbuffer
      endm




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

if DEBUG_FORTH_PARSE
	ex de,hl		
endif

	pop hl 		; get back string pointer

if DEBUG_FORTH_PARSE
	push af
	ld a, 'Q'
	ld (debug_mark),a
	pop af
	call display_reg_state
	call display_dump_at_hl
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

	; we have a space so change to zero term for dict match later
	dec hl
	ld a,0
	ld (hl), a
	inc hl
	jr .ptoken2
	

.ptokenstr2:
	; skip all white space until either eol (because forgot to term) or end double quote
        ;   if double quotes spotted ensure to skip any space sep until matched doble quote
	ld a,(hl)
	inc hl
	cp '"'
	jr z, .ptokendone2
	cp FORTH_END_BUFFER
	jr z, .ptokendone2
	jr z, .ptokenstr2


.ptokendone2:

if DEBUG_FORTH_PARSE
	ld hl,(os_tok_ptr)
	push af
	ld a, 'W'
	ld (debug_mark),a
	pop af
	call display_reg_state
	call display_dump_at_hl
endif

	; malloc size + buffer pointer + if is loop flag
	ld hl,(os_tok_len) 		 ; get string length

	ld a,l

	cp 0			; we dont want to use a null string
	ret z

	add 3    ; prefix malloc with buffer for current word ptr

	add 5     ; TODO when certain not over writing memory remove

		

if DEBUG_FORTH_PARSE
	push af
	ld a, 'E'
	ld (debug_mark),a
	pop af
	call display_reg_state
	call display_dump_at_hl
endif

	ld l,a
	ld h,0
	call malloc
	ld (os_tok_malloc), hl	 ; save malloc ptr


if DEBUG_FORTH_PARSE
	push af
	ld a, 'R'
	ld (debug_mark),a
	pop af
	call display_reg_state
	call display_dump_at_hl
endif

	FORTH_RSP_NEXT

	inc hl	 ; go past current buffer pointer
	inc hl
	inc hl   ; and past if loop flag
		; TODO Need to set flag 

	
	
	ex de,hl	; malloc is dest
	ld hl, (os_tok_len)
	ld c, l
	ld b,0
	ld hl, (os_tok_ptr)

if DEBUG_FORTH_PARSE
	push af
	ld a, 'T'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif

	; do str cpy

	ldir      ; copy byte in hl to de

	; set end of buffer to high bit on zero term and use that for end of buffer scan

if DEBUG_FORTH_PARSE
	push af
	ld a, 'Y'
	ld (debug_mark),a
	pop af
	call display_reg_state
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
	ld hl, (os_tok_malloc)
	inc hl
	inc hl
	inc hl
	ex de,hl
	ld hl, (os_tok_malloc)
	ld (hl),e
	inc hl
	ld (hl),d


if DEBUG_FORTH_PARSE
	ld hl,(os_tok_malloc)
	push af
	ld a, 'U'
	ld (debug_mark),a
	pop af
	call display_reg_state
	call display_dump_at_hl
endif

	ret

forthexec:

; line exec:
;
;       get current exec line on rsp
;       restore current pc
;       while at start of word:
;           match word at pc
;           exec word
;           or push to dsp
;           forward to next token
;           if line term pop rsp and exit
;       



; start of parsing a new buffer 
parsenext:
	; TODO can use this process to compile by just returning the byte op code whole buffer without doing sub loops
        ; TODO might need to add high bit to op codes to tell difference with values to push to stack
	;




	; process....
	; get size of zero term buffer

	ld (cli_origptr),hl

if DEBUG_FORTH_PARSE
	push af
	ld a, '1'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif

	ld a,0
	call strlent


if DEBUG_FORTH_PARSE
	push af
	ld a, '2'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif

	; malloc size + buffer pointer + if is loop flag

	ld a,l

	cp 0			; we dont want to use a null string
	ret z

	push af		; save str len
	add 3    ; prefix malloc with buffer for current word ptr

	add 5     ; TODO when certain not over writing memory remove

if DEBUG_FORTH_PARSE
	push af
	ld a, '3'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif


	ld l,a
	ld h,0
	call malloc

if DEBUG_FORTH_PARSE
	push af
	ld a, '4'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif
	FORTH_RSP_NEXT

if DEBUG_FORTH_PARSE
	push af
	ld a, 'b'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif
	; copy buffer to malloc

	pop af	 ; get strl len back

	inc hl	 ; go past current buffer pointer
	inc hl
	inc hl   ; and past if loop flag
		; TODO Need to set flag 

	push hl

if DEBUG_FORTH_PARSE
	push af
	ld a, 'C'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif
	; prepare to copy current buffer to new malloc
	ex de,hl
	ld hl, (cli_origptr)
	ld b,0
	ld c, a

if DEBUG_FORTH_PARSE
	push af
	ld a, 'D'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif

	; do str cpy

	ldir      ; copy byte in hl to de

	; set end of buffer to high bit on zero term and use that for end of buffer scan

if DEBUG_FORTH_PARSE
	push af
	ld a, 'd'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif
	ld a,0
	;ld a,FORTH_END_BUFFER
	ex de, hl
	dec hl			 ; go back over the space delim at the end of word
	ld (hl),a
	inc hl                    ;  TODO double check this. Going past the end of string to make sure end of processing buffer is marked
	ld a,FORTH_END_BUFFER
	ld (hl),a
	inc hl
	ld a,FORTH_END_BUFFER
	ld (hl),a
	
	; go through malloc string and set zero term on all keywords

; TODO showing possible zero pointer when doing word check.  do we ld hl correctly?
; TODO do a hex dump of hl at this point to see if im out by a byte or two



	pop hl     ; at start of buffer string




if DEBUG_FORTH_PARSE
	push af
	ld a, 'p'
	ld (debug_mark),a
	pop af
	call display_dump_at_hl
	call display_reg_state
endif
.ptoken:    ld a,(hl)
	inc hl
if DEBUG_FORTH_PARSE
	push af
	ld a, 'Q'
	ld (debug_mark),a
	pop af
;	call display_dump_at_hl
;	call display_reg_state
endif
	cp FORTH_END_BUFFER
	jr z, .ptokendone
	cp 0
	jr z, .ptokendone
	cp '"'
	jr z, .ptokenstr     ; will want to skip until end of string delim
	cp ' '
	jr nz,  .ptoken

if DEBUG_FORTH_PARSE
	push af
	ld a, 'r'
	ld (debug_mark),a
	pop af
;	call display_dump_at_hl
;	call display_reg_state
endif
	; we have a space so change to zero term for dict match later
	dec hl
	ld a,0
	ld (hl), a
	inc hl
	jr .ptoken
	

.ptokenstr:
	; skip all white space until either eol (because forgot to term) or end double quote
        ;   if double quotes spotted ensure to skip any space sep until matched doble quote
if DEBUG_FORTH_PARSE
	push af
	ld a, 's'
	ld (debug_mark),a
	pop af
;	call display_dump_at_hl
;	call display_reg_state
endif
	ld a,(hl)
	inc hl
	cp '"'
	jr z, .ptokendone
	cp FORTH_END_BUFFER
	jr z, .ptokendone
	jr z, .ptokenstr


.ptokendone:

if DEBUG_FORTH_PARSE
	push af
	ld a, 't'
	ld (debug_mark),a
	pop af
;	call display_dump_at_hl
;	call display_reg_state
endif
	; set word ptr to start of string in malloc
	; inc ret sp
	; store malloc ptr


	; .repeat
	; get top of ret sp
	; set cur ptr to malloc
	; call parsenext

.parsethismalloc:

if DEBUG_FORTH_PARSE
	push af
	ld a, 'u'
	ld (debug_mark),a
	pop af
	call display_dump_at_hl
	call display_reg_state
endif
	FORTH_RSP_TOS
	inc hl    ; ptr word
	inc hl
	inc hl    ; loop flag
if DEBUG_FORTH_PARSE
	push af
	ld a, 'v'
	ld (debug_mark),a
	pop af
	call display_dump_at_hl
	call display_reg_state
endif
	;ld (cli_ptr), hl
	call parsemallocbuffer

	; on return
	; free top of ret sp

if DEBUG_FORTH_PARSE
	push af
	ld a, 'z'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif
	FORTH_RSP_TOS
if DEBUG_FORTH_PARSE
	push af
	ld a, 'Z'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif
	; call free			 ; TODO causing a crash

if DEBUG_FORTH_PARSE
	push af
	ld a, 'X'
	ld (debug_mark),a
	pop af
	call display_reg_state
endif
	; dec ret sp
	ld hl,(cli_ret_sp)
	dec hl
	dec hl
	ld (cli_ret_sp), hl

	; get new top of ret sp

	ld a, (hl)
	cp 0
	jr nz, .parsethismalloc
	inc hl
	ld a, (hl)
	jr nz, .parsethismalloc

	; if zero then ret
	; if not zero then jp .repeat

	ret



; cli_ptr holds start of current word to pass

parsemallocbuffer:


;PLUS:	db 1
;	db 1
;	ds "+",0
;	dw NEG
;		NEXT


; 1. hold ptr of the line being parsed
; 2. scan word until space is found
; 3. scan dict
;       get start of dict
;       compare token to string
;       if char does not match drop out and get pointer to next word
;       if chars match to zero term then flag as found word
;           do a jump to the code block for word 

; hl contains string to parse

ld (cli_ptr), hl
ld (cli_origptr), hl     ; save for any restart of current string ie a number or string to push to data stack
ld a, (hl)
cp FORTH_END_BUFFER
ret z

; get start of dict (in user area first)

ld hl, baseusermem
;ld hl, sysdict
ld (cli_nextword),hl

;
; word comp
;    get compiled byte and save it (need to decide if code is compiled or not for comparison)
;    if byte is 0 then end parsing and report failed lookup (or could be something to add to stack etc)
;    move to start of word 
;    compare word to cli_token

.pnword:	; HL at start of a word in the dictionary to check
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
	inc hl

	ex de,hl
	ld (cli_nextword), hl     ; save for next check if no match on this word
	ex de, hl

if DEBUG_FORTH_PARSE
endif	
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
.pnwordinc: 
	inc hl
	djnz .pnwordinc
	ld (cli_execword), hl      ; save start of this words code

	; now check the word token against the string being parsed

	ld hl,(cli_token)
	inc hl     ; skip string length (use zero term instead to end)
	ld (cli_token), hl

if DEBUG_FORTH_PARSE
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
	call delay250ms
;	call delay1s
;	call delay1s
;	call delay1s
	pop hl
endif	
.pnchar:    ; compare char between token and string to parse

if DEBUG_FORTH_PARSE
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
;	call delay250ms
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
	jp nz, .pnskipword	 ; no match so move to next word
	
;    if same
;       scan for string terms 0 for token and 32 for input

	

	add b			
	cp 0			 ; add both chars together, if 32 then other must be 0 so at end of string we are parsing?
				; TODO need to make sure last word in zero term string is accounted for
	jr nz, .pnchar 		 ; not at end of strings yet


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

	ld hl,(cli_execword)
	jp (hl)


;    if not same
;	scan for zero term
;	get ptr for next word
;	goto word comp

.pnskipword:	; get pointer to next word
	ld hl,(cli_nextword)

	ld a,(hl)
	cp 0
	jr z, .endofdict			 ; at end of words

if DEBUG_FORTH_PARSE

	ld de, .nowordfound
	ld a, display_row_3
	call str_at_display
	call update_display
	call delay250ms

endif	

	ld hl,(cli_origptr)
	ld (cli_ptr),hl

	jp .pnword			; else go to next word

.endofdict: 

if DEBUG_FORTH_PUSH
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
	call delay1s
	call delay1s
	call delay1s

endif	



	; if the word is not a keyword then must be a literal so push it to stack

; TODO push token to stack to end of word


ld hl,(cli_origptr)
call forth_apush


; TODO remove this subject to push type move past token to next word

ld hl, (cli_origptr)
ld a, 0
ld bc, 255     ; input buffer size
cpir

; TODO this might place hl on the null, so will need to forward on???
inc hl   ; see if this gets onto the next item


; TODO pass a pointer to the buffer to push
; TODO call function to push



ld (cli_origptr), hl

; look for end of input

;inc hl
ld a,(hl)
cp FORTH_END_BUFFER
ret z


jp parsenext
 
	;ret

;endif





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

	; identify input type

	ld a,(hl)
	cp '"'
	jr z, .fapstr
	cp '$'
	jp z, .faphex
	cp 'b'
	jp z, .fabin
	; else decimal

	; TODO do decimal conversion
	; decimal is stored as a 16bit word

.fapstr:   
	; get string length

	ld a, '"'
	call strlent      ; TODO maybe a bug here for string copying
	;push af
if DEBUG_FORTH_PUSH
	push af
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
	pop af
endif	

	; TODO malloc + 1

	add 5    ; to be safe for some reason - max of 255 char for string
	ld h,0
	ld l,a
	call malloc	; on ret hl now contains allocated memory

	push hl
if DEBUG_FORTH_MALLOC
	call display_data_malloc 
endif	

	; flag set as str


	ld (hl), DS_TYPE_STR
	inc hl

	; copy string to malloc area

	ex de,hl
	ld hl, (cli_origptr)
	ld b,0
	ld c, a
	ldir

	; push malloc to data stack     macro????? 

	ld hl,(cli_data_sp)
	inc hl
	inc hl
	ld (cli_data_sp), hl

	pop de ; get malloc root
	ld (hl), e
	inc hl
	ld (hl), d		


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
	push af
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
	pop af
endif	

	; get malloc for the storage (a bit of an overhead but makes it compatible with string push

	ld hl, 5
	call malloc

	push hl		; once to save on to data stack
	push hl		; once to save word into

if DEBUG_FORTH_MALLOC
	call display_data_malloc 
endif
	
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

	ld a,  DS_TYPE_NUM
	ld (hl), a
	inc hl

	; get word off stack
	pop de
	ld a,e
	ld (hl), a
	inc hl
	ld a,d
	ld (hl), a




	ret
	 nop

.fabin:   ; TODO bin conversion



	ret


; get either a string ptr or a 16bit word from the data stack

FORTH_DSP: macro
	; data stack pointer points to current word on tos

	ld hl,(cli_data_sp)

	if DEBUG_FORTH_PUSH

		call display_data_sp
	endif

	endm

; return hl to start of value on stack

FORTH_DSP_VALUE: macro

	FORTH_DSP

	push de

	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de,hl 

	pop de

	endm

	

; whatever the current top os stack points to, we are now done with it so return memory to malloc

FORTH_DSP_POP: macro
	; release malloc data

	;ld hl,(cli_data_sp)
if DEBUG_FORTH_DOT
		
		ld a, '1'
		ld (debug_mark),a
		call display_data_sp
		ld a, '2'
		ld (debug_mark),a
		call next_page_prompt
endif	
	FORTH_DSP_VALUE
if DEBUG_FORTH_DOT
		
		ld a, '3'
		ld (debug_mark),a
		call display_data_sp
		ld a, '4'
		ld (debug_mark),a
		call next_page_prompt
endif	
	call free
if DEBUG_FORTH_DOT
		
		ld a, '5'
		ld (debug_mark),a
		call display_data_sp
		ld a, '6'
		ld (debug_mark),a
		call next_page_prompt
endif	

	; move pointer down

	ld hl,(cli_data_sp)
	dec hl
	dec hl
	ld (cli_data_sp), hl

	endm

; get the tos data type

FORTH_DSP_TYPE:   macro

	FORTH_DSP_VALUE
	
	; hl points to value
	; check type

	ld a,(hl)

	endm

; load the tos value into hl

FORTH_DSP_VALUEHL:  macro
	FORTH_DSP_VALUE

	inc hl   ; skip type id

	push de

	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de,hl 

	pop de

	if DEBUG_FORTH_PUSH

		call display_data_sp
	endif
	endm
