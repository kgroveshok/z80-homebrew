; z80 homebrew opperating system
;
;

; main constants (used here and in firmware)



tos:	equ 0ffffh
stacksize: equ 128

; keyscan table needs rows x cols buffer

; memory allocation 
key_rows: equ 4
key_cols: equ 4
keyscan_table_row1: equ tos-stacksize-key_cols-1
keyscan_table_row2: equ keyscan_table_row1-key_cols-1
keyscan_table_row3: equ keyscan_table_row2-key_cols-1
keyscan_table_row4: equ keyscan_table_row3-key_cols-1
keyscan_table: equ keyscan_table_row4-(key_cols*key_rows)-1
;keyscan_table_len: equ key_rows*key_cols
;keybufptr: equ keyscan_table - 2
;keysymbol: equ keybufptr - 1
keyshift: equ keyscan_table_row4


;key_scanr: equ key_row_bitmask
;key_scanc: equ key_col_bitmask

;key_char_map: equ key_map
;key_face_map: equ key_map_face

; lcd allocation

lcd_rows: equ 4
lcd_cols: equ 20

lcd_fb_len: equ (lcd_rows*lcd_cols)+lcd_rows ; extra byte per row for 0 term

lcd_fb_active: equ  keyshift-lcd_fb_len
;; can load into de directory
cursor_col: equ lcd_fb_active-1
cursor_row: equ cursor_col-1


scratch: equ cursor_row-255

; change below to point to last memory alloc above
topusermem:  equ   scratch


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

cloop:	
;call cin

;	ld hl,lcd_fb_active
;	ld (hl),a
;	call delay250ms

	call cin

	cp 0
	jr z, cloop
	; we have a key press what is it?

	ld hl,scratch
	ld (hl),a
	inc hl
	ld a,0
	ld (hl),a


            LD   A, kLCD_Line1
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, scratch
            CALL fLCD_Str       ;Display string pointed to by DE

	nop
	jp main


	cp 0
	jr z, cloop

	cp '#'
	jr z, backspace

	call curptr
	ld (hl),a
	inc e
	

	jp main


backspace:
	jp main




include "firmware.asm"


