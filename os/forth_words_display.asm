
.EMIT:
	CWHEAD .DOTH 7 "EMIT" 4 WORD_FLAG_CODE
; |  EMIT ( u -- )        Display ascii character  TOS   | DONE
		; get value off TOS and display it


		FORTH_DSP_VALUEHL

		ld a,l

		; TODO write to display

		ld (os_input), a
		ld a, 0
		ld (os_input+1), a
		
		ld a, (f_cursor_ptr)
		ld de, os_input
		call str_at_display


		ld a,(cli_autodisplay)
		cp 0
		jr z, .enoupdate
				call update_display
		.enoupdate:



		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
 

		NEXTW
.DOTH:
	CWHEAD .DOT 8 ".-" 2 WORD_FLAG_CODE
        ; | .- ( u -- )    Display TOS replacing any dashes with space   | DONE
		; get value off TOS and display it
	jp .dotgo
	NEXTW

.DOT:
	CWHEAD .CLS 8 "." 1 WORD_FLAG_CODE
        ; | . ( u -- )    Display TOS   | DONE
		; get value off TOS and display it

.dotgo:

		FORTH_DSP_VALUE 
if DEBUG_FORTH_DOT
	DMARK "DOT"
	CALLMONITOR
endif	
;		.print:

	ld a,(hl)  ; work out what type of value is on the TOS
	inc hl   ; position to the actual value
	cp DS_TYPE_STR
	jr nz, .dotnum1 

; display string
	ex de,hl
	jr .dotwrite

.dotnum1:
	cp DS_TYPE_INUM
	jr nz, .dotflot


; display number

;	push hl
;	call clear_display
;	pop hl

	ld e, (hl)
	inc hl
	ld d, (hl)
	ld hl, scratch
if DEBUG_FORTH_DOT
	DMARK "DT1"
	CALLMONITOR
endif	

	call uitoa_16
	ex de,hl

if DEBUG_FORTH_DOT
	DMARK "DT2"
	CALLMONITOR
endif	

;	ld de, os_word_scratch
	jr .dotwrite

.dotflot:   nop
; TODO print floating point number

.dotwrite:		ld a, (f_cursor_ptr)
		call str_at_display
ld a,(cli_autodisplay)
cp 0
jr z, .noupdate
		call update_display
.noupdate:
if DEBUG_FORTH_DOT_KEY
		call next_page_prompt
endif	
; TODO this pop off the stack causes a crash. i dont know why


if DEBUG_FORTH_DOT
	DMARK "DTh"
	CALLMONITOR
endif	

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

if DEBUG_FORTH_DOT
	DMARK "DTi"
	CALLMONITOR
endif	


		NEXTW

.CLS:
	CWHEAD .DRAW 33 "CLS" 3 WORD_FLAG_CODE
; | CLS ( -- ) clear frame buffer    | DONE
		call clear_display
		jp .home		; and home cursor
		NEXTW

.DRAW:
	CWHEAD .DUMP 34 "DRAW" 4 WORD_FLAG_CODE
; | DRAW ( -- ) Draw contents of current frame buffer  | DONE
		call update_display
		NEXTW

.DUMP:
	CWHEAD .CDUMP 35 "DUMP" 4 WORD_FLAG_CODE
; | DUMP ( x --  ) With address x display dump   | DONE
; TODO pop address to use off of the stack
		call clear_display

		; get address

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
	
		; save it for cdump

		ld (os_cur_ptr),hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		call dumpcont	; skip old style of param parsing	
		ret			; TODO command causes end of remaining parsing so cant do: $0000 DUMP $8000 DUMP
		NEXTW
.CDUMP:
	CWHEAD .DAT 36 "CDUMP" 5 WORD_FLAG_CODE
; | CDUMP ( -- ) continue dump of memory from DUMP | DONE
		call clear_display
		call dumpcont	
		ret			; TODO command causes end of remaining parsing so cant do: $0000 DUMP CDUMP $8000 DUMP
		NEXTW




.DAT:
	CWHEAD .HOME 41 "AT" 2 WORD_FLAG_CODE
; | AT ( u1 u2 -- )  Set next output via . or emit at row u2 col u1 | DONE
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol


		; TODO save cursor row
		ld a,l
		cp 2
		jr nz, .crow3
		ld a, display_row_2
		jr .ccol1
.crow3:		cp 3
		jr nz, .crow4
		ld a, display_row_3
		jr .ccol1
.crow4:		cp 4
		jr nz, .crow1
		ld a, display_row_4
		jr .ccol1
.crow1:		ld a,display_row_1
.ccol1:		push af			; got row offset
		ld l,a
		ld h,0
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		; TODO save cursor col
		pop af
		add l		; add col offset
		ld (f_cursor_ptr), a
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; calculate 

		NEXTW


.HOME:
	CWHEAD .SPACE 45 "HOME" 4 WORD_FLAG_CODE
; | HOME ( -- )    Reset the current cursor for output to home | DONE
.home:		ld a, 0		; and home cursor
		ld (f_cursor_ptr), a
		NEXTW


.SPACE:
	CWHEAD .SPACES 50 "SPACE" 5 WORD_FLAG_CODE
; | SPACE (  -- c ) Push the value of space onto the stack as a string  | DONE
		ld hl, ' '
		call forth_push_numhl
		
	       NEXTW

.SPACES:
	CWHEAD .SCROLL 51 "SPACES" 6 WORD_FLAG_CODE
; | SPACES ( u -- str )  A string of u spaces is pushed onto the stack | TO TEST


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u
		if DEBUG_FORTH_WORDS
			DMARK "SPA"
			CALLMONITOR
		endif

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		pop hl
		ld c, l
		ld b, 0
		ld hl, scratch 

		if DEBUG_FORTH_WORDS
			DMARK "SP2"
			CALLMONITOR
		endif
		ld a, ' '
.spaces1:	push bc
		ld (hl),a
		inc hl
		pop bc
		djnz .spaces1
		ld a,0
		ld (hl),a
		ld hl, scratch
		if DEBUG_FORTH_WORDS
			DMARK "SP3"
			CALLMONITOR
		endif
		call forth_apush

	       NEXTW



.SCROLL:
	CWHEAD .ATQ 63 "SCROLL" 6 WORD_FLAG_CODE
; | SCROLL ( u1 c1 -- ) Scroll u1 lines/chars in direction c1 | WIP

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl

		pop bc

		; TODO Get SPI byte

		NEXTW




.ATQ:
	CWHEAD .AUTODSP 78 "AT?" 3 WORD_FLAG_CODE
; | AT? ( u1 u2 -- n )  Push to stack ASCII value at row u2 col u1 | DONE

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		; TODO save cursor row
		ld a,l
		cp 2
		jr nz, .crow3aq
		ld a, display_row_2
		jr .ccol1aq
.crow3aq:		cp 3
		jr nz, .crow4aq
		ld a, display_row_3
		jr .ccol1aq
.crow4aq:		cp 4
		jr nz, .crow1aq
		ld a, display_row_4
		jr .ccol1aq
.crow1aq:		ld a,display_row_1
.ccol1aq:		push af			; got row offset
		ld l,a
		ld h,0
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		; TODO save cursor col
		pop af
		add l		; add col offset

		; get char at location
		ld a,(hl)
		ld h, 0
		ld l, a

		call forth_push_numhl


		NEXTW

; get rid of below code

	
		FORTH_DSP_POP

		pop hl

		ld h, a		; how many rows
		ld d, display_cols
		call Mult8

		push hl

		FORTH_DSP_VALUEHL
		push hl
	
		FORTH_DSP_POP

		pop hl
		pop de
		add hl, de

		ld a, (hl)

		ld h,0
		ld l, a
		call forth_push_numhl


	       NEXTW

.AUTODSP:
	CWHEAD .MENU 79 "ADSP" 4 WORD_FLAG_CODE
; | ADSP ( u1 --  )  Enable/Disable Auto screen updates (SLOW). If off, use DRAW to refresh. Default is on. $0003 will enable direct screen writes (TODO) | DONE

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop hl

		ld a,l
		ld (cli_autodisplay), a
	       NEXTW

.MENU:
	CWHEAD .ENDDISPLAY 92 "MENU" 4 WORD_FLAG_CODE
; | MENU ( u1....ux n ut -- n ) Create a menu. Ut is the title, n is the number of menu items on stack. Push number selection to TOS |
	       NEXTW


.ENDDISPLAY:

; eof
