
.IF:
	CWHEAD .THEN 10 "IF" 2 WORD_FLAG_CODE
;	db 10
;	dw .THEN
;	db 3
;	db "IF",0     
;  |IF ( w -- f )     If TOS is true exec code following up to THEN - Note: currently not supporting ELSE or nested IF | DONE
;
; eval TOS

	FORTH_DSP_VALUEHL

	push hl
	FORTH_DSP_POP
	pop hl

		if DEBUG_FORTH_WORDS
			DMARK "IF1"
;			push af
;			ld a, 'I'
;			ld (debug_mark),a
;			pop af
			CALLMONITOR
		endif
	or a        ; clear carry flag
	ld de, 0
	ex de,hl
	sbc hl, de
	jp nz, .iftrue

		if DEBUG_FORTH_WORDS
			DMARK "IF2"
			;push af
			;ld a, 'f'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif

; if not true then skip to THEN

	; TODO get tok_ptr
	; TODO consume toks until we get to THEN

	ld hl, (os_tok_ptr)
		if DEBUG_FORTH_WORDS
			DMARK "IF3"
			;push af
			;ld a, 'h'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
			
		endif
	ld de, .ifthen
		if DEBUG_FORTH_WORDS
			DMARK "IF4"
			;push af
			;ld a, 'd'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif
	call findnexttok 

		if DEBUG_FORTH_WORDS
			DMARK "IF5"
			;push af
			;ld a, 'z'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif
	; TODO replace below with ; exec using tok_ptr
	ld (os_tok_ptr), hl
	jp exec1
	NEXTW

.ifthen:  db "THEN",0

.iftrue:		
	; Exec next words normally

	; if true then exec following IF as normal
		if DEBUG_FORTH_WORDS
			DMARK "IFT"
;			push af
;			ld a, 'T'
;			ld (debug_mark),a
;			pop af
			CALLMONITOR
		endif

		NEXTW
.THEN:
	CWHEAD .ELSE 11 "THEN" 4 WORD_FLAG_CODE
;	db 11
;	dw .ELSE
;	db 5
;	db "THEN",0    
; |THEN ( -- )    Does nothing. It is a marker for the end of an IF block | DONE
		NEXTW
.ELSE:
	CWHEAD .DO 12 "ELSE" 2 WORD_FLAG_CODE
; 	db 12
;	dw .DO
;	db 5
;	db "ELSE",0      
; |ELSE ( -- )   Not supported - does nothing



		NEXTW
.DO:
	CWHEAD .LOOP 13 "DO" 2 WORD_FLAG_CODE
;	db 13
;	dw .LOOP
;	db 3
;	db "DO",0       
; |DO ( u1 u2 -- )   Loop starting at u2 with a limit of u1 | DONE

		if DEBUG_FORTH_WORDS
;			push af
;			ld a, 'D'
;			ld (debug_mark),a
;			ld a, 'O'
;			ld (debug_mark+1),a
;			pop af

			DMARK "DO1"
			CALLMONITOR
		endif
;  push pc to rsp stack past the DO

		ld hl, (os_tok_ptr)
		inc hl   ; D
		inc hl  ; O
		inc hl   ; null
		if DEBUG_FORTH_WORDS
;			push af
;			ld a, '1'
;			ld (debug_mark+1),a
;			pop af
			DMARK "DO2"
			CALLMONITOR
		endif
		FORTH_RSP_NEXT
		if DEBUG_FORTH_WORDS
			DMARK "DO3"
;			push af
;			ld a, '2'
;			ld (debug_mark+1),a
;			pop af
			CALLMONITOR
		endif

		;if DEBUG_FORTH_WORDS
	;		push hl
;		endif 

; get counters from data stack


		FORTH_DSP_VALUEHL
		push hl		 ; hl now has starting counter which needs to be tos

		if DEBUG_FORTH_WORDS
			DMARK "DO4"
			;push af
			;ld a, 'a'
			;ld (debug_mark+1),a
			;pop af
			CALLMONITOR
		endif
		FORTH_DSP_POP

		if DEBUG_FORTH_WORDS
			DMARK "DO5"
			;push af
			;ld a, 'b'
			;ld (debug_mark+1),a
			;pop af
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL
		push hl		 ; hl now has starting limit counter

		if DEBUG_FORTH_WORDS
			DMARK "DO6"
			;push af
			;ld a, '3'
			;ld (debug_mark+1),a
			;pop af
			CALLMONITOR
		endif
		FORTH_DSP_POP

; put counters on the loop stack

		pop hl			 ; limit counter
		pop de			; start counter

		; push limit counter

		if DEBUG_FORTH_WORDS
			DMARK "DO7"
			;ipush af
			;ld a, '4'
			;ld (debug_mark+1),a
			;pop af
			CALLMONITOR
		endif
		FORTH_LOOP_NEXT

		; push start counter

		ex de, hl
		if DEBUG_FORTH_WORDS
			DMARK "DO7"
			;push af
			;ld a, '5'
			;ld (debug_mark+1),a
			;pop af
			CALLMONITOR
		endif
		FORTH_LOOP_NEXT


		; init first round of I counter

		ld (os_current_i), hl

		if DEBUG_FORTH_WORDS
			DMARK "DO8"
			;push af
			;ld a, 'D'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif

		NEXTW
.LOOP:
	CWHEAD .I 14 "LOOP" 4 WORD_FLAG_CODE
;	db 14
;	dw .COLN
;	db 5
;	db "LOOP",0      
; |LOOP ( -- )     Increment and test loop counter  | DONE

	; pop tos as current loop count to hl

	; if new tos (loop limit) is not same as hl, inc hl, push hl to tos, pop rsp and set pc to it

	FORTH_LOOP_TOS
	push hl

		if DEBUG_FORTH_WORDS
			DMARK "LOP"
;		push af
;		ld a, 'l'
;		ld (debug_mark),a
;		pop af
			CALLMONITOR
		endif
	; next item on the stack is the limit. get it


	FORTH_LOOP_POP

	FORTH_LOOP_TOS

	pop de		 ; de = i, hl = limit

		if DEBUG_FORTH_WORDS
			DMARK "LP1"
			;push af
			;ld a, 'l'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif

	; go back to previous word

	push de    ; save I for inc later


	; get limit
	;  is I at limit?


		if DEBUG_FORTH_WORDS
			DMARK "LP1"
			;push af
			;ld a, 'L'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif

	sbc hl, de


	;  if at limit pop both limit and current off stack do NEXT and get rid of saved DO

		jr nz, .loopnotdone

	pop hl   ; get rid of saved I
	FORTH_LOOP_POP     ; get rid of limit

	FORTH_RSP_POP     ; get rid of DO ptr

if DEBUG_FORTH_WORDS
			DMARK "LP>"
;	push af
;	ld a, '>'
;	ld (debug_mark),a
;	pop af
	CALLMONITOR
endif

		NEXTW
	; if not at limit. Inc I and update TOS get RTS off stack and reset parser

.loopnotdone:

	pop hl    ; get I
	inc hl

   	; save new I


		; set I counter

		ld (os_current_i), hl

		if DEBUG_FORTH_WORDS
			DMARK "LPN"
			;push af
			;ld a, '6'
			;ld (debug_mark),a
			;pop af
		CALLMONITOR
		endif
		
	FORTH_LOOP_NEXT


		if DEBUG_FORTH_WORDS
			ex de,hl
		endif

;	; get DO ptr
;
		if DEBUG_FORTH_WORDS
			DMARK "LP7"
			;push af
			;ld a, '7'
			;ld (debug_mark),a
			;pop af
		CALLMONITOR
		endif
	FORTH_RSP_TOS

		if DEBUG_FORTH_WORDS
			DMARK "LP8"
			;push af
			;ld a, '8'
			;ld (debug_mark),a
			;pop af
		CALLMONITOR
		endif
	;push hl

	; not going to DO any more
	; get rid of the RSP pointer as DO will add it back in
	;FORTH_RSP_POP
	;pop hl

	;ld hl,(cli_ret_sp)
	;ld e, (hl)
	;inc hl
	;ld d, (hl)
	;ex de,hl
	ld (os_tok_ptr), hl
		if DEBUG_FORTH_WORDS
			DMARK "LP<"
			;push af
			;ld a, '<'
			;ld (debug_mark),a
			;pop af
		CALLMONITOR
	endif
	jp exec1

		


		NEXTW
.I: 

	CWHEAD .DLOOP 74 "I" 1 WORD_FLAG_CODE
;	db "I",0               ;| I ( -- ) Current loop counter | DONE

		ld hl,(os_current_i)
		call forth_push_numhl

		NEXTW
.DLOOP:
	CWHEAD .REPEAT 75 "-LOOP" 5 WORD_FLAG_CODE
;	db 14
;	dw .COLN
;	db 5
;	db "LOOP",0      
; | -LOOP ( -- )    Decrement and test loop counter  | DONE
	; pop tos as current loop count to hl

	; if new tos (loop limit) is not same as hl, inc hl, push hl to tos, pop rsp and set pc to it

	FORTH_LOOP_TOS
	push hl

		if DEBUG_FORTH_WORDS
			DMARK "-LP"
			;push af
			;ld a, 'l'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif
	; next item on the stack is the limit. get it


	FORTH_LOOP_POP

	FORTH_LOOP_TOS

	pop de		 ; de = i, hl = limit

		if DEBUG_FORTH_WORDS
			DMARK "-L1"
;			push af
;			ld a, 'l'
;			ld (debug_mark),a
;			pop af
			CALLMONITOR
		endif

	; go back to previous word

	push de    ; save I for inc later


	; get limit
	;  is I at limit?


		if DEBUG_FORTH_WORDS
			DMARK "-L1"
			;push af
			;ld a, 'L'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif

	sbc hl, de


	;  if at limit pop both limit and current off stack do NEXT and get rid of saved DO

		jr nz, .mloopnotdone

	pop hl   ; get rid of saved I
	FORTH_LOOP_POP     ; get rid of limit

	FORTH_RSP_POP     ; get rid of DO ptr

if DEBUG_FORTH_WORDS
			DMARK "-L>"
;	push af
;	ld a, '>'
;	ld (debug_mark),a
;	pop af
	CALLMONITOR
endif

		NEXTW
	; if not at limit. Inc I and update TOS get RTS off stack and reset parser

.mloopnotdone:

	pop hl    ; get I
	dec hl

   	; save new I


		; set I counter

		ld (os_current_i), hl

		
	FORTH_LOOP_NEXT


		if DEBUG_FORTH_WORDS
			ex de,hl
		endif

;	; get DO ptr
;
	FORTH_RSP_TOS

	;push hl

	; not going to DO any more
	; get rid of the RSP pointer as DO will add it back in
	;FORTH_RSP_POP
	;pop hl


	ld (os_tok_ptr), hl
		if DEBUG_FORTH_WORDS
			DMARK "-L<"
			;push af
			;ld a, '<'
			;ld (debug_mark),a
			pop af
		CALLMONITOR
	endif
	jp exec1

		



	NEXTW




.REPEAT:
	CWHEAD .UNTIL 93 "REPEAT" 5 WORD_FLAG_CODE
;| REPEAT ( --  ) Start REPEAT...UNTIL loop  | DONE
;  push pc to rsp stack past the REPEAT

		ld hl, (os_tok_ptr)
		inc hl   ; R
		inc hl  ; E
		inc hl   ; P
		inc hl   ; E
		inc hl   ; A
		inc hl   ; T
		inc hl   ; zero
		FORTH_RSP_NEXT


		if DEBUG_FORTH_WORDS
			DMARK "REP"
			;pop bc    ; TODO BUG ?????? what is this for????
			;push af
			;ld a, 'R'
			;ld (debug_mark),a
			pop af
			CALLMONITOR
		endif

		NEXTW
;	       NEXTW

.UNTIL:
	CWHEAD .ENDFLOW 94 "UNTIL" 5 WORD_FLAG_CODE
;| UNTIL ( u -- ) Exit REPEAT...UNTIL loop if TOS is false  | DONE

	; pop tos as check

	; if new tos (loop limit) is not same as hl, inc hl, push hl to tos, pop rsp and set pc to it

	FORTH_DSP_VALUEHL

		if DEBUG_FORTH_WORDS
			DMARK "UNT"
	;		push af
;			ld a, 'U'
;			ld (debug_mark),a
;			pop af
			CALLMONITOR
		endif

	push hl
	FORTH_DSP_POP

	pop hl

	; test if true


	ld a,l
	add h

	cp 0

	jr nz, .untilnotdone

		if DEBUG_FORTH_WORDS
			DMARK "UNf"
			;push af
			;ld a, 'f'
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif



	FORTH_RSP_POP     ; get rid of DO ptr

if DEBUG_FORTH_WORDS
			DMARK "UN>"
;	push af
;	ld a, '>'
;	ld (debug_mark),a
;	pop af
	CALLMONITOR
endif

		NEXTW
	; if not at limit. Inc I and update TOS get RTS off stack and reset parser

.untilnotdone:


;	; get DO ptr
;
	FORTH_RSP_TOS

	;push hl

	; not going to DO any more
	; get rid of the RSP pointer as DO will add it back in
	;FORTH_RSP_POP
	;pop hl


	ld (os_tok_ptr), hl
		if DEBUG_FORTH_WORDS
			DMARK "UN<"
			;push af
			;ld a, '<'
			;ld (debug_mark),a
			;pop af
		CALLMONITOR
	endif
	jp exec1

		


		NEXTW


.ENDFLOW:

; eof

