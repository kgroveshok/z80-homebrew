
; main constants (used here and in firmware)

; TODO have page 0 of storage as bios

Device_A: equ 0h
Device_B: equ 040h
Device_C: equ 080h
Device_D: equ 0c0h


DEBUG_KEY: equ 0
DEBUG_KEY_MATRIX: equ 0
DEBUG_STORECF: equ 0
DEBUG_STORESE: equ 0
DEBUG_FORTH: equ 0
DEBUG_FORTH_PARSE: equ 0
DEBUG_FORTH_JP: equ 0
DEBUG_FORTH_PUSH: equ 0
DEBUG_FORTH_MALLOC: equ 0
DEBUG_FORTH_DOT: equ 0

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

; debug marker - optional display of debug point on the debug screens

debug_mark: equ key_face_held - 2

; input_str vars
input_ptr:  equ debug_mark - 2    ; ptr to the current cursor position of string currently being edited  on entry starting 
input_start:  equ input_ptr - 2    ; ptr to the start of string 
input_size: equ input_start -1  ; number of chars
input_at_pos: equ input_size - 1 ; frame buffer offset for start of input
input_cursor: equ input_at_pos - 1 ; offset of cursor to current start of string

key_actual_pressed: equ input_cursor - 1 
key_symbol: equ key_actual_pressed - 1 
key_shift: equ key_symbol - 1 

; Display allocation

display_rows: equ 4
display_cols: equ 20

display_fb_len: equ display_rows*display_cols

; primary frame buffer
display_fb0: equ  key_shift-display_fb_len-display_fb_len
; working frame buffers
display_fb1: equ  display_fb0-display_fb_len-display_fb_len
display_fb2: equ  display_fb1-display_fb_len
;
; pointer to active frame buffer
display_fb_active: equ display_fb2 - 2
display_write_tmp: equ display_fb_active - 2


;

;; can load into de directory
cursor_col: equ display_write_tmp-1
cursor_row: equ cursor_col-1
cursor_ptr: equ cursor_row - 1     ;  actual offset into lcd memory for row and col combo
cursor_shape: equ cursor_ptr - 1   ; char used for the current cursor 

; cf storage vars

iErrorNum:  equ cursor_shape-1         ;Error number
iErrorReg:  equ iErrorNum -1              ;Error register
iErrorVer:  equ iErrorReg - 1              ;Verify error flag

store_bank_active: equ iErrorVer - (5 + 8 ) 		; indicator of which storage banks are available to use 5 on board and 8 in cart
store_page: equ store_bank_active-128            ; page size for eeprom
;
; spi vars
; 

spi_portbyte: equ store_page - 1      ; holds bit mask to send to spi bus

;;;;; forth cli params

; TODO use a different frame buffer for forth???

f_cursor_ptr:  equ spi_portbyte - 1  ; offset into frame buffer for any . or EMIT output
cli_buffer: equ f_cursor_ptr - 20     ; temp hold - maybe not needed
cli_origtoken: equ cli_buffer - 2     ; pointer to the text of token for this word being checked
cli_token: equ cli_origtoken - 2     ; pointer to the text of token for this word being checked
cli_execword: equ cli_token - 2      ; pointer to start of code for this word
cli_nextword: equ cli_execword - 2      ; pointer to start of next word in dict
cli_ptr: equ cli_nextword - 2           ; pointer to start of word to parse by forth kernel (working)
cli_origptr: equ cli_ptr - 2           ; pointer to start of word to parse which resets cli_ptr on each word test

cli_var_array: equ cli_origptr - ( 10 * 2 ) ; word or string pointer variables using @0-@9
cli_ret_sp: equ cli_var_array - 2    ; ret stack pointer
cli_data_sp: equ cli_ret_sp - 2   ; data stack pointer
cli_ret_stack: equ cli_data_sp - 128      ; TODO could I just use normal stack for this? - use linked list for looping
cli_data_stack: equ cli_ret_stack - 512		 ; 


; with data stack could see memory filled with junk. need some memory management 
; malloc and free entry points added

free_list:  equ cli_data_stack - 4     ; Block struct for start of free list (MUST be 4 bytes)
heap_size: equ  2048      ; Number of bytes available in heap
heap_start: equ free_list - heap_size  ; Starting address of heap

;;;;

os_last_cmd: equ heap_start-30
os_cur_ptr: equ os_last_cmd-2
os_word_scratch: equ os_cur_ptr-30

scratch: equ os_word_scratch-255

; change below to point to last memory alloc above
topusermem:  equ   scratch
baseusermem: equ 08000h
; **********************************************************************
; **  Constants
; **********************************************************************

; Constants used by this code module
kDataReg:   EQU Device_D           ;PIO port A data register
kContReg:   EQU Device_D+2           ;PIO port A control register


portbdata:  equ Device_D+1    ; port b data
portbctl:   equ Device_D+3    ; port b control



KEY_CR:   equ 13
KEY_TAB:  equ 9
KEY_BS: equ 8
KEY_HOME: equ 2
KEY_SHIFTLOCK: equ 4


;TODO macro to calc col and row offset into screen



hardware_init:

		; init primary frame buffer area
		ld hl, display_fb0
		ld (display_fb_active), hl

		call clear_display


		call lcd_init		; lcd hardware first as some screen functions called during key_init e.g. cursor shapes

	call key_init
	call storage_init

	; setup malloc functions

	call  heap_init

	; lcd test sequence
		
	call update_display
	call delay1s
	ld a,'+'
	call fill_display
	call update_display
	call delay1s
	ld a,'*'
	call fill_display
	call update_display
	call delay1s
	ld a,'-'
	call fill_display
	call update_display
	call delay1s

; boot splash screen
	
            ld a, display_row_1
	ld de, bootmsg
	call str_at_display
	call update_display


	call delay1s
	call delay1s
            LD   A, display_row_3+2
	ld de, bootmsg1
	call str_at_display
	call update_display
	call delay1s
	call delay1s

;	ld a, display_row_4+3
;	ld de, bootmsg2
;	call str_at_display
;	call update_display
;	call delay1s
;	call delay1s

; debug mark setup

ld a, 'a'
ld (debug_mark),a
ld a,0
ld (debug_mark+1),a

		ret


bootmsg:	db "z80-homebrew OS v0.5",0
bootmsg1:	db "by Kevin Groves",0
;bootmsg2:	db "Firmware v0.1",0

; a 4x20 lcd
; cout for display, low level positioning and writing functions (TODO) for hardware abstraction
include "firmware_lcd.asm"
;
; TODO use the low spare two pins on port a of display pio to bit bang a serial out video display to an esp
; TODO abstract the bit bang video out interface for dual display
; TODO wire video out to tx pin on rc2014 bus

; must supply cin, and cin_wait for low level hardware abstraction 
; moved text_input entry points to here and leave the firmware hardware modules as abstraction layer
; test scancode
include "firmware_key_4x4.asm"

; storage hardware interface

; use microchip serial eeprom for storage
include "firmware_spi.asm"
include "firmware_seeprom.asm"

; use cf card for storage - throwing timeout errors. Hardware or software?????
;include "firmware_cf.asm"

; load up high level storage hardward abstractions
include "firmware_storage.asm"

; support routines for above hardware abstraction layer

include "firmware_general.asm"        ; general support functions
include "firmware_display.asm"      ; frame buffer screen abstraction layer
;include "firmware_maths.asm"     ; any odd maths stuff   TODO removed until I fix up the rng code
include "firmware_strings.asm"   ; string handling
include "firmware_memory.asm"   ; malloc and free






; eof

