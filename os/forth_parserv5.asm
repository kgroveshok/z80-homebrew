

; A better parser without using malloc and string copies all over the place. 
; Exec in situ should be faster

;WORD_SYS_LOWPRIM: equ 4    ; Offset for low level prim words opcode
;WORD_SYS_BRANCH: equ 10    ; Offset for branching and loop words opcode
WORD_SYS_UWORD: equ 1   ; Opcode for all user words
WORD_SYS_DELETED: equ 3 ; Op code for a deleted UWORD
WORD_SYS_ROOT: equ 0   ; Opcode for all user words
WORD_SYS_END: equ 0   ; Opcode for all user words
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
      


; Another go at the parser to compile 


; TODO rework parser to change all of the string words to byte tokens
; TODO do a search for 

; TODO first run normal parser to zero term sections
; TODO for each word do a token look up to get the op code
; TODO need some means to flag to the exec that this is a byte code form   


forthcompile:

;
; line parse:
;       parse raw input buffer
;       tokenise the words
;       malloc new copy (for looping etc)
;       copy to malloc + current pc in line to start of string and add line term
;       save on new rsp
;

; hl to point to the line to tokenise

;	push hl
	ld (os_tok_ptr), hl  ; save ptr to string

;	ld a,0		; string term on input
;	call strlent

;	ld (os_tok_len), hl	 ; save string length

;if DEBUG_FORTH_TOK
;	ex de,hl		
;endif

;	pop hl 		; get back string pointer

if DEBUG_FORTH_TOK
			DMARK "TOc"
	CALLMONITOR
endif
.cptoken2:    ld a,(hl)
	inc hl
	cp FORTH_END_BUFFER
	jr z, .cptokendone2
	cp 0
	jr z, .cptokendone2
	cp '"'
	jr z, .cptokenstr2     ; will want to skip until end of string delim
	cp ' '
	jr nz,  .cptoken2

; TODO consume comments held between ( and )

	; we have a space so change to zero term for dict match later
	dec hl
	ld a,0
	ld (hl), a
	inc hl
	jr .cptoken2
	

.cptokenstr2:
	; skip all white space until either eol (because forgot to term) or end double quote
        ;   if double quotes spotted ensure to skip any space sep until matched doble quote
	;inc hl ; skip current double quote
	ld a,(hl)
	inc hl
	cp '"'
	jr z, .cptoken2
	cp FORTH_END_BUFFER
	jr z, .cptokendone2
	cp 0
	jr z, .cptokendone2
	cp ' '
	jr z, .cptmp2
	jr .cptokenstr2

.cptmp2:	; we have a space so change to zero term for dict match later
	;dec hl
	;ld a,"-"	; TODO remove this when working
	;ld (hl), a
	;inc hl
	jr .cptokenstr2

.cptokendone2:
	;inc hl
	ld a, FORTH_END_BUFFER
	ld (hl),a
	inc hl
	ld a, '!'
	ld (hl),a

	ld hl,(os_tok_ptr)
        
if DEBUG_FORTH_TOK
			DMARK "Tc1"
	CALLMONITOR
endif

	; push exec string to top of return stack
	FORTH_RSP_NEXT
	ret

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

;	push hl
	ld (os_tok_ptr), hl  ; save ptr to string

;	ld a,0		; string term on input
;	call strlent

;	ld (os_tok_len), hl	 ; save string length

;if DEBUG_FORTH_TOK
;	ex de,hl		
;endif

;	pop hl 		; get back string pointer

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
	;inc hl
	ld a, FORTH_END_BUFFER
	ld (hl),a
	inc hl
	ld a, '!'
	ld (hl),a

	ld hl,(os_tok_ptr)
        
if DEBUG_FORTH_TOK
			DMARK "TK1"
	CALLMONITOR
endif

	; push exec string to top of return stack
	FORTH_RSP_NEXT
	ret

;
;	; malloc size + buffer pointer + if is loop flag
;	ld hl,(os_tok_len) 		 ; get string length
;
;	ld a,l
;
;	cp 0			; we dont want to use a null string
;	ret z
;
;;	add 3    ; prefix malloc with buffer for current word ptr
;
;	add 5     ; TODO when certain not over writing memory remove
;
;		
;
;if DEBUG_FORTH_TOK
;			DMARK "TKE"
;	CALLMONITOR
;endif
;
;	ld l,a
;	ld h,0
;;	push hl   ; save required space for the copy later
;	call malloc
;if DEBUG_FORTH_TOK
;			DMARK "TKM"
;	CALLMONITOR
;endif
;	if DEBUG_FORTH_MALLOC_GUARD
;		push af
;		call ishlzero
;;		ld a, l
;;		add h
;;		cp 0
;		pop af
;		
;		call z,malloc_error
;	endif
;	ld (os_tok_malloc), hl	 ; save malloc ptr
;
;
;if DEBUG_FORTH_TOK
;			DMARK "TKR"
;	CALLMONITOR
;endif
;
;	FORTH_RSP_NEXT
;
;	;inc hl	 ; go past current buffer pointer
;	;inc hl
;	;inc hl   ; and past if loop flag
;		; TODO Need to set flag 
;
;	
;	
;	ex de,hl	; malloc is dest
;	ld hl, (os_tok_len)
;;	pop bc
;	ld c, l               
;	ld b,0
;	ld hl, (os_tok_ptr)
;
;if DEBUG_FORTH_TOK
;			DMARK "TKT"
;	CALLMONITOR
;endif
;
;	; do str cpy
;
;	ldir      ; copy byte in hl to de
;
;	; set end of buffer to high bit on zero term and use that for end of buffer scan
;
;if DEBUG_FORTH_TOK
;
;			DMARK "TKY"
;	CALLMONITOR
;endif
;	;ld a,0
;	;ld a,FORTH_END_BUFFER
;	ex de, hl
;	;dec hl			 ; go back over the space delim at the end of word
;	;ld (hl),a
;	;inc hl                    ;  TODO double check this. Going past the end of string to make sure end of processing buffer is marked
;	ld a,FORTH_END_BUFFER
;	ld (hl),a
;	inc hl
;	ld a,FORTH_END_BUFFER
;	ld (hl),a
;
;	; init the malloc area data
;	; set pc for in current area
;	;ld hl, (os_tok_malloc)
;	;inc hl
;	;inc hl
;	;inc hl
;	;ex de,hl
;	;ld hl, (os_tok_malloc)
;	;ld (hl),e
;	;inc hl
;	;ld (hl),d
;
;
;	ld hl,(os_tok_malloc)
;if DEBUG_FORTH_PARSE_KEY
;			DMARK "TKU"
;	CALLMONITOR
;endif
;
;	ret

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

ld hl, baseram
;ld hl, sysdict
ld (cli_nextword),hl
;           match word at pc
;           exec word
;           or push to dsp
;           forward to next token
;           if line term pop rsp and exit
;       

if DEBUG_FORTH_PARSE_KEY
			DMARK "KYq"
	CALLMONITOR
endif

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

	call forth_tok_next
; tok next start here
;	; TODO skip compiled symbol for now
;	inc hl
;
;	; save pointer to next word
;
;	; hl now points to the address of the next word pointer 
;	ld e, (hl)
;	inc hl
;	ld d, (hl)
;	inc l
;
;	ex de,hl
;if DEBUG_FORTH_PARSE_NEXTWORD
;	push bc
;	ld bc, (cli_nextword)
;			DMARK "NXW"
;	CALLMONITOR
;	pop bc
;endif
; tok next end here
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
	cp WORD_SYS_END
;	cp 0
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


; LIST needs to find a specific token  
; FORGET needs to find a spefici token

; SAVE needs to find all tokens by flag
; WORDS just needs to scan through all  by flag
; UWORDS needs to scan through all by flag


; given hl as pointer to start of dict look up string
; return hl as pointer to start of word block
; or 0 if not found

forth_find_tok:
	ret

; given hl as pointer to dict structure
; move to the next dict block structure

forth_tok_next:
	; hl now points to the address of the next word pointer 
	; TODO skip compiled symbol for now
	inc hl
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
	
	ret



; eof
