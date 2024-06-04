
.IF:
	CWHEAD .THEN 10 "IF" 2 WORD_FLAG_CODE
;  | IF ( w -- f )     If TOS is true exec code following up to THEN - Note: currently not supporting ELSE or nested IF | DONE
;
; eval TOS

	FORTH_DSP_VALUEHL

	push hl
	FORTH_DSP_POP
	pop hl

		if DEBUG_FORTH_WORDS
			DMARK "IF1"
			CALLMONITOR
		endif
	or a        ; clear carry flag
	ld de, 0
	ex de,hl
	sbc hl, de
	jp nz, .iftrue

		if DEBUG_FORTH_WORDS
			DMARK "IF2"
			CALLMONITOR
		endif

; if not true then skip to THEN

	; TODO get tok_ptr
	; TODO consume toks until we get to THEN

	ld hl, (os_tok_ptr)
		if DEBUG_FORTH_WORDS
			DMARK "IF3"
			CALLMONITOR
			
		endif
	ld de, .ifthen
		if DEBUG_FORTH_WORDS
			DMARK "IF4"
			CALLMONITOR
		endif
	call findnexttok 

		if DEBUG_FORTH_WORDS
			DMARK "IF5"
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
			CALLMONITOR
		endif

		NEXTW
.THEN:
	CWHEAD .ELSE 11 "THEN" 4 WORD_FLAG_CODE
; | THEN ( -- )    Does nothing. It is a marker for the end of an IF block | DONE
		NEXTW
.ELSE:
	CWHEAD .DO 12 "ELSE" 2 WORD_FLAG_CODE
; | ELSE ( -- )   Not supported - does nothing | TODO



		NEXTW
.DO:
	CWHEAD .LOOP 13 "DO" 2 WORD_FLAG_CODE
; | DO ( u1 u2 -- )   Loop starting at u2 with a limit of u1 | DONE

		if DEBUG_FORTH_WORDS
			DMARK "DO1"
			CALLMONITOR
		endif
;  push pc to rsp stack past the DO

		ld hl, (os_tok_ptr)
		inc hl   ; D
		inc hl  ; O
		inc hl   ; null
		if DEBUG_FORTH_WORDS
			DMARK "DO2"
			CALLMONITOR
		endif
		FORTH_RSP_NEXT
		if DEBUG_FORTH_WORDS
			DMARK "DO3"
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
			CALLMONITOR
		endif
		FORTH_DSP_POP

		if DEBUG_FORTH_WORDS
			DMARK "DO5"
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL
		push hl		 ; hl now has starting limit counter

		if DEBUG_FORTH_WORDS
			DMARK "DO6"
			CALLMONITOR
		endif
		FORTH_DSP_POP

; put counters on the loop stack

		pop hl			 ; limit counter
		pop de			; start counter

		; push limit counter

		if DEBUG_FORTH_WORDS
			DMARK "DO7"
			CALLMONITOR
		endif
		FORTH_LOOP_NEXT

		; push start counter

		ex de, hl
		if DEBUG_FORTH_WORDS
			DMARK "DO7"
			CALLMONITOR
		endif
		FORTH_LOOP_NEXT


		; init first round of I counter

		ld (os_current_i), hl

		if DEBUG_FORTH_WORDS
			DMARK "DO8"
			CALLMONITOR
		endif

		NEXTW
.LOOP:
	CWHEAD .I 14 "LOOP" 4 WORD_FLAG_CODE
; | LOOP ( -- )     Increment and test loop counter  | DONE

	; pop tos as current loop count to hl

	; if new tos (loop limit) is not same as hl, inc hl, push hl to tos, pop rsp and set pc to it

	FORTH_LOOP_TOS
	push hl

		if DEBUG_FORTH_WORDS
			DMARK "LOP"
			CALLMONITOR
		endif
	; next item on the stack is the limit. get it


	FORTH_LOOP_POP

	FORTH_LOOP_TOS

	pop de		 ; de = i, hl = limit

		if DEBUG_FORTH_WORDS
			DMARK "LP1"
			CALLMONITOR
		endif

	; go back to previous word

	push de    ; save I for inc later


	; get limit
	;  is I at limit?


		if DEBUG_FORTH_WORDS
			DMARK "LP1"
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
		CALLMONITOR
		endif
	FORTH_RSP_TOS

		if DEBUG_FORTH_WORDS
			DMARK "LP8"
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
; | -LOOP ( -- )    Decrement and test loop counter  | DONE
	; pop tos as current loop count to hl

	; if new tos (loop limit) is not same as hl, inc hl, push hl to tos, pop rsp and set pc to it

	FORTH_LOOP_TOS
	push hl

		if DEBUG_FORTH_WORDS
			DMARK "-LP"
			CALLMONITOR
		endif
	; next item on the stack is the limit. get it


	FORTH_LOOP_POP

	FORTH_LOOP_TOS

	pop de		 ; de = i, hl = limit

		if DEBUG_FORTH_WORDS
			DMARK "-L1"
			CALLMONITOR
		endif

	; go back to previous word

	push de    ; save I for inc later


	; get limit
	;  is I at limit?


		if DEBUG_FORTH_WORDS
			DMARK "-L1"
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
		CALLMONITOR
	endif
	jp exec1

		



	NEXTW




.REPEAT:
	CWHEAD .UNTIL 93 "REPEAT" 5 WORD_FLAG_CODE
; | REPEAT ( --  ) Start REPEAT...UNTIL loop  | DONE
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
			CALLMONITOR
		endif

		NEXTW
;	       NEXTW

.UNTIL:
	CWHEAD .ENDFLOW 94 "UNTIL" 5 WORD_FLAG_CODE
; | UNTIL ( u -- ) Exit REPEAT...UNTIL loop if TOS is false  | DONE

	; pop tos as check

	; if new tos (loop limit) is not same as hl, inc hl, push hl to tos, pop rsp and set pc to it

	FORTH_DSP_VALUEHL

		if DEBUG_FORTH_WORDS
			DMARK "UNT"
			CALLMONITOR
		endif

	push hl
	FORTH_DSP_POP

	pop hl

	; test if true

	call ishlzero
;	ld a,l
;	add h
;
;	cp 0

	jr nz, .untilnotdone

		if DEBUG_FORTH_WORDS
			DMARK "UNf"
			CALLMONITOR
		endif



	FORTH_RSP_POP     ; get rid of DO ptr

if DEBUG_FORTH_WORDS
			DMARK "UN>"
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
		CALLMONITOR
	endif
	jp exec1

		


		NEXTW


.ENDFLOW:

; eof

