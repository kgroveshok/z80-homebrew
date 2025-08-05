
; | ## Logic Words

.NOT:
	CWHEAD .IS 25 "NOT" 3 WORD_FLAG_CODE
; | NOT ( u  -- u ) Inverse true/false on stack | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "NOT"
			CALLMONITOR
		endif
		FORTH_DSP
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .noti
		NEXTW
.noti:          FORTH_DSP_VALUEHL
;		push hl
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
;		pop hl
		ld a,0
		cp l
		jr z, .not2t
		ld l, 0
		jr .notip

.not2t:		ld l, 255

.notip:		ld h, 0	

		call forth_push_numhl
		NEXTW

.IS:
	CWHEAD .LZERO 25 "IS" 2 WORD_FLAG_CODE
; | IS ( s1 s2  -- f ) Push true if string s1 is the same as s2 | TODO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "IS."
			CALLMONITOR
		endif
		NEXTW
.LZERO:
	CWHEAD .TZERO 25 "0<" 2 WORD_FLAG_CODE
; | 0< ( u -- f ) Push true if u is less than o | CANT DO UNTIL FLOAT
		NEXTW
.TZERO:
	CWHEAD .LESS 26 "0=" 2 WORD_FLAG_CODE
; | 0= ( u -- f ) Push true if u equals 0 | DONE
	; TODO add floating point number detection
		;v5 FORTH_DSP_VALUE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "0=."
			CALLMONITOR
		endif
		FORTH_DSP
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .tz_inum

	if FORTH_ENABLE_FLOATMATH
		jr .tz_done

	endif
		

.tz_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

;		pop hl

		ld a,0

		cp l
		jr nz, .tz_notzero

		cp h

		jr nz, .tz_notzero


		ld hl, FORTH_TRUE
		jr .tz_done

.tz_notzero:	ld hl, FORTH_FALSE

		; push value back onto stack for another op etc

.tz_done:
		call forth_push_numhl

		NEXTW
.LESS:
	CWHEAD .GT 27 "<" 1 WORD_FLAG_CODE
; | < ( u1 u2 -- f ) True if u1 is less than u2 | DONE
	; TODO add floating point number detection
		if DEBUG_FORTH_WORDS_KEY
			DMARK "LES"
			CALLMONITOR
		endif
		FORTH_DSP
		;v5 FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .less_inum

	if FORTH_ENABLE_FLOATMATH
		jr .less_done

	endif
		

.less_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl  ; u2

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u1

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


 or a      ;clear carry flag
 ld bc, FORTH_FALSE
  pop hl    ; u1
  pop de    ; u2
  sbc hl,de
  jr nc,.lscont   	;	if hl >= de, carry flag will be cleared

 ld bc, FORTH_TRUE
.lscont: 
		push bc
		pop hl

		if DEBUG_FORTH_WORDS
			DMARK "LT1"
			CALLMONITOR
		endif
		call forth_push_numhl

		NEXTW
.GT:
	CWHEAD .EQUAL 28 ">" 1 WORD_FLAG_CODE
; | > ( u1 u2 -- f ) True if u1 is greater than u2 | DONE
	; TODO add floating point number detection
		if DEBUG_FORTH_WORDS_KEY
			DMARK "GRT"
			CALLMONITOR
		endif
		FORTH_DSP
		;FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .gt_inum

	if FORTH_ENABLE_FLOATMATH
		jr .gt_done

	endif
		

.gt_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl  ; u2

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u1

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


 or a      ;clear carry flag
 ld bc, FORTH_FALSE
  pop hl    ; u1
  pop de    ; u2
  sbc hl,de
  jr c,.gtcont   	;	if hl >= de, carry flag will be cleared

 ld bc, FORTH_TRUE
.gtcont: 
		push bc
		pop hl

		if DEBUG_FORTH_WORDS
			DMARK "GT1"
			CALLMONITOR
		endif
		call forth_push_numhl

		NEXTW
.EQUAL:
	CWHEAD .ENDLOGIC 29 "=" 1 WORD_FLAG_CODE
; | = ( u1 u2 -- f ) True if u1 equals u2 | DONE
	; TODO add floating point number detection
		if DEBUG_FORTH_WORDS_KEY
			DMARK "EQ."
			CALLMONITOR
		endif
		FORTH_DSP
		;v5 FORTH_DSP_VALUE
		ld a,(hl)	; get type of value on TOS
		cp DS_TYPE_INUM 
		jr z, .eq_inum

	if FORTH_ENABLE_FLOATMATH
		jr .eq_done

	endif
		

.eq_inum:
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		; one value on hl get other one back

		push hl

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		ld c, FORTH_FALSE

		pop hl
		pop de

		ld a, e
		cp l

		jr nz, .eq_done

		ld a, d
		cp h

		jr nz, .eq_done

		ld c, FORTH_TRUE
		


.eq_done:

		; TODO push value back onto stack for another op etc

		ld h, 0
		ld l, c
		if DEBUG_FORTH_WORDS
			DMARK "EQ1"
			CALLMONITOR
		endif
		call forth_push_numhl

		NEXTW


.ENDLOGIC:
; eof


