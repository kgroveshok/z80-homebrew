
; | ## String Words

.PTR:  

	CWHEAD .STYPE 52 "PTR" 3 WORD_FLAG_CODE
; | PTR ( -- addr ) Low level push pointer to the value on TOS | DONE
; | | If a string will give the address of the string without dropping it. Handy for direct string access
; | | If a number can then use 2@ and 2! for direct value update without using stack words 

		if DEBUG_FORTH_WORDS_KEY
			DMARK "PTR"
			CALLMONITOR
		endif
		FORTH_DSP_VALUEHL
		call forth_push_numhl


		NEXTW
.STYPE:
	CWHEAD .UPPER 52 "STYPE" 5 WORD_FLAG_CODE
; | STYPE ( u -- u type ) Push type of value on TOS - 's' string, 'i' integer...   | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "STY"
			CALLMONITOR
		endif
		FORTH_DSP
		;v5 FORTH_DSP_VALUE

		ld a, (hl)

		push af

; Dont destroy TOS		FORTH_DSP_POP

		pop af

		cp DS_TYPE_STR
		jr z, .typestr

		cp DS_TYPE_INUM
		jr z, .typeinum

		ld hl, .tna
		jr .tpush

.typestr:	ld hl, .tstr
		jr .tpush
.typeinum:	ld hl, .tinum
		jr .tpush

.tpush:

		call forth_push_str

		NEXTW
.tstr:	db "s",0
.tinum:  db "i",0
.tna:   db "?", 0


.UPPER:
	CWHEAD .LOWER 52 "UPPER" 5 WORD_FLAG_CODE
; | UPPER ( s -- s ) Upper case string s  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "UPR"
			CALLMONITOR
		endif

		FORTH_DSP
		
; TODO check is string type

		FORTH_DSP_VALUEHL
; get pointer to string in hl

.toup:		ld a, (hl)
		cp 0
		jr z, .toupdone

		call to_upper

		ld (hl), a
		inc hl
		jr .toup

		


; for each char convert to upper
		
.toupdone:


		NEXTW
.LOWER:
	CWHEAD .TCASE 52 "LOWER" 5 WORD_FLAG_CODE
; | LOWER ( s -- s ) Lower case string s  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "LWR"
			CALLMONITOR
		endif

		FORTH_DSP
		
; TODO check is string type

		FORTH_DSP_VALUEHL
; get pointer to string in hl

.tolow:		ld a, (hl)
		cp 0
		jr z, .tolowdone

		call to_lower

		ld (hl), a
		inc hl
		jr .tolow

		


; for each char convert to low
		
.tolowdone:
		NEXTW
.TCASE:
	CWHEAD .SUBSTR 52 "TCASE" 5 WORD_FLAG_CODE
; | TCASE ( s -- s ) Title case string s  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "TCS"
			CALLMONITOR
		endif

		FORTH_DSP
		
; TODO check is string type

		FORTH_DSP_VALUEHL
; get pointer to string in hl

		if DEBUG_FORTH_WORDS
			DMARK "TC1"
			CALLMONITOR
		endif

		; first time in turn to upper case first char

		ld a, (hl)
		jp .totsiptou


.tot:		ld a, (hl)
		cp 0
		jp z, .totdone

		if DEBUG_FORTH_WORDS
			DMARK "TC2"
			CALLMONITOR
		endif
		; check to see if current char is a space

		cp ' '
		jr z, .totsp
		call to_lower
		if DEBUG_FORTH_WORDS
			DMARK "TC3"
			CALLMONITOR
		endif
		jr .totnxt

.totsp:         ; on a space, find next char which should be upper

		if DEBUG_FORTH_WORDS
			DMARK "TC4"
			CALLMONITOR
		endif
		;;

		cp ' '
		jr nz, .totsiptou
		inc hl
		ld a, (hl)
		if DEBUG_FORTH_WORDS
			DMARK "TC5"
			CALLMONITOR
		endif
		jr .totsp
.totsiptou:    cp 0
		jr z, .totdone
		; not space and not zero term so upper case it
		call to_upper

		if DEBUG_FORTH_WORDS
			DMARK "TC6"
			CALLMONITOR
		endif


.totnxt:

		ld (hl), a
		inc hl
		if DEBUG_FORTH_WORDS
			DMARK "TC7"
			CALLMONITOR
		endif
		jp .tot

		


; for each char convert to low
		
.totdone:
		if DEBUG_FORTH_WORDS
			DMARK "TCd"
			CALLMONITOR
		endif
		NEXTW

.SUBSTR:
	CWHEAD .LEFT 52 "SUBSTR" 6 WORD_FLAG_CODE
; | SUBSTR ( s u1 u2 -- s sb ) Push to TOS chars starting at position u1 and with length u2 from string s  | DONE

		if DEBUG_FORTH_WORDS_KEY
			DMARK "SST"
			CALLMONITOR
		endif
; TODO check string type
		FORTH_DSP_VALUEHL

		push hl      ; string length

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		push hl     ; start char

		FORTH_DSP_POP


		FORTH_DSP_VALUE

		pop de    ; get start post offset

		add hl, de    ; starting offset

		pop bc
		push bc      ; grab size of string

		push hl    ; save string start 

		ld h, 0
		ld l, c
		inc hl
		inc hl

		call malloc
	if DEBUG_FORTH_MALLOC_GUARD
		call z,malloc_error
	endif

		ex de, hl      ; save malloc area for string copy
		pop hl    ; get back source
		pop bc    ; get length of string back

		push de    ; save malloc area for after we push
		ldir     ; copy substr


		ex de, hl
		ld a, 0
		ld (hl), a   ; term substr

		
		pop hl    ; get malloc so we can push it
		push hl   ; save so we can free it afterwards

		call forth_push_str

		pop hl
		call free

		
		


		NEXTW

.LEFT:
	CWHEAD .RIGHT 52 "LEFT" 4 WORD_FLAG_CODE
; | LEFT ( s u -- s sub ) Push to TOS string u long starting from left of s  | TODO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "LEF"
			CALLMONITOR
		endif

		NEXTW
.RIGHT:
	CWHEAD .STR2NUM 52 "RIGHT" 5 WORD_FLAG_CODE
; | RIGHT ( s u -- s sub ) Push to TOS string u long starting from right of s  | TODO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "RIG"
			CALLMONITOR
		endif

		NEXTW


.STR2NUM:
	CWHEAD .NUM2STR 52 "STR2NUM" 7 WORD_FLAG_CODE
; | STR2NUM ( s -- n ) Convert a string on TOS to number | DONE


; TODO STR type check to do
		if DEBUG_FORTH_WORDS_KEY
			DMARK "S2N"
			CALLMONITOR
		endif

		;FORTH_DSP
		FORTH_DSP_VALUE
		;inc hl

		ex de, hl
		if DEBUG_FORTH_WORDS
			DMARK "S2a"
			CALLMONITOR
		endif
		call string_to_uint16

		if DEBUG_FORTH_WORDS
			DMARK "S2b"
			CALLMONITOR
		endif
;		push hl
		FORTH_DSP_POP
;		pop hl
		
		if DEBUG_FORTH_WORDS
			DMARK "S2b"
			CALLMONITOR
		endif
		call forth_push_numhl	

	
	       NEXTW
.NUM2STR:
	CWHEAD .CONCAT 52 "NUM2STR" 7 WORD_FLAG_CODE
; | NUM2STR ( n -- s ) Convert a number on TOS to string | NOT DOING

;		; malloc a string to target
;		ld hl, 10     ; TODO max string size should be fine
;		call malloc
;		push hl    ; save malloc location
;
;
;; TODO check int type
;		FORTH_DSP_VALUEHL
;		ld a, l
;		call DispAToASCII  
;;TODO need to chage above call to dump into string
;
;

	       NEXTW

.CONCAT:
	CWHEAD .FIND 52 "CONCAT" 6 WORD_FLAG_CODE
; | CONCAT ( s1 s2 -- s3 ) A s1 + s2 is pushed onto the stack | DONE

; TODO check string type
; TODO create macro to get pointer for next item on stack. Handy for lots of things

		if DEBUG_FORTH_WORDS_KEY
			DMARK "CON"
			CALLMONITOR
		endif


		FORTH_DSP_VALUE
		push hl   ; s2

		FORTH_DSP_POP

		FORTH_DSP_VALUE

		push hl   ; s1

		FORTH_DSP_POP
		

		; copy s1

	
		; save ptr
		pop hl 
		push hl
		ld a, 0
		call strlent
		;inc hl    ; zer0
		ld b, 0
		ld c, l
		pop hl		
		ld de, scratch	
		if DEBUG_FORTH_WORDS
			DMARK "CO1"
			CALLMONITOR
		endif
		ldir

		pop hl
		push hl
		push de


		ld a, 0
		call strlent
		inc hl    ; zer0
		inc hl
		ld b, 0
		ld c, l
		pop de
		pop hl		
		if DEBUG_FORTH_WORDS
			DMARK "CO2"
			CALLMONITOR
		endif
		ldir



		ld hl, scratch
		if DEBUG_FORTH_WORDS
			DMARK "CO5"
			CALLMONITOR
		endif

		call forth_push_str




	       NEXTW


.FIND:
	CWHEAD .LEN 55 "FIND" 4 WORD_FLAG_CODE
; | FIND ( s c -- s u ) Search the string s for the char c and push the position of the first occurance to TOS | DONE

		if DEBUG_FORTH_WORDS_KEY
			DMARK "FND"
			CALLMONITOR
		endif

; TODO check string type
		FORTH_DSP_VALUE

		push hl   
		ld a,(hl)    ; char to find  
; TODO change char to substr

		push af
		


		if DEBUG_FORTH_WORDS
			DMARK "FN1"
			CALLMONITOR
		endif

		FORTH_DSP_POP

		; string to search

		FORTH_DSP_VALUE

		pop de  ; d is char to find 

		if DEBUG_FORTH_WORDS
			DMARK "FN2"
			CALLMONITOR
		endif
		
		ld bc, 0
.findchar:      ld a,(hl)
		cp 0   		
		jr z, .finddone    
		cp d
		jr z, .foundchar
		inc bc
		inc hl
		if DEBUG_FORTH_WORDS
			DMARK "FN3"
			CALLMONITOR
		endif
		jr .findchar


.foundchar:	push bc
		pop hl
		jr .findexit


				

.finddone:     ; got to end of string with no find
		ld hl, 0
.findexit:

		if DEBUG_FORTH_WORDS
			DMARK "FNd"
			CALLMONITOR
		endif
	call forth_push_numhl

	       NEXTW

.LEN:
	CWHEAD .ASC 56 "COUNT" 5 WORD_FLAG_CODE
; | COUNT (  str -- str u1 ) Push the length of the string str on TOS as u1 | DONE

		if DEBUG_FORTH_WORDS_KEY
			DMARK "CNT"
			CALLMONITOR
		endif
; TODO check string type
		FORTH_DSP_VALUE


		if DEBUG_FORTH_WORDS
			DMARK "CN?"
			CALLMONITOR
		endif
		call strlenz
		if DEBUG_FORTH_WORDS
			DMARK "CNl"
			CALLMONITOR
		endif

		call forth_push_numhl



	       NEXTW
.ASC:
	CWHEAD .CHR 57 "ASC" 3 WORD_FLAG_CODE
; | ASC ( u -- n ) Get the ascii value of the first character of the string on the stack | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "ASC"
			CALLMONITOR
		endif
		FORTH_DSP_VALUE
		;v5 FORTH_DSP_VALUE
;		inc hl      ; now at start of numeric as string

		push hl

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop hl

		if DEBUG_FORTH_WORDS
			DMARK "AS1"
			CALLMONITOR
		endif
		; push the content of a onto the stack as a value

		ld a,(hl)   ; get char
		ld h,0
		ld l,a
		if DEBUG_FORTH_WORDS
			DMARK "AS2"
			CALLMONITOR
		endif
		call forth_push_numhl

	       NEXTW

.CHR:
	CWHEAD .ENDSTR 57 "CHR" 3 WORD_FLAG_CODE
; | CHR ( u -- n ) The ASCII character value of u is turned into a string n on the stack | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "CHR"
			CALLMONITOR
		endif
		FORTH_DSP_VALUEHL

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; save asci byte as a zero term string and push string

		ld a,l
		ld (scratch), a

		ld a, 0
		ld (scratch+1), a

		ld hl, scratch
		call forth_push_str


	       NEXTW




.ENDSTR:
; eof

