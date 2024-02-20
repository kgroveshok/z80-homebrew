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
keyscan_table: equ  tos-stacksize-(key_rows*key_cols)
keyscan_table_len: equ key_rows*key_cols
keybufptr: equ keyscan_table - 2
keysymbol: equ keybufptr - 1
keyshift: equ keysymbol - 1


key_scanr: equ key_row_bitmask
key_scanc: equ key_col_bitmask

key_char_map: equ key_map
key_face_map: equ key_map_face

; lcd allocation

lcd_rows: equ 4
lcd_cols: equ 20

lcd_fb_len: equ (lcd_rows*lcd_cols)+lcd_rows ; extra byte per row for 0 term

lcd_fb_active: equ  keyshift-lcd_fb_len
; can load into de directory
cursor_col: equ lcd_fb_active-1
cursor_row: equ cursor_col-1


; change below to point to last memory alloc above
topusermem:  equ   0f000h


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


; bit mask for each scan column and row for testing the matrix

; out 
key_row_bitmask:    db 128, 64, 32, 16
; in
key_col_bitmask:    db 1, 2, 4, 8

; row/col to character map

; char, state use   123xxsss   - bit 8,7,6 this key selects specified state, s is this key is member of that state
;  

; physical key matrix map to face of key

key_map_face: 
		db '1'
		db '2'
		db '3'
		db 'A'

		db '4'
		db '5'
		db '6'
		db 'B'

		db '7'
		db '8'
		db '9'
		db 'C'

		db '*'
		db '0'
		db '#'
		db 'D'

; map the physical key to a char dependant on state

key_map: 
		db '1',000000000b
		db '2',000000000b
		db '3',000000000b
		db 'A',000000000b

		db '4',000000000b
		db '5',000000000b
		db '6',000000000b
		db 'B',000000000b
		db '7',000000000b
		db '8',000000000b
		db '9',000000000b
		db 'C',000000000b
		db '*',010000000b
		db '0',000000000b
		db '#',000000000b
		db 'D',000000000b

		db 0,000000000b


		db 'a',000000010b
		db 'b',000000010b
		db 'c',000000010b
		db 'd',000000010b
		db 'e',000000010b
		db 'f',000000010b
		db 'g',000000010b
		db 'h',000000010b
		db 'i',000000010b
		db 'j',000000010b
		db 'k',000000010b
		db 'l',000000010b
		db '*',010000010b
		db 'm',000000010b
		db '#',00000100b
		db 'n',000000010b


bootmsg:	db "z80-homebrew OS v0.1",0
bootmsg1:	db "by Kevin Groves",0


; start system

coldstart:
	; set sp
	; di/ei

	di
	ld sp, tos
;	ei

	; init hardware

	; init keyboard and screen hardware

	call keylcd_init

	



	;call clear_display

	
            LD   A, kLCD_Line2
            CALL fLCD_Pos       ;Position cursor to location in A
	ld de, bootmsg
            CALL fLCD_Str       ;Display string pointed to by DE

stop:	nop
	jp stop

	call delay1s
	call delay1s
            LD   A, kLCD_Line2
            CALL fLCD_Pos       ;Position cursor to location in A
	ld de, bootmsg
            CALL fLCD_Str       ;Display string pointed to by DE
	call delay1s
	call delay1s

	ld de, bootmsg
	ld hl,lcd_fb_active
	call strcpy

	ld d, 1
	ld e, 0

main:
	call update_display

cloop:	call cin
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


