;
; kernel to the forth OS

DS_TYPE_STR: equ 1
DS_TYPE_NUM: equ 2 

user_word_eol: 
	; hl contains the pointer to where to create a linked list item from the end
	; of the user dict to continue on at the system word dict
	
	; poke the stub of the word list linked list to repoint to rom words

	; stub format
	; db   word id
	; dw    link to next word
        ; db char length of token
	; db string + 0 term
	; db exec code.... 

	ld a, 1
	ld (hl), a		; word id
	inc hl

	ld de, sysdict
	ld (hl), e		; next word link ie system dict
	inc hl
	ld (hl), d		; next word link ie system dict
	inc hl	

;	ld (hl), sysdict		; next word link ie system dict
;	inc hl
;	inc hl

;	inc hl
;	inc hl

	ld a, 2			; word length is 0
	ld (hl), a	
	inc hl

	ld a, '~'			; word length is 0
	ld (hl), a	
	inc hl
	ld a, 0			; save empty word
	ld (hl), a

	ret


forth_init:
;	call update_display
;	call delay1s
;	ld a,'.'
;	call fill_display
;	call update_display
;	call delay1s
;
;            ld a, display_row_2
;	ld de, .bootforth
;	call str_at_display
;	call update_display
;
;	call delay1s
;	call delay1s

	; init stack pointers  - * these stacks go upwards * 
	ld hl, cli_ret_stack
	ld (cli_ret_sp), hl	

	ld hl, cli_data_stack
	ld (cli_data_sp), hl	

	call clear_display

	ld a,0
	ld (f_cursor_ptr), a

	; set start of word list in start of ram - for use when creating user words

	ld hl, baseusermem		
	call user_word_eol
	


	ret

.bootforth: db " Forth Kernel Init ",0

; TODO push to stack

; 



; parse cli

; cli_ptr holds start of current word to pass

parsenext:


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

ld (cli_origptr), hl		 ;save start of buffer to parse

.ltrimbl:     ; trim off any space at start of string to get to the first non space or end of string
	ld a,(hl)
	inc hl
	cp ' '
	jr z, .ltrimbl
	cp 0		; end of string
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
	ld hl,(cli_origptr)	 ; reset start of word to look up
	ld (cli_ptr), hl

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
	push hl
	call clear_display
	ld hl, (cli_nextword)     ; save for next check if no match on this word
	ld a,h
	ld hl, os_word_scratch
	call hexout
	ld hl, (cli_nextword)     ; save for next check if no match on this word
	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
		ld a, display_row_2
		call str_at_display
	ld a,display_row_1
	ld de, .nextwordat
		call str_at_display
	ld hl,(cli_ptr)
	ld a,(hl)
        ld hl, os_word_scratch
	ld (hl),a
	ld a,0
	inc hl
	ld (hl),a 	
	ld a, display_row_4+10
	ld de, os_word_scratch
		call str_at_display
	call update_display
	call delay500ms
;	call delay1s
;	call delay1s
	pop hl
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
	call delay500ms
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
	call delay500ms
;	call delay1s
;	call delay1s
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
	push af
	push bc

	ld hl, os_word_scratch
	call hexout
	ld a,b
	ld hl, os_word_scratch+2
	call hexout
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
		ld a, display_row_4+10
		call str_at_display

	ld de,.charmatch
	ld a,display_row_1
	call str_at_display
	call update_display
	call delay500ms
;	call delay1s
;	call delay1s
	pop bc
	pop af
endif

	; input stream end of token is a space so get rid of it

	cp ' '
	jr nz, .pnskipspace

	ld a, 0		; make same term as word token term

.pnskipspace:

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
	;inc hl			 ; at next char
	ld (cli_origptr), hl     ; save for next round of the parser
	
	



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
ld a, ' '
ld bc, 255     ; input buffer size
cpir


; TODO pass a pointer to the buffer to push
; TODO call function to push



ld (cli_origptr), hl

; look for end of input

;inc hl
ld a,(hl)
cp 0
ret z


jp parsenext
 
	;ret


if DEBUG_FORTH_PARSE
.nowordfound: db "No match",0
.compword:	db "Comparing word ",0
.nextwordat:	db "Next word at",0
.charmatch:	db "Char match",0
endif
if DEBUG_FORTH_JP
.foundword:	db "Word match. Exec..",0
endif
;if DEBUG_FORTH_PUSH
.enddict:	db "Dict end. Push.",0
.push_str:	db "Pushing string",0
.push_num:	db "Pushing number",0
.data_sp:	db "SP:",0
.wordinhl:	db "Word in HL:",0
;endif
;if DEBUG_FORTH_MALLOC
.push_malloc:	db "Malloc address",0
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

	ld a, ' '
	call strlent      ; TODO maybe a bug here for string copying

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

	ld hl,(cli_data_sp)
	call free

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


	




; display malloc address and current data stack pointer 

;if DEBUG_FORTH_PUSH
display_data_sp:

	push af
	push hl
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
	ld de, .wordinhl
	ld a, display_row_1

		call str_at_display

	; display current data stack pointer
	ld de,.data_sp
		ld a, display_row_2 + 8
		call str_at_display

	ld hl,(cli_data_sp)
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
		ld a, display_row_2 + 11
		call str_at_display

	call update_display
	call delay1s
	call delay1s
	pop hl
	pop af
	ret

display_data_malloc:

	push af
	push hl
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
	ld de, .push_malloc
	ld a, display_row_1

		call str_at_display

	; display current data stack pointer
	ld de,.data_sp
		ld a, display_row_2 + 8
		call str_at_display

	ld hl,(cli_data_sp)
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
		ld a, display_row_2 + 11
		call str_at_display

	call update_display
	call delay1s
	call delay1s
	pop hl
	pop af
	ret
;endif
; eof
