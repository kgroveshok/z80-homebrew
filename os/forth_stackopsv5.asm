
; Stack operations for v5 parser on wards
; * DATA stack
; * LOOP stack
; * RETURN stack



FORTH_CHK_DSP_UNDER: macro
	push hl
	push de
	ld hl,(cli_data_sp)
	ld de, cli_data_stack
	call cmp16
	jp c, fault_dsp_under
	pop de
	pop hl
	endm


FORTH_CHK_RSP_UNDER: macro
	push hl
	push de
	ld hl,(cli_ret_sp)
	ld de, cli_ret_stack
	call cmp16
	jp c, fault_rsp_under
	pop de
	pop hl
	endm

FORTH_CHK_LOOP_UNDER: macro
	push hl
	push de
	ld hl,(cli_loop_sp)
	ld de, cli_loop_stack
	call cmp16
	jp c, fault_loop_under
	pop de
	pop hl
	endm

FORTH_ERR_TOS_NOTSTR: macro
	; TOSO might need more for checks when used
	push af
	ld a,(hl)
	cp DS_TYPE_STR
	jp nz, type_faultn  
	pop af
	endm

FORTH_ERR_TOS_NOTNUM: macro
	push af
	ld a,(hl)
	cp DS_TYPE_INUM
	jp nz, type_faultn  
	pop af
	endm


; increase data stack pointer and save hl to it
	
FORTH_DSP_NEXT: macro
	call macro_forth_dsp_next
	endm


macro_forth_dsp_next:
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	push hl
	push de
	ex de,hl
	ld hl,(cli_data_sp)
	inc hl
	inc hl

; PARSEV5
	inc hl
	ld (cli_data_sp),hl
	ld (hl), e
	inc hl
	ld (hl), d
	pop de
	pop hl
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	ret


; increase ret stack pointer and save hl to it
	
FORTH_RSP_NEXT: macro
	call macro_forth_rsp_next
	endm

macro_forth_rsp_next:
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	push hl
	push de
	ex de,hl
	ld hl,(cli_ret_sp)
	inc hl
	inc hl
	ld (cli_ret_sp),hl
	ld (hl), e
	inc hl
	ld (hl), d
	pop de
	pop hl
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	ret

; get current ret stack pointer and save to hl 
	
FORTH_RSP_TOS: macro
	call macro_forth_rsp_tos
	endm

macro_forth_rsp_tos:
	push de
	ld hl,(cli_ret_sp)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
		if DEBUG_FORTH_WORDS
			DMARK "RST"
			CALLMONITOR
		endif
	pop de
	ret

; pop ret stack pointer
	
FORTH_RSP_POP: macro
	call macro_forth_rsp_pop
	endm


macro_forth_rsp_pop:
	if DEBUG_FORTH_STACK_GUARD
		DMARK "RPP"
		call check_stacks
		FORTH_CHK_RSP_UNDER
	endif
	push hl
	ld hl,(cli_ret_sp)


	if FORTH_ENABLE_FREE

		; get pointer

		push de
		push hl

		ld e, (hl)
		inc hl
		ld d, (hl)

		ex de, hl
		call free

		pop hl
		pop de


	endif


	dec hl
	dec hl
	ld (cli_ret_sp), hl
	; TODO do stack underflow checks
	pop hl
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
		FORTH_CHK_RSP_UNDER
	endif
	ret




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
;    %xxxxx bin
;    xxxxx decimal
;    convert number to 16bit word. 
;    malloc word + 1 with flag to identiy as num
;    put pointer to number on stack
;  
; 
 
forth_apush:
	; kernel push

if DEBUG_FORTH_PUSH
			DMARK "PSH"
	CALLMONITOR
endif	
	; identify input type

	ld a,(hl)
	cp '"'
	jr z, .fapstr
	cp '$'
	jp z, .faphex
	cp '%'
	jp z, .fapbin
;	cp 'b'
;	jp z, .fabin
	; else decimal

	; TODO do decimal conversion
	; decimal is stored as a 16bit word

	; by default everything is a string if type is not detected
	jp .defstr


.fapstr:

if DEBUG_FORTH_PUSH
			DMARK "PSQ"
	CALLMONITOR
endif	
   
	; get string length
	inc hl ; skip past current double quote and look for the last one
	ld (cli_origptr), hl
	push hl
	push hl

if DEBUG_FORTH_PUSH
			DMARK "PQ1"
	CALLMONITOR
endif	
	ld a, 0   ; find end of string
	call strlent      
if DEBUG_FORTH_PUSH
			DMARK "PQ2"
	CALLMONITOR
endif	
	ex de, hl
	pop hl   ; get ptr to start of string
if DEBUG_FORTH_PUSH
			DMARK "PQ3"
	CALLMONITOR
endif	
	add hl,de
if DEBUG_FORTH_PUSH
			DMARK "PQE"
	CALLMONITOR
endif	

	dec hl    ; see if there is an optional trailing double quote
	ld a,(hl)
	cp '"'
	jr nz, .strnoq
	ld a, 0      ; get rid of double quote
	ld (hl), a
.strnoq: inc hl

	ld a, 0
	ld (hl), a     ; add null term and get rid of trailing double quote

	pop hl
.defstr:	
if DEBUG_FORTH_PUSH
			DMARK "PDF"
	CALLMONITOR
endif	
	ld a, 0    ; set null string term
	call strlent      

	ld a,l

	inc a ; add one for the type string
	inc a ; add one for null term???

if DEBUG_FORTH_PUSH
			DMARK "PH1"
	CALLMONITOR
endif	
	;push af
if DEBUG_FORTH_PUSH
	; see if disabled
	push af

	ld a, (os_view_disable)
	cp '*'
	jr z, .pskip1

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
.pskip1:
	pop af
endif	

	; TODO malloc + 1

	add 1    ; to be safe for some reason - max of 255 char for string
	ld h,0
	ld l,a
if DEBUG_FORTH_PUSH
			DMARK "PH2"
	CALLMONITOR
endif	
	call malloc	; on ret hl now contains allocated memory
if DEBUG_FORTH_PUSH
			DMARK "PH3"
	CALLMONITOR
endif	
	if DEBUG_FORTH_MALLOC_GUARD
		call z,malloc_error
	endif

	push hl
if DEBUG_FORTH_PUSH
			DMARK "PH4"
	CALLMONITOR
endif	

;	; flag set as str


;	ld (hl), DS_TYPE_STR
;	inc hl

	; copy string to malloc area

	ex de,hl
	ld hl, (cli_origptr)
	ld b,0
	ld c, a

; BUG memory over write of malloc structures. This dec resolves the issue - not a huge problem as 5 bytes are added to any string length above.
; is it related to ldir doing zer0 inclusive and so the length of data should be less one?
; Furthermore it appears the number push has this flaw. it is possible my counter sound be 0 index based
; will make changes to malloc to handle this possiblity
;dec bc

	ldir


	; push malloc to data stack     macro????? 

;	pop hl ; get malloc root
;	ld (hl), e
;	inc hl
;	ld (hl), d		


	FORTH_DSP_NEXT

;	ld hl,(cli_data_sp)
;	inc hl
;	inc hl
;	ld (cli_data_sp), hl

	; save value and type

;	pop hl

	ld hl, (cli_data_sp)

	; save item type
	ld a,  DS_TYPE_STR
	ld (hl), a
	inc hl

	; get malloc word off stack
	pop de
	ld a,e
	ld (hl), a
	inc hl
	ld a,d
	ld (hl), a



if DEBUG_FORTH_PUSH
			DMARK "PHS"
	CALLMONITOR
;	ex de,hl
endif	
	; in case of spaces, skip the ptr past the copied string
	;pop af
	;ld (cli_origptr),hl

	ret

.fapbin:    ; push a binary string. 
	ld de, 0   ; hold a 16bit value

.fapbinshift:	inc hl 
	ld a,(hl)
	cp 0     ; done scanning 
	jr z, .fapbdone  	; got it in HL so push 

	; left shift de
	ex de, hl	
	add hl, hl

	; is 1
	cp '1'
	jr nz, .binzero
	bit 1, l
.binzero:
	ex de, hl	 ; save current de
	jr .fapbinshift

.fapbdone:
	ex de, hl
	jr .faprawhl





.faphex:   ; hex is always stored as a 16bit word
	; skip number prefix
	inc hl
	; turn ascii into number
	call get_word_hl	; ret 16bit word in hl

.faprawhl:		; entry point for pushing a value when already in hl used in function above
	push hl    ; save value to push

if DEBUG_FORTH_PUSH
	; see if disabled


	push af
	ld a, (os_view_disable)
	cp '*'
	jr z, .pskip2
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
.pskip2: 

	pop af
endif	

	; get malloc for the storage (a bit of an overhead but makes it compatible with string push

;	ld hl, 5
;	call malloc
;	if DEBUG_FORTH_MALLOC_GUARD
;		call z,malloc_error
;	endif

;	push hl		; once to save on to data stack
;	push hl		; once to save word into

;;if DEBUG_FORTH_MALLOC
;;	call display_data_malloc 
;;endif
;	
;	; push malloc to data stack     macro????? 

	FORTH_DSP_NEXT

;	ld hl,(cli_data_sp)
;	inc hl
;	inc hl
;
;	ld (cli_data_sp),hl
;
;	pop de ; get malloc root
;	ld (hl), e
;	inc hl
;	ld (hl), d		

	; save value and type

;	pop hl

	ld hl, (cli_data_sp)

	; save item type
	ld a,  DS_TYPE_INUM
	ld (hl), a
	inc hl

	; get word off stack
	pop de
	ld a,e
	ld (hl), a
	inc hl
	ld a,d
	ld (hl), a

if DEBUG_FORTH_PUSH
	dec hl
	dec hl
	dec hl
			DMARK "PH5"
	CALLMONITOR
endif	



	ret
	 nop

.fabin:   ; TODO bin conversion



	ret


; get either a string ptr or a 16bit word from the data stack

FORTH_DSP: macro
	call macro_forth_dsp
	endm

macro_forth_dsp:
	; data stack pointer points to current word on tos

	ld hl,(cli_data_sp)

	if DEBUG_FORTH_PUSH
			DMARK "DSP"

		call display_data_sp
	;call break_point_state
	;rst 030h
	CALLMONITOR
	endif

	ret

; return hl to start of value on stack

FORTH_DSP_VALUE: macro
	call macro_forth_dsp_value
	endm

macro_forth_dsp_value:

	FORTH_DSP

	push de

	inc hl ; skip type

	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de,hl 

	pop de

	ret

; return hl to start of value to second item on stack

FORTH_DSP_VALUEM1: macro
	call macro_forth_dsp_value_m1
	endm

macro_forth_dsp_value_m1:

	FORTH_DSP

	dec hl
	dec hl
;	dec hl

	push de

	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de,hl 

	pop de

	ret

	

; whatever the current top os stack points to, we are now done with it so return memory to malloc

FORTH_DSP_POP: macro
	call macro_forth_dsp_pop
	endm


; get the tos data type

FORTH_DSP_TYPE:   macro

	;FORTH_DSP_VALUE
	FORTH_DSP
	
	; hl points to value
	; check type

	ld a,(hl)

	endm

; load the tos value into hl


FORTH_DSP_VALUEHL:  macro
	call macro_dsp_valuehl
	endm



macro_dsp_valuehl:
	FORTH_DSP_VALUE

	;FORTH_ERR_TOS_NOTNUM

	;inc hl   ; skip type id

;	push de
;
;	ld e, (hl)
;	inc hl
;	ld d, (hl)
;	ex de,hl 

;	pop de

	if DEBUG_FORTH_PUSH
			DMARK "DVL"
	CALLMONITOR
	endif
	ret

forth_apushstrhl:     
	; push of string requires use of cli_origptr
	; bodge use

	; get current cli_origptr, save, update with temp pointer 
	ld de, (cli_origptr)
	ld (cli_origptr), hl
	push de
	call forth_apush
	pop de
	ld (cli_origptr), de
        ret	


; increase loop stack pointer and save hl to it
	
FORTH_LOOP_NEXT: macro
	call macro_forth_loop_next
	;nop
	endm

macro_forth_loop_next:
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	push hl
	push de
	ex de,hl
	ld hl,(cli_loop_sp)
	inc hl
	inc hl
		if DEBUG_FORTH_WORDS
			DMARK "LNX"
			CALLMONITOR
		endif
	ld (cli_loop_sp),hl
	ld (hl), e
	inc hl
	ld (hl), d
	pop de    ; been reversed so save a swap on restore
	pop hl
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	ret

; get current ret stack pointer and save to hl 
	
FORTH_LOOP_TOS: macro
	call macro_forth_loop_tos
	endm

macro_forth_loop_tos:
	push de
	ld hl,(cli_loop_sp)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	pop de
	ret

; pop loop stack pointer
	
FORTH_LOOP_POP: macro
	call macro_forth_loop_pop
	endm


macro_forth_loop_pop:
	if DEBUG_FORTH_STACK_GUARD
		DMARK "LPP"
		call check_stacks
		FORTH_CHK_LOOP_UNDER
	endif
	push hl
	ld hl,(cli_loop_sp)
	dec hl
	dec hl
	ld (cli_loop_sp), hl
	; TODO do stack underflow checks
	pop hl
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
		FORTH_CHK_LOOP_UNDER
	endif
	ret

macro_forth_dsp_pop:

	push hl

	; release malloc data

	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
		FORTH_CHK_DSP_UNDER
	endif
	;ld hl,(cli_data_sp)
if DEBUG_FORTH_DOT
	DMARK "DPP"
	CALLMONITOR
endif	


if FORTH_ENABLE_DSPPOPFREE

	FORTH_DSP

	ld a, (hl)
	cp DS_TYPE_STR
	jr nz, .skippopfree

	FORTH_DSP_VALUEHL
	nop
if DEBUG_FORTH_DOT
	DMARK "DPf"
	CALLMONITOR
endif	
	call free
.skippopfree:
	

endif

if DEBUG_FORTH_DOT_KEY
	DMARK "DP2"
	CALLMONITOR
endif	

	; move pointer down

	ld hl,(cli_data_sp)
	dec hl
	dec hl
; PARSEV5
	dec hl
	ld (cli_data_sp), hl

	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
		FORTH_CHK_DSP_UNDER
	endif

	pop hl

	ret
; eof

