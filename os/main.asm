; z80 homebrew opperating system
;

STARTUP_ENABLE: equ 1


; bios jump points via rst

if BASE_SC114 = 1 

	org 8000h
endif

if BASE_KEV = 1 

	org 0h
endif

if BASE_CPM = 1 

	org 100h
endif
	jp coldstart     ; rst 0 - cold boot


buildtime: db   "Build: 00/00/00 00:00:00",0


;        nop 
;        nop
;;	org 05h		; null out bdos call
;
;        nop 
;        nop 
;        nop
;;	org 08h
;;;
;;	jp cin		; rst 8 - char in
;;;
;
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop
;	org 010h
;;
;	jp cout		; rest 010h  - char out
;;
;	org 01bh  
;
;	;jp  		; rst 01bh   - write string to display
;	jp str_at_display
;
;
;	org 020h
;
;	; jp		 ; rst 020h - read char at screen location
;
;	org 028h

	; jp		 ; rst 028h  - storage i/o

; 	org 030h
;	jp break_point_state
 
; $30 
; org 038h
; $38

; TODO any more important entry points to add to jump table for easier coding use?


include "firmware.asm"

;; below moved from firmware.asm for strange zero calc of baseusermem label. Scope issue on multipass????
;if BASE_KEV 
;baseram: equ 08000h
;endif

;if BASE_SC114
;baseram:     equ    endofcode
;endif


; Add NMI support. A rst 066h when r15z goes neg on clock side of resist. needs to do retn when exiting

; start system

coldstart:
	; set sp
	; di/ei

	di
	ld sp, tos
;	ei

	; init spinner
	ld a,0
	ld (display_active), a

	; disable breakpoint by default

	;ld a,'*'
;	ld a,' '
;	ld (os_view_disable),a

	; set break point vector as new break point on or off
	call bp_off

	; init hardware

	; init keyboard and screen hardware

	call hardware_init


	call delay1s
	ld a, display_row_3+8
	ld de, buildtime
	call str_at_display
	call update_display

	call delay1s
	call delay1s
	call delay1s

	; detect if any keys are held down to enable breakpoints at start up

	call cin 
	cp 0
	jr z, .nokeys

	;call hardware_diags
	call config

;	ld de, .bpen
;	ld a, display_row_4
;	call str_at_display
;	call update_display
;
;	ld a,0
;	ld (os_view_disable),a
;
;.bpwait:
;	call cin
;	cp 0
;	jr z, .bpwait
;	jr .nokeys
;
;
;.bpen:  db "Break points enabled!",0






.nokeys:


	

;jp  testkey

;call storage_get_block_0
;
;ld hl, 0
;ld de, store_page
;call storage_read_block

	
;ld hl, 10
;ld de, store_page
;call storage_read_block





;stop:	nop
;	jp stop



main:
	call clear_display
	call update_display



;	call testlcd



	call forth_init


warmstart:
	call forth_warmstart

	; run startup word load
        ; TODO prevent this running at warmstart after crash 

	if STARTUP_ENABLE

		if STARTUP_V1

			if STORAGE_SE
				call forth_autoload
			endif
			call forth_startup
		endif

		if STARTUP_V2

			if STORAGE_SE
				call forth_autoload
			else
				call forth_startup
			endif


		endif

	endif

	; show free memory after boot
	ld de, freeram
	ld a, display_row_1
	call str_at_display

; Or use heap_size word????
	ld hl, heap_end
	ld de, heap_start
	sbc hl, de
	push hl
	ld a,h	         	
	ld hl, os_word_scratch		; TODO do direct write to frame buffer instead and drop the str_at_display
	call hexout
   	pop hl

	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a, 0
	ld (hl),a
	ld de, os_word_scratch
	ld a, display_row_1 + 13
	call str_at_display
	call update_display


	;call demo


	; init scratch input area for cli commands

	ld hl, os_cli_cmd
	ld a,0
	ld (hl),a
	inc hl
	ld (hl),a

	ld a,0
	ld (os_last_cmd),a	; current command in use to enable repeated use with an enter etc

	ld (os_cur_ptr),a	; ptr to whatever is needed for this command
	ld (os_cur_ptr+1),a	

	ld (os_word_scratch),a	; byte or word being used in parsing for this command
	ld (os_word_scratch+1),a	
	

	;ld a, kLCD_Line2        ; TODO prompt using direct screen line address. Correct this to frame buffer
	ld hl, os_cli_cmd

	ld a, 0		 ; init cli input
	ld (hl), a
	ld a, display_row_2        ; TODO prompt using direct screen line address. Correct this to frame buffer
cli:
	; show cli prompt
	;push af
	;ld a, 0
	;ld de, prompt
	;call str_at_display

	;call update_display
	;pop af
	;inc a
	;ld a, kLCD_Line4+1	 ; TODO using direct screen line writes. Correct this to frame buffer
	ld c, 0
	ld d, 255    ; TODO fix input_str to actually take note of max string input length
	ld e, 40

	ld hl, os_cli_cmd

	STACKFRAME OFF $fefe $9f9f

	call input_str

	STACKFRAMECHK OFF $fefe $9f9f

	; copy input to last command

	ld hl, os_cli_cmd
	ld de, os_last_cmd
	ld bc, 255
	ldir

	; wipe current buffer

;	ld a, 0
;	ld hl, os_cli_cmd
;	ld de, os_cli_cmd+1
;	ld bc, 254
;	ldir
	; TODO ldir is not working strcpy may not get all the terms on the input line????
;	call strcpy
;	ld a, 0
;	ld (hl), a
;	inc hl
;	ld (hl), a
;	inc hl
;	ld (hl), a

	; switch frame buffer to program 

		ld hl, display_fb1
		ld (display_fb_active), hl

;	nop
	STACKFRAME ON $fbfe $8f9f
	; first time into the parser so pass over the current scratch pad
	ld hl,os_cli_cmd
	; tokenise the entered statement(s) in HL
	call forthparse
        ; exec forth statements in top of return stack
	call forthexec
	;call forthexec_cleanup
;	call parsenext

	STACKFRAMECHK ON $fbfe $8f9f
	; TODO on return from forth parsing should there be a prompt to return to system? but already in system.

	ld a, display_row_4
	ld de, endprog

	call update_display		

	call next_page_prompt

	; switch frame buffer to cli

		ld hl, display_fb0
		ld (display_fb_active), hl


        call clear_display
	call update_display		

	ld hl, os_cli_cmd

	ld a, 0		 ; init cli input
	ld (hl), a

	; TODO f_cursor_ptr should inc row (scroll if required) and set start of row for next input 

	; now on last line

	; TODO scroll screen up

	; TODO instead just clear screen and place at top of screen

;	ld a, 0
;	ld (f_cursor_ptr),a

	;call clear_display
	;call update_display

	;ld a, kLCD_Line1        ; TODO prompt using direct screen line address. Correct this to frame buffer
	ld a, display_row_1        ; TODO prompt using direct screen line address. Correct this to frame buffer
	jp cli

freeram: db "Free bytes: $",0
asc: db "1A2F"
endprog: db "End prog...",0

testenter2:  
	ld hl,scratch+50
	ld (os_cur_ptr),hl
	jp cli

testenter: 

	ld hl,asc
;	ld a,(hl)
;	call nibble2val
	call get_byte


;	ld a,(hl)
;	call atohex

;	call fourehexhl
	ld (scratch+50),a



	ld hl,asc+2
;	ld a, (hl)
;	call nibble2val
	call get_byte

;	call fourehexhl
	ld (scratch+52),a
	
	ld hl,scratch+50
	ld (os_cur_ptr),hl
	jp cli

enter:	
	ld a,(scratch+4)
	cp 0
	jr z, .entercont
	; no, not a null term line so has an address to work out....

	ld hl,scratch+2
	call get_word_hl

	ld (os_cur_ptr),hl	
	jp cli


.entercont: 

	ld hl, scratch+2
	call get_byte

   	ld hl,(os_cur_ptr)
		ld (hl),a
		inc hl
		ld (os_cur_ptr),hl
	
; get byte 


	jp cli


; basic monitor support

monitor:
	; 
	call clear_display
	ld a, 0
	ld de, .monprompt
	call str_at_display
	call update_display

	; get a monitor command

	ld c, 0     ; entry at top left
	ld d, 100   ; max buffer size
	ld e, 15    ; input scroll area
	ld a, 0     ; init string
	ld hl, os_input
	ld (hl), a
	inc hl
	ld (hl), a
	ld hl, os_input
	ld a, 1     ; init string
	call input_str

        call clear_display
	call update_display		

	ld a, (os_input)
	call toUpper
        cp 'H'
        jp z, .monhelp
	cp 'D'		; dump
	jp z, .mondump	
	cp 'C'		; dump
	jp z, .moncdump	
	cp 'M'		; dump
	jp z, .moneditstart
	cp 'U'		; dump
	jp z, .monedit	
	cp 'G'		; dump
	jp z, .monjump
	cp 'Q'		; dump
	ret z	


	; TODO "S" to access symbol by name and not need the address
	; TODO "F" to find a string in memory

	jp monitor

.monprompt: db ">", 0

.moneditstart:
	; get starting address

	ld hl,os_input+2
	call get_word_hl

	ld (os_cur_ptr),hl	

	jp monitor

.monedit:
	; get byte to load

	ld hl,os_input+2
	call get_byte

	; get address to update
	ld hl, (os_cur_ptr)

	; update byte

	ld (hl), a

	; move to next address and save it

	inc hl
	ld (os_cur_ptr),hl	

	jp monitor


.monhelptext1: 	db "D-Dump, C-Cont Dump",0
.monhelptext2:  db "M-Edit Start, U-Update Byte",0
.monhelptext3:  db "G-Call address",0
.monhelptext4:  db "Q-Quit",0
       
.monhelp:
	ld a, display_row_1
        ld de, .monhelptext1

	call str_at_display
	ld a, display_row_2
        ld de, .monhelptext2
		
	call str_at_display
	ld a, display_row_3
        ld de, .monhelptext3
		
	call str_at_display
	ld a, display_row_4
        ld de, .monhelptext4
	call str_at_display

	call update_display		

	call next_page_prompt
	jp monitor

.monjump:   
	ld hl,os_input+2
	call get_word_hl

	jp (hl)
	jp monitor

.mondump:   
	ld hl,os_input+2
	call get_word_hl

	ld (os_cur_ptr),hl	
	call dumpcont
	ld a, display_row_4
	ld de, endprog

	call update_display		

	call next_page_prompt
	jp monitor
.moncdump:
	call dumpcont
	ld a, display_row_4
	ld de, endprog

	call update_display		

	call next_page_prompt
	jp monitor


; TODO symbol access 

.symbols:     ;; A list of symbols that can be called up 
	dw display_fb0
	db "fb0",0 
     	dw store_page
	db "store_page",0


dump:	; see if we are cotinuing on from the last command by not uncluding any address

	ld a,(scratch+1)
	cp 0
	jr z, dumpcont

	; no, not a null term line so has an address to work out....

	ld hl,scratch+2
	call get_word_hl

	ld (os_cur_ptr),hl	



dumpcont:

	; dump bytes at ptr


	ld a, display_row_1
	ld hl, (display_fb_active)
	call addatohl
	call .dumpbyterow

	ld a, display_row_2
	ld hl, (display_fb_active)
	call addatohl
	call .dumpbyterow


	ld a, display_row_3
	ld hl, (display_fb_active)
	call addatohl
	call .dumpbyterow

	ld a, display_row_4
	ld hl, (display_fb_active)
	call addatohl
	call .dumpbyterow

	call update_display
;		jp cli
	ret

.dumpbyterow:

	;push af

	push hl

	; calc where to poke the ascii
if display_cols == 20
	ld a, 16
else
	ld a, 31
endif

	call addatohl
	ld (os_word_scratch),hl  		; save pos for later


; display decoding address
   	ld hl,(os_cur_ptr)

	ld a,h
	pop hl
	push hl
;	ld hl, os_word_scratch		; TODO do direct write to frame buffer instead and drop the str_at_display
	call hexout
   	ld hl,(os_cur_ptr)

	ld a,l
	pop hl
	inc hl
	inc hl
	push hl
;	ld hl, os_word_scratch+2
	call hexout
	pop hl
	inc hl
	inc hl
	;ld hl, os_word_scratch+4
	ld a, ':'
	ld (hl),a
	inc hl
	;ld a, 0
	;ld (hl),a
	;ld de, os_word_scratch
	;pop af
	;push af
;		ld a, display_row_2
;		call str_at_display
;		call update_display


;pop af
;	add 5

if display_cols == 20
	ld b, 4
else
	ld b, 8
endif	

.dumpbyte:
	push bc
	push hl


   	ld hl,(os_cur_ptr)
		ld a,(hl)

		; poke the ascii to display
		ld hl,(os_word_scratch)
		ld (hl),a
		inc hl
		ld (os_word_scratch),hl

		


		pop hl
		push hl

		call hexout

		
   	ld hl,(os_cur_ptr)
	inc hl
   	ld (os_cur_ptr),hl

		pop hl
		inc hl
		inc hl
		inc hl



		;ld a,0
		;ld (os_word_scratch+2),a
		;pop af
		;push af

		;ld de, os_word_scratch
		;call str_at_display
;		call update_display
;		pop af
		pop bc
		add 3
	djnz .dumpbyte

	

	ret

jump:	

	ld hl,scratch+2
	call get_word_hl
	;ld hl,(scratch+2)
	;call fourehexhl

	ld (os_cur_ptr),hl	

	jp (hl)



; TODO implement a basic monitor mode to start with









; testing and demo code during development


str1: db "Enter some text...",0
clear: db "                    ",0

demo:



;	call update_display

	; init scratch input area for testing
	ld hl, scratch	
	ld a,0
	ld (hl),a


            LD   A, display_row_2
;            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, str1
	call str_at_display

;            CALL fLCD_Str       ;Display string pointed to by DE
cloop:	
            LD   A, display_row_3
;            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, clear
 ;           CALL fLCD_Str       ;Display string pointed to by DE
		call str_at_display
	ld a, display_row_4
	ld de, prompt

		call str_at_display
	call update_display

	ld a, kLCD_Line4+1	 ; TODO using direct screen line writes. Correct this to frame buffer
	ld d, 10
	ld hl, scratch	
	call input_str

;	call clear_display
;'	call update_display

            LD   A, display_row_1
;            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, clear
		call str_at_display
;            CALL fLCD_Str       ;Display string pointed to by DE
            LD   A, display_row_1
;            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, scratch
;            CALL fLCD_Str       ;Display string pointed to by DE
		call str_at_display
	call update_display

		ld a,0
	ld hl, scratch
	ld (hl),a

	nop
	jp cloop



; OS Prompt

prompt: db ">",0
endprg: db "?",0


; handy next page prompt
next_page_prompt:
	push hl
	push de
	push af
	push bc

	ld a,display_row_4 + display_cols - 1
        ld de, endprg
	call str_at_display
	call update_display
	call cin_wait
	pop bc
	pop af
	pop de
	pop hl


	ret


; forth parser

; My forth kernel
include "forth_kernel.asm"
;include "nascombasic.asm"


; find out where the code ends if loaded into RAM (for SC114)
;endofcode: 
;	nop


; eof

