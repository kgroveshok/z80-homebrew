
; | ## Maths Words

.PLUS:	
	CWHEAD .NEG 1 "+" 1 WORD_FLAG_CODE
; | + ( u u -- u )    Add two numbers and push result   | INT DONE
		; add top two values and push back result

		FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .dot_inum

	if FORTH_ENABLE_FLOATMATH
			inc hl      ; now at start of numeric as string

		if DEBUG_FORTH_DOT
			DMARK "ADD"
	CALLMONITOR
		endif

		;ld ix, hl
		call CON


		push hl
		
		

			FORTH_DSP_POP      ; TODO add stock underflow checks and throws 

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

		NEXTW
.NEG:

	CWHEAD .DIV 3 "-" 1 WORD_FLAG_CODE
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

		NEXTW
.DIV:
	CWHEAD .MUL 4 "/" 1 WORD_FLAG_CODE
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
			DMARK "DIV"
	CALLMONITOR
		endif
		; one value on hl but move to a get other one back

       
	call Div16

;	push af	
	push hl
	push bc

		if DEBUG_FORTH_MATHS
			DMARK "DI1"
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
		NEXTW
.MUL:
	CWHEAD .MIN 5 "*" 1 WORD_FLAG_CODE
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
		NEXTW




.MIN:
	CWHEAD .MAX 53 "MIN" 3 WORD_FLAG_CODE
; | MIN (  u1 u2 -- u3 ) Whichever is the smallest value is pushed back onto the stack | DONE
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
			DMARK "MIN"
			CALLMONITOR
		endif
		call forth_push_numhl

	       NEXTW

.mincont: 
	pop bc   ; tidy up
	ex de , hl 
		if DEBUG_FORTH_WORDS
			DMARK "MI1"
			CALLMONITOR
		endif
		call forth_push_numhl

	       NEXTW
.MAX:
	CWHEAD .RND16 54 "MAX" 3 WORD_FLAG_CODE
; | MAX (  u1 u2 -- u3 )  Whichever is the largest value is pushed back onto the stack | DONE
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
			DMARK "MAX"
			CALLMONITOR
		endif
		call forth_push_numhl

	       NEXTW

.maxcont: 
	pop bc   ; tidy up
	ex de , hl 
		if DEBUG_FORTH_WORDS
			DMARK "MA1"
			CALLMONITOR
		endif
		call forth_push_numhl
	       NEXTW

.RND16:
	CWHEAD .RND8 58 "RND16" 5 WORD_FLAG_CODE
; | RND16 (  -- n ) Generate a random 16bit number and push to stack | DONE
		call prng16 
		call forth_push_numhl
	       NEXTW
.RND8:
	CWHEAD .RND 76 "RND8" 4 WORD_FLAG_CODE
; | RND8 (  -- n ) Generate a random 8bit number and push to stack | DONE
		ld hl,(xrandc)
		inc hl
		call xrnd
		ld l,a	
		ld h,0
		call forth_push_numhl
	       NEXTW
.RND:
	CWHEAD .ENDMATHS 76 "RND" 3 WORD_FLAG_CODE
; | RND ( u1 u2 -- u ) Generate a random number no lower than u1 and no higher than u2 and push to stack | DONE

		if DEBUG_FORTH_WORDS
			DMARK "RND"
			CALLMONITOR
		endif
		
		FORTH_DSP_VALUEHL    ; upper range

		ld (LFSRSeed), hl	

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL    ; low range

		ld (LFSRSeed+2), hl

		FORTH_DSP_POP


.inrange:	call prng16 

		ld de, (LFSRSeed)     ; check high level
		call cmp16

		jr nc, .inrange

		ld de, (LFSRSeed+2)   ; check low range
		call cmp16
	
		jr z, .inrange

		


		call forth_push_numhl
	       NEXTW

.ENDMATHS:

; eof

