
; main constants (used here and in firmware)


DEBUG_KEY: equ 1


tos:	equ 0ffffh
stacksize: equ 255


; memory allocation 

; keyscan table needs rows x cols buffer

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
key_held: equ keyscan_table-1	; currently held
key_held_prev: equ key_held - 1   ; previously held (to detect bounce and cycle of key if required)
key_repeat_ct: equ key_held_prev - 4 ; timers (two words)
key_fa: equ key_repeat_ct -1 ;
key_fb: equ key_fa -1 ;
key_fc: equ key_fb -1 ;
key_fd: equ key_fc -1 ;
key_face_held: equ key_fd - 1 

; input_str vars
input_ptr:  equ key_face_held - 2    ; ptr to the current cursor position of string currently being edited  on entry starting 
input_start:  equ input_ptr - 2    ; ptr to the start of string 
input_size: equ input_start -1  ; number of chars
input_cursor: equ input_size - 1 ; offset of cursor to current start of string

key_actual_pressed: equ input_cursor - 1 
key_symbol: equ key_actual_pressed - 1 
key_shift: equ key_symbol - 1 

; lcd allocation

lcd_rows: equ 4
lcd_cols: equ 20

lcd_fb_len: equ (lcd_rows*lcd_cols)+lcd_rows ; extra byte per row for 0 term

; active frame buffer
lcd_fb_active: equ  key_shift-lcd_fb_len

;; can load into de directory
cursor_col: equ lcd_fb_active-1
cursor_row: equ cursor_col-1
cursor_ptr: equ cursor_row - 1     ;  actual offset into lcd memory for row and col combo
cursor_shape: equ cursor_ptr - 1   ; char used for the current cursor 
scratch: equ cursor_shape-255

; change below to point to last memory alloc above
topusermem:  equ   scratch
baseusermem: equ 08000h
; **********************************************************************
; **  Constants
; **********************************************************************

; Constants used by this code module
kDataReg:   EQU 0xc0           ;PIO port A data register
kContReg:   EQU 0xc2           ;PIO port A control register


portbdata:  equ 0xc1    ; port b data
portbctl:   equ 0xc3    ; port b control



KEY_CR:   equ 13
KEY_TAB:  equ 9
KEY_BS: equ 8
KEY_HOME: equ 2
KEY_SHIFTLOCK: equ 4


;TODO macro to calc col and row offset into screen



hardware_init:

		call lcd_init		; lcd hardware first as some screen functions called during key_init e.g. cursor shapes

	call key_init

		
	
            LD   A, kLCD_Line2
            CALL fLCD_Pos       ;Position cursor to location in A
	ld de, bootmsg
            CALL fLCD_Str       ;Display string pointed to by DE


	call delay1s
	call delay1s
            LD   A, kLCD_Line2
            CALL fLCD_Pos       ;Position cursor to location in A
	ld de, bootmsg1
            CALL fLCD_Str       ;Display string pointed to by DE
	call delay1s
	call delay1s
	ld de, bootmsg2
            CALL fLCD_Str       ;Display string pointed to by DE
	call delay1s
	call delay1s

		ret


bootmsg:	db "z80-homebrew OS v0.1",0
bootmsg1:	db "  by Kevin Groves   ",0
bootmsg2:	db "   Firmware v0.1   ",0

; a 4x20 lcd
; cout for display, low level positioning and writing functions (TODO) for hardware abstraction
include "firmware_lcd.asm"

; must supply cin, and cin_wait for low level hardware abstraction 
; moved text_input entry points to here and leave the firmware hardware modules as abstraction layer
; test scancode
include "firmware_key_4x4.asm"


; support routines for above hardware abstraction layer

include "firmware_general.asm"        ; general support functions
include "firmware_display.asm"      ; frame buffer screen abstraction layer
include "firmware_maths.asm"     ; any odd maths stuff
include "firmware_strings.asm"   ; string handling






; eof

