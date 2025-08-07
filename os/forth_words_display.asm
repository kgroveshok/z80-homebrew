
; | ## Display Words

.ACT:

	CWHEAD .INFO 78 "ACTIVE" 6 WORD_FLAG_CODE
; | ACTIVE ( -- s ) Push the next char for an activity indicator to TOS | DONE
; 
; | | To display a pulsing activity indicator in a processing loop do this...
; | | e.g. $ff $00 do active . ..... Your code ..... loop

		if DEBUG_FORTH_WORDS_KEY
			DMARK "ACT"
			CALLMONITOR
		endif
		call active
		if DEBUG_FORTH_WORDS
			DMARK "ACp"
			CALLMONITOR
		endif
		call forth_push_str

		NEXTW
.INFO:

	CWHEAD .ATP 78 "INFO" 4 WORD_FLAG_CODE
; | INFO ( u1 u2 -- )  Use the top two strings on stack to fill in an info window over two lines. Causes a wait for key press to continue. | DONE
		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

		push hl

		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

		pop de

		call info_panel


		NEXTW
.ATP:
	CWHEAD .FB 78 "AT?" 3 WORD_FLAG_CODE
; | AT? ( -- c r )  Push to stack the current position of the next print | TO TEST
		if DEBUG_FORTH_WORDS_KEY
			DMARK "AT?"
			CALLMONITOR
		endif
		ld a, (f_cursor_ptr)

if DEBUG_FORTH_WORDS
	DMARK "AT?"
	CALLMONITOR
endif	
		; count the number of rows

		ld b, 0
.atpr:		ld c, a    ; save in case we go below zero
		sub display_cols
		jp p, .atprunder
		inc b
		jr .atpr
.atprunder:	
if DEBUG_FORTH_WORDS
	DMARK "A?2"
	CALLMONITOR
endif	
		ld h, 0
		ld l, c
		call forth_push_numhl
		ld l, b 
		call forth_push_numhl


	NEXTW

.FB:
	CWHEAD .EMIT 7 "FB" 2 WORD_FLAG_CODE
; | FB ( u -- ) Select frame buffer ID u (1-3)  |  DONE
; | | Default frame buffer is 1. System uses 0 which can't be selected for system messages etc.
; | | Selecting the frame buffer wont display unless automatic display is setup (default).
; | | If automatic display is off then updates will not be shown until DRAW is used.
		if DEBUG_FORTH_WORDS_KEY
			DMARK "FB."
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL

		ld a, l
		cp 1
		jr nz, .fbn1
		ld hl, display_fb1
		jr .fbset
.fbn1:		cp 2
		jr nz, .fbn2
		ld hl, display_fb2
		jr .fbset
.fbn2:		cp 3
		jr nz, .fbn3
		ld hl, display_fb3
		jr .fbset
.fbn3:		 ; if invalid number select first
		ld hl, display_fb1
.fbset:		ld (display_fb_active), hl

		FORTH_DSP_POP

		NEXTW


.EMIT:
	CWHEAD .DOTH 7 "EMIT" 4 WORD_FLAG_CODE
; |  EMIT ( u -- ) Display ascii character  TOS   | DONE
		; get value off TOS and display it

		if DEBUG_FORTH_WORDS_KEY
			DMARK "EMT"
			CALLMONITOR
		endif

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

		ld a, (f_cursor_ptr)
		inc a
		ld (f_cursor_ptr), a   ; save new pos


		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
 

		NEXTW
.DOTH:
	CWHEAD .DOTF 8 ".-" 2 WORD_FLAG_CODE
        ; | .- ( u -- ) Display TOS replacing any dashes with spaces. Means you dont need to wrap strings in double quotes!   | DONE
		; get value off TOS and display it
		if DEBUG_FORTH_WORDS_KEY
			DMARK "DTD"
			CALLMONITOR
		endif
	ld c, 1	  ; flag for removal of '-' enabled
	ld a, 0
	ld (cli_mvdot), a
	jp .dotgo
	NEXTW
.DOTF:
	CWHEAD .DOT 8 ".>" 2 WORD_FLAG_CODE
        ; | .> ( u -- ) Display TOS and move the next display point with display  | DONE
		; get value off TOS and display it
        ; TODO BUG adds extra spaces
        ; TODO BUG handle numerics?
		if DEBUG_FORTH_WORDS_KEY
			DMARK "DTC"
			CALLMONITOR
		endif
	ld a, 1
	ld (cli_mvdot), a
	jp .dotgo
	NEXTW

.DOT:
	CWHEAD .CLS 8 "." 1 WORD_FLAG_CODE
        ; | . ( u -- ) Display TOS. Does not move next print position. Use .> if you want that. | DONE
		; get value off TOS and display it

		if DEBUG_FORTH_WORDS_KEY
			DMARK "DOT"
			CALLMONITOR
		endif
	ld a, 0
	ld (cli_mvdot), a
ld c, 0	  ; flag for removal of '-' disabled
	

.dotgo:

; move up type to on stack for parserv5
		FORTH_DSP
	;FORTH_DSP_VALUE 

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
	FORTH_DSP_VALUE 
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

.dotwrite:		

		; if c is set then set all '-' to spaces
		; need to also take into account .> 

		ld a, 1
		cp c
		jr nz, .nodashswap

		; DE has the string to write, working with HL

		ld b, 255
		push de
		pop hl

if DEBUG_FORTH_DOT
	DMARK "DT-"
	CALLMONITOR
endif	
.dashscan:	ld a, (hl)
		cp 0
		jr z, .nodashswap
		cp '-'
		jr nz, .dashskip
		ld a, ' '
		ld (hl), a
.dashskip:	inc hl
if DEBUG_FORTH_DOT
	DMARK "D-2"
	CALLMONITOR
endif	
		djnz .dashscan

if DEBUG_FORTH_DOT
	DMARK "D-1"
	CALLMONITOR
endif	

.nodashswap:

if DEBUG_FORTH_DOT
	DMARK "D-o"
	CALLMONITOR
endif	

		push de   ; save string start in case we need to advance print

		ld a, (f_cursor_ptr)
		call str_at_display
		ld a,(cli_autodisplay)
		cp 0
		jr z, .noupdate
				call update_display
		.noupdate:


		; see if we need to advance the print position

		pop hl   ; get back string
;		ex de,hl

		ld a, (cli_mvdot)
if DEBUG_FORTH_DOT
;		ld e,a
	DMARK "D>1"
	CALLMONITOR
endif	
		cp 0
		jr z, .noadv
		; yes, lets advance the print position
		ld a, 0
		call strlent
if DEBUG_FORTH_DOT
	DMARK "D-?"
	CALLMONITOR
endif	
		ld a, (f_cursor_ptr)
		add a,l
		;call addatohl
		;ld a, l
		ld (f_cursor_ptr), a   ; save new pos

if DEBUG_FORTH_DOT
	DMARK "D->"
	CALLMONITOR
endif	

.noadv:	

		if DEBUG_FORTH_DOT_WAIT
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
; | CLS ( -- ) Clear current frame buffer and set next print position to top left corner  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "CLS"
			CALLMONITOR
		endif
		call clear_display
		jp .home		; and home cursor
		NEXTW

.DRAW:
	CWHEAD .DUMP 34 "DRAW" 4 WORD_FLAG_CODE
; | DRAW ( -- ) Draw contents of current frame buffer  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "DRW"
			CALLMONITOR
		endif
		call update_display
		NEXTW

.DUMP:
	CWHEAD .CDUMP 35 "DUMP" 4 WORD_FLAG_CODE
; | DUMP ( x -- ) With address x display dump   | DONE
; TODO pop address to use off of the stack
		if DEBUG_FORTH_WORDS_KEY
			DMARK "DUM"
			CALLMONITOR
		endif
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
; | CDUMP ( -- ) Continue dump of memory from DUMP | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "CDP"
			CALLMONITOR
		endif
		call clear_display
		call dumpcont	
		ret			; TODO command causes end of remaining parsing so cant do: $0000 DUMP CDUMP $8000 DUMP
		NEXTW




.DAT:
	CWHEAD .HOME 41 "AT" 2 WORD_FLAG_CODE
; | AT ( u1 u2 -- ) Set next output via . or emit at row u2 col u1 | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "AT."
			CALLMONITOR
		endif
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
	CWHEAD .CR 45 "HOME" 4 WORD_FLAG_CODE
; | HOME ( -- ) Reset the current cursor for output to home | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "HOM"
			CALLMONITOR
		endif
.home:		ld a, 0		; and home cursor
		ld (f_cursor_ptr), a
		NEXTW


.CR:
	CWHEAD .SPACE 50 "CR" 2 WORD_FLAG_CODE
; | CR (  -- s ) Push CR/LF pair onto the stack as a string  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "CR."
			CALLMONITOR
		endif
		ld a, 13
		ld (scratch),a
		ld a, 10
		ld (scratch+1),a
		ld a, 0
		ld (scratch+2),a
		ld hl, scratch
		call forth_push_str
		
	       NEXTW
.SPACE:
	CWHEAD .SPACES 50 "BL" 2 WORD_FLAG_CODE
; | BL (  -- c ) Push the value of space onto the stack as a string  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "BL."
			CALLMONITOR
		endif
		ld a, " "
		ld (scratch),a
		ld a, 0
		ld (scratch+1),a
		ld hl, scratch
		call forth_push_str
		
	       NEXTW

;.blstr: db " ", 0

.SPACES:
	CWHEAD .SCROLL 51 "SPACES" 6 WORD_FLAG_CODE
; | SPACES ( u -- str ) A string of u spaces is pushed onto the stack | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "SPS"
			CALLMONITOR
		endif


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u
		if DEBUG_FORTH_WORDS
			DMARK "SPA"
			CALLMONITOR
		endif

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		pop hl
		ld c, 0
		ld b, l
		ld hl, scratch 

		if DEBUG_FORTH_WORDS
			DMARK "SP2"
			CALLMONITOR
		endif
		ld a, ' '
.spaces1:	
		ld (hl),a
		inc hl
		
		djnz .spaces1
		ld a,0
		ld (hl),a
		ld hl, scratch
		if DEBUG_FORTH_WORDS
			DMARK "SP3"
			CALLMONITOR
		endif
		call forth_push_str

	       NEXTW



.SCROLL:
	CWHEAD .SCROLLD 63 "SCROLL" 6 WORD_FLAG_CODE
; | SCROLL ( -- ) Scroll up one line - next write will update if required | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "SCR"
			CALLMONITOR
		endif

	call scroll_up
;	call update_display

		NEXTW



;		; get dir
;
;		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
;
;		push hl
;
;		; destroy value TOS
;
;		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
;
;		; get count
;
;		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
;
;		push hl
;
;		; destroy value TOS
;
;		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
;
;		; one value on hl get other one back
;
;		pop bc    ; count
;
;		pop de   ; dir
;
;
;		ld b, c
;
;.scrolldir:     push bc
;		push de
;
;		ld a, 0
;		cp e
;		jr z, .scrollup 
;		call scroll_down
;		jr .scrollnext
;.scrollup:	call scroll_up
;
;		
;.scrollnext:
;		pop de
;		pop bc
;		djnz .scrolldir
;
;
;
;
;
;		NEXTW

.SCROLLD:
	CWHEAD .ATQ 63 "SCROLLD" 7 WORD_FLAG_CODE
; | SCROLLD ( -- ) Scroll down one line - next write will update if required | TO DO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "SCD"
			CALLMONITOR
		endif

	call scroll_down
;	call update_display

		NEXTW


.ATQ:
	CWHEAD .AUTODSP 78 "AT@" 3 WORD_FLAG_CODE
; | AT@ ( u1 u2 -- n ) Push to stack ASCII value at row u2 col u1 | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "ATA"
			CALLMONITOR
		endif


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

		; add current frame buffer address
		ld hl, (display_fb_active)
		call addatohl




		; get char frame buffer location offset in hl

		ld a,(hl)
		ld h, 0
		ld l, a

		call forth_push_numhl


		NEXTW

.AUTODSP:
	CWHEAD .MENU 79 "ADSP" 4 WORD_FLAG_CODE
; | ADSP ( u1 --  ) Enable/Disable Auto screen updates (SLOW). | DONE
; | | If off, use DRAW to refresh. Default is on. $0003 will enable direct screen writes (TODO) 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

;		pop hl

		ld a,l
		ld (cli_autodisplay), a
	       NEXTW

.MENU:
	CWHEAD .ENDDISPLAY 92 "MENU" 4 WORD_FLAG_CODE
; | MENU ( u1....ux n -- n ) Create a menu. n is the number of menu items on stack. Push number selection to TOS | DONE

;		; get number of items on the stack
;
	
		FORTH_DSP_VALUEHL
	
		if DEBUG_FORTH_WORDS_KEY
			DMARK "MNU"
			CALLMONITOR
		endif

		ld b, l	
		dec b

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		; go directly through the stack to pluck out the string pointers and build an array

;		FORTH_DSP

		; hl contains top most stack item
	
		ld de, scratch

.mbuild:

		FORTH_DSP_VALUEHL

		if DEBUG_FORTH_WORDS
			DMARK "MN3"
			CALLMONITOR
		endif
		ex de, hl
		ld (hl), e
		inc hl
		ld (hl), d
		inc hl
		ex de, hl

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		djnz .mbuild

		; done add term

		ex de, hl
		ld (hl), 0
		inc hl
		ld (hl), 0

	
		
		ld hl, scratch

		if DEBUG_FORTH_WORDS
			DMARK "MNx"
			CALLMONITOR
		endif



		ld a, 0
		call menu


		ld l, a
		ld h, 0

		if DEBUG_FORTH_WORDS
			DMARK "MNr"
			CALLMONITOR
		endif

		call forth_push_numhl




	       NEXTW


.ENDDISPLAY:

; eof
