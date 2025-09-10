
; | ## String Words

.CONST:
	
	CWHEAD .MOVE 52 "CONST" 5 WORD_FLAG_CODE
; | CONST ( u -- u ) Change the type of var on TOS to a constant. i.e. if a string it won't be freed on consuption, | TODO
		FORTH_DSP
		ld (hl), DS_TYPE_CONST
		NEXTW

.MOVE:  

	CWHEAD .ZMOVE 52 "MOVE" 4 WORD_FLAG_CODE
; | MOVE ( a1 a2 c -- ) Copy from address a1 to address a2 for the length of c | DONE

		FORTH_DSP_VALUEHL
		push hl    ; push count

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL
		push hl    ; dest

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

		pop de
		pop bc
	
		ldir
	NEXTW
.ZMOVE:  

	CWHEAD .TABLE 52 "ZMOVE" 5 WORD_FLAG_CODE
		
; | ZMOVE ( a1 a2 -- ) Copy from address a1 to address a2 until a1 hits zero term string | DONE
; | | Ensure you have enough space!


		FORTH_DSP_VALUEHL
		push hl    ; dest

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

		pop de

		ld bc, 255
.zmovel:	ldi
		dec hl
		ld a,(hl)
		inc hl
		or a 
		jr nz, .zmovel   
		

	NEXTW

.TABLE:  

	CWHEAD .SPLIT 52 "TABLE" 5 WORD_FLAG_CODE
		
; | TABLE ( s .. sx c -- a) For the number c of strings s on the stack. Generate a look up table array a | DONE
; | | Takes a list of strings and creates a block of pointers to each string which can then be used
; | | in any kind of lookup or iteration. 
; | | Last item in the array will be a zero pointer for ease of iteration


	; get the count of strings

		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

	; allocate memory for (count + 1 ) * 2 for word array plus zero pointer

		; l contains count

		ld a,l
		ld (scratch), a     ; save it for the loading loop

		inc l  ; for zero pointer
		ex de, hl
		ld a, 2
		call Mult16

		; hl is the size of block to allocate

		call malloc
	if DEBUG_FORTH_MALLOC_GUARD
		call z,malloc_error
	endif
		; hl is the pointer to the array block
			
		ld (scratch+1), hl    ; save the base for later push to stack
		ld (scratch+3), hl    ; save the base for current string to push

		ld a, (scratch)
		ld b, a

	; for each string

.tablelop:

		push bc

	;     get string pointer

		FORTH_DSP_VALUEHL

		push hl

	;     get string length

		ld a,0
		call strlent

		inc hl
		push hl

	;     allocate string length

		call malloc

        ;     copy string to block

		pop bc
		ex de, hl
		pop hl
		push de

		ldir


        ;     add pointer to string to array block

		ld hl, (scratch+3)    ; save the base for current string to push

		pop de     ; the pointer to the newly copied string to add to the array
		ld (hl), e
		inc hl
		ld (hl), d	
		inc hl
	
		ld (scratch+3), hl    ; save the base for current string to push

		FORTH_DSP_POP

		pop bc
		djnz .tablelop

        ;  push array block pointer

		ld hl, (scratch+3)    ; save the base for current string to push
		ld (hl), 0
		inc hl
		ld (hl), 0


	
		ld hl, (scratch+1)    ; save the base for current string to push
		call forth_push_numhl

	NEXTW

.SPLIT:  

	CWHEAD .PTR 52 "SPLIT" 5 WORD_FLAG_CODE
; | SPLIT ( s d -- s s...sn c ) Using delimter d, add strings found in s to stack pushing item count c | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "SPT"
			CALLMONITOR
		endif

		; get delim
		FORTH_DSP_VALUEHL

		FORTH_DSP_POP
		

		ld b, l    ; move delim to b
		ld c, 1   ; count of poritions

		push bc

		if DEBUG_FORTH_WORDS
			DMARK "SPa"
			CALLMONITOR
		endif
		; get pointer to string to chop up
		FORTH_DSP_VALUEHL

;		push hl
		ld de, scratch
.spllop:
		pop bc
		push bc
;		pop hl
		if DEBUG_FORTH_WORDS
			DMARK "SPl"
			CALLMONITOR
		endif
		ld a, (hl)
		cp b
		jr z, .splnxt
;		cp 0
		or a
		jr z, .splend
		ldi
		jr .spllop

		; hit dlim

.splnxt:
		if DEBUG_FORTH_WORDS
			DMARK "SPx"
			CALLMONITOR
		endif
		ld a, 0
		ld (de), a
		;ex de, hl
		push hl
		ld hl, scratch
		call forth_push_str
		pop hl
		;ex de, hl
		inc hl
		pop bc
		inc c
		push bc
		ld de, scratch
		jr .spllop

.splend:		
		if DEBUG_FORTH_WORDS
			DMARK "SPe"
			CALLMONITOR
		endif
		ld (de), a
		ex de, hl
;		push hl
		ld hl, scratch
		call forth_push_str
		
		if DEBUG_FORTH_WORDS
			DMARK "SPc"
			CALLMONITOR
		endif

		pop hl    ; get counter from bc which has been push
		ld h, 0
;		ld l, c
		call forth_push_numhl


	NEXTW
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
; | STYPE ( u -- u type ) Push type of value on TOS  | DONE
; | | 's' string or 'i' integer or 'c' const
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
		cp DS_TYPE_CONST
		jr z, .typeconst

		cp DS_TYPE_INUM
		jr z, .typeinum

		ld hl, .tna
		jr .tpush

.typeconst:	ld hl, .tconst
		jr .tpush
.typestr:	ld hl, .tstr
		jr .tpush
.typeinum:	ld hl, .tinum
		jr .tpush

.tpush:

		call forth_push_str

		NEXTW
.tstr:	db "s",0
.tconst:	db "c",0
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
;		cp 0
		or a
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
;		cp 0
		or a
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
;		cp 0
		or a
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
.totsiptou:    
		;cp 0
		or a
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
;		ld a, 0
		ld (hl), 0   ; term substr

		
		pop hl    ; get malloc so we can push it
		push hl   ; save so we can free it afterwards

		call forth_push_str

		pop hl
		call free

		
		


		NEXTW

.LEFT:
	CWHEAD .RIGHT 52 "LEFT" 4 WORD_FLAG_CODE
; | LEFT ( s u -- s sub ) Push to TOS string u long starting from left of s  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "LEF"
			CALLMONITOR
		endif

		
; TODO check string type
		FORTH_DSP_VALUEHL

		push hl      ; string length

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		pop bc

		ld de, scratch
		ldir
		ld a, 0
		ld (de), a
		
		ld hl, scratch
		call forth_push_str

		NEXTW
.RIGHT:
	CWHEAD .STR2NUM 52 "RIGHT" 5 WORD_FLAG_CODE
; | RIGHT ( s u -- s sub ) Push to TOS string u long starting from right of s  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "RIG"
			CALLMONITOR
		endif

; TODO check string type
		FORTH_DSP_VALUEHL

		push hl      ; string length

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		if DEBUG_FORTH_WORDS
			DMARK "RI1"
			CALLMONITOR
		endif
		; from the pointer to string get to the end of string

		ld bc, 255
		ld a, 0
		cpir
		dec hl

		; 

		if DEBUG_FORTH_WORDS
			DMARK "RI2"
			CALLMONITOR
		endif

		pop bc    ;  length of string to copy

		ld a, c
		ex de, hl
		ld hl, scratch 
		call addatohl

		ex de, hl

		if DEBUG_FORTH_WORDS
			DMARK "RI3"
			CALLMONITOR
		endif

		inc bc
		lddr
		
		ld hl, scratch
		if DEBUG_FORTH_WORDS
			DMARK "RI4"
			CALLMONITOR
		endif
		call forth_push_str


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
; | NUM2STR ( n -- s ) Convert a number on TOS to zero padded string | DONE

;		; malloc a string to target
;		ld hl, 10     ; TODO max string size should be fine
;		call malloc
;		push hl    ; save malloc location
;
;
;; TODO check int type
		if DEBUG_FORTH_WORDS_KEY
			DMARK "N2S"
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL

		if DEBUG_FORTH_WORDS
			DMARK "NS1"
			CALLMONITOR
		endif
		FORTH_DSP_POP

		ex de, hl
		ld hl, scratch
		if DEBUG_FORTH_WORDS
			DMARK "NS2"
			CALLMONITOR
		endif
		call uitoa_16
		ld hl, scratch
		if DEBUG_FORTH_WORDS
			DMARK "NS3"
			CALLMONITOR
		endif
		call forth_push_str
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
;		cp 0   		
		or a
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
; | ASC ( u -- n ) Get the ASCII value of the first character of the string on TOS | DONE
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

