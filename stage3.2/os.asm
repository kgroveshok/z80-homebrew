; z80 homebrew opperating system
;
;



; bios jump points via rst


	org 0h

	jp coldstart     ; rst 0 - cold boot

;	org 05h		; null out bdos call
;	ret

;	org 08h
;
;	jp cin		; rst 8 - char in
;
;	org 010h
;
;	jp cout		; rest 010h  - char out
;
;	org 01bh  
;
;	;jp  		; rst 01bh   - write string to display
;
;
;	org 020h
;
;	; jp		 ; rst 020h - read char at screen location
;
;	org 028h

	; jp		 ; rst 028h  - storage i/o

; org 030h
; $30 
; org 038h
; $38

; TODO any more important entry points to add to jump table for easier coding use?


include "firmware.asm"

; start system

coldstart:
	; set sp
	; di/ei

	di
	ld sp, tos
;	ei

	; init hardware

	; init keyboard and screen hardware

	call hardware_init

	



;stop:	nop
;	jp stop


os_last_cmd: equ scratch+30
os_cur_ptr: equ scratch+33
os_word_scratch: equ scratch+38

main:
	call clear_display
	call update_display

	;call demo


	; init scratch input area for cli commands

	ld hl, scratch	
	ld a,0
	ld (hl),a

	ld a,0
	ld (os_last_cmd),a	; current command in use to enable repeated use with an enter etc

	ld (os_cur_ptr),a	; ptr to whatever is needed for this command
	ld (os_cur_ptr+1),a	

	ld (os_word_scratch),a	; byte or word being used in parsing for this command
	ld (os_word_scratch+1),a	
	

cli:
	; show cli prompt

	ld a, display_row_4
	ld de, prompt
	call str_at_display

	call update_display

	ld a, kLCD_Line4+1	 ; TODO using direct screen line writes. Correct this to frame buffer
	ld d, 10
	ld hl, scratch	
	call input_str


	; look for monitor commands

	ld a,(scratch)
	cp 'd'
	jp z, dump			; d xxxx    dump 4 bytes. repeated pressing of enter dumps another row and scrolls
	cp 'g'
	jp z,jump			; j xxxx     jump and run code at xxxx
	cp 'e'
	jp z,enter                ; e xxxx     start entering of single bytes storing at address until empty string
	cp 't'
	jp z,testenter                ; e xxxx     start entering of single bytes storing at address until empty string
	cp 'j'
	jp z,testenter2                ; e xxxx     start entering of single bytes storing at address until empty string


	nop
	jp cli


asc: db "1A2F"

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


dump:	; see if we are cotinuing on from the last command by not uncluding any address

	ld a,(scratch+1)
	cp 0
	jr z, .dumpcont

	; no, not a null term line so has an address to work out....

	ld hl,scratch+2
	call get_word_hl

	ld (os_cur_ptr),hl	



.dumpcont:


	; dump bytes at ptr

	ld a, display_row_1
	call .dumpbyterow

	ld a, display_row_2
	call .dumpbyterow


	ld a, display_row_3
	call .dumpbyterow

		jp cli

.dumpbyterow:

	push af

; display decoding address
   	ld hl,(os_cur_ptr)

	ld a,h
	ld hl, os_word_scratch		; TODO do direct write to frame buffer instead and drop the str_at_display
	call hexout
   	ld hl,(os_cur_ptr)

	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a, ':'
	ld (hl),a
	inc hl
	ld a, 0
	ld (hl),a
	ld de, os_word_scratch
	pop af
	push af
;		ld a, display_row_2
		call str_at_display
		call update_display


pop af
	add 5

	ld b, 5

.dumpbyte:
	push bc
	push af
   	ld hl,(os_cur_ptr)
		ld a,(hl)
		inc hl
		ld (os_cur_ptr),hl

		ld hl, os_word_scratch

		call hexout

		ld a,0
		ld (os_word_scratch+2),a
		pop af
		push af

		ld de, os_word_scratch
		call str_at_display
		call update_display
		pop af
		pop bc
		add 3
	djnz .dumpbyte

	

	ret

jump:	

	ld hl,(scratch+2)
	call fourehexhl

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


; eof

