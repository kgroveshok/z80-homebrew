; z80 homebrew opperating system
;
;



; bios jump points via rst


	org 0h

	jp coldstart     ; rst 0 - cold boot

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
;	;jp 		; rst 01bh
;
;
;	org 020h
;
;	; jp		 ; rst 020h
;
;	org 028h

	; jp		 ; rst 028h

;$08, $10, $18, $20, $28, $30 or $38

str1: db "Enter some text:",0

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

	



	;call clear_display


;	ld de, bootmsg
;	ld hl,lcd_fb_active
;	call strcpy
;
;	ld d, 1
;	ld e, 0

;stop:	nop
;	jp stop


main:
;	call update_display

	; init scratch input area for testing
	ld hl, scratch	
	ld a,0
	ld (hl),a

            LD   A, kLCD_Line2
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, str1
            CALL fLCD_Str       ;Display string pointed to by DE
cloop:	
;call cin

;	ld hl,lcd_fb_active
;	ld (hl),a
;	call delay250ms

;	call cin
	ld bc, 0
	ld d, 10
	ld hl, scratch	
	call input_str

;	cp 0
;	jr z, cloop
	; we have a key press what is it?

;	ld hl,scratch
;	ld (hl),a
;	inc hl
;	ld a,0
;	ld (hl),a


 ;           LD   A, kLCD_Line1
 ;           CALL fLCD_Pos       ;Position cursor to location in A
 ;           LD   DE, scratch
 ;           CALL fLCD_Str       ;Display string pointed to by DE

	nop
	jp cloop


;	cp 0
;	jr z, cloop
;
;	cp '#'
;	jr z, backspace
;
;	call curptr
;	ld (hl),a
;	inc e
;	
;
;	jp main
;
;
;backspace:
;	jp main




; eof

