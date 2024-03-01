;
; kernel to the forth OS

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


; get start of dict

ld hl, sysdict
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

if DEBUG_FORTH
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
	ld de, (cli_ptr)
	ld a, display_row_4+10
	
		call str_at_display
	call update_display
;	call delay500ms
	call delay1s
	call delay1s
	pop hl
endif	
	; save the pointer of the current token - 1 to check against
	
	ld (cli_token), hl   
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

if DEBUG_FORTH
	push hl
	call clear_display
	ld de, .compword
	ld a, display_row_1
	call str_at_display
	pop de
	ld a, display_row_2
	call str_at_display
	ld de,(cli_ptr)
	ld a, display_row_2+10
	call str_at_display
	call update_display
	call delay500ms

endif	
.pnchar:    ; compare char between token and string to parse

if DEBUG_FORTH
	ld hl,(cli_token)
ld a,(hl)
ld (os_word_scratch),a
	ld hl,(cli_ptr)
ld a,(hl)
	ld (os_word_scratch+1),a
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
	ld a,display_row_4
	call str_at_display
	call update_display
	call delay1s
endif
	ld hl,(cli_token)
	ld a, (hl)	 ; char in word token
	inc hl 		; move to next char
	ld (cli_token), hl ; and save it
	ld b,a

	ld hl,(cli_ptr) ;	get the char from the string to parse
	ld a,(hl)
;	inc hl
;	ld (cli_ptr), hl		; move to next char
	;call toUpper 		; make sure the input string matches case

	cp b
	jr nz, .pnskipword	 ; no match so move to next word
	
;    if same
;       scan for string terms 0 for token and 32 for input

	add b			
	cp 32			 ; add both chars together, if 32 then other must be 0 so at end of string we are parsing?
				; TODO need to make sure last word in zero term string is accounted for
	jr nz, .pnchar 		 ; not at end of strings yet


	; at end of both strings so both are exact match

;       skip ptr for next word
;       exec code block
if DEBUG_FORTH
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
	ld a,display_row_1
	ld de, .foundword
	ld a, display_row_3
	call str_at_display
	call update_display
	call delay1s
	call delay1s
	call delay1s
	call delay1s
	call delay1s
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

if DEBUG_FORTH

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

if DEBUG_FORTH

	ld de, .enddict
	ld a, display_row_3
	call str_at_display
	call update_display
	call delay1s

endif	
	ret

if DEBUG_FORTH
.nowordfound: db "No match",0
.compword:	db "Comparing word ",0
.foundword:	db "Word match. Exec code",0
.enddict:	db "Dict end marker",0
.nextwordat:	db "Next word at",0
endif


; move cli_ptr to start of next word in cli_buffer 


strtok: 
	
	ret


; eof
