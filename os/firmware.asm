
; main constants (used here and in firmware)

; TODO have page 0 of storage as bios

Device_A: equ 0h
Device_B: equ 040h
Device_C: equ 080h
Device_D: equ 0c0h


DEBUG_INPUT: equ 0     ; Debug input entry code
DEBUG_KEYCINWAIT: equ 0
DEBUG_KEYCIN: equ 0
DEBUG_KEY: equ 0
DEBUG_KEY_MATRIX: equ 0
DEBUG_STORECF: equ 0
DEBUG_STORESE: equ 1        ; TODO  w locks up, r returns. 
DEBUG_FORTH_PARSE_EXEC: equ 1     ; 6
DEBUG_FORTH_PARSE_EXEC_SLOW: equ 0     ; 6
DEBUG_FORTH_PARSE_NEXTWORD: equ 0
DEBUG_FORTH_JP: equ 0
DEBUG_FORTH_MALLOC: equ 0
DEBUG_FORTH_DOT: equ 0
DEBUG_FORTH_DOT_KEY: equ 0
DEBUG_FORTH_MALLOC_GUARD: equ 1
DEBUG_FORTH_MATHS: equ 1


DEBUG_FORTH_PARSE_KEY: equ 1   ; 5
DEBUG_FORTH_TOK: equ 1     ; 4
DEBUG_FORTH_PARSE: equ 1    ; 3
DEBUG_FORTH: equ 1  ;2
DEBUG_FORTH_WORDS: equ 1   ; 1
DEBUG_FORTH_PUSH: equ 1   ; 1
DEBUG_FORTH_UWORD: equ 1   ; 1

FORTH_ENABLE_FREE: equ 1
FORTH_ENABLE_FLOATMATH: equ 0

CALLMONITOR: macro
	call break_point_state
	endm

MALLOC_1: equ 1
MALLOC_2: equ 0


tos:	equ 0ffffh
stacksize: equ 512

if STORAGE_SE == 0
	STORE_BLOCK_PHY:   equ 64    ; physical block size on storage   64byte on 256k eeprom
	STORE_DEVICE_MAXBLOCKS:  equ  512 ; how many blocks are there on this storage device
endif

; memory allocation 

; keyscan table needs rows x cols buffer

key_rows: equ 5     ; TODO move out to mini and maxi + 1 null
key_cols: equ 10    ; TODO move out to mini and maxi + 1 null
keyscan_table_row1: equ tos-stacksize-key_cols-1
keyscan_table_row2: equ keyscan_table_row1-key_cols-1
keyscan_table_row3: equ keyscan_table_row2-key_cols-1
keyscan_table_row4: equ keyscan_table_row3-key_cols-1
keyscan_table_row5: equ keyscan_table_row4-key_cols-1
keyscan_table: equ keyscan_table_row5-(key_cols*key_rows)-1
keyscan_scancol: equ keyscan_table-key_cols
;keyscan_table_len: equ key_rows*key_cols
;keybufptr: equ keyscan_table - 2
;keysymbol: equ keybufptr - 1
key_held: equ keyscan_scancol-1	; currently held
key_held_prev: equ key_held - 1   ; previously held (to detect bounce and cycle of key if required)
key_repeat_ct: equ key_held_prev - 4 ; timers (two words)
key_fa: equ key_repeat_ct -1 ;
key_fb: equ key_fa -1 ;
key_fc: equ key_fb -1 ;
key_fd: equ key_fc -1 ;
key_face_held: equ key_fd - 1 

; hardware config switches
; TODO add bitmasks on includes for hardware
; high byte for expansion ids
;     0000 0000  no card inserted
;     0000 0001  storage card inserted
;     0000 0010  spi sd card active

;     
; low byte:
;     0000 0001   4x4 keypad
;     0000 0010   full keyboard
;     0000 0011   spi/ext keyboard
;     0000 0100   20x4 lcd
;     0000 1000   40x4 lcd
;     0000 1100   spi/ext display
;     0001 0000   ide interface available

hardware_word: equ key_face_held - 2

; debug marker - optional display of debug point on the debug screens

debug_mark: equ hardware_word - 2

; input_str vars
input_ptr:  equ debug_mark - 2    ; ptr to the current cursor position of string currently being edited  on entry starting 
input_start:  equ input_ptr - 2    ; ptr to the start of string 
input_size: equ input_start -1  ; number of chars
input_display_size: equ input_size -1  ; TODO number of chars that are displayable. if < input_size then scroll 
input_at_pos: equ input_display_size - 1 ; frame buffer offset for start of input
input_under_cursor: equ input_at_pos - 1 ; char under the cursor so we can blink it
input_at_cursor: equ input_under_cursor - 1 ; offset of cursor to current start of string
input_cur_flash: equ input_at_cursor - 2 ;  timeout for cursor flash
input_cur_onoff: equ input_cur_flash - 1 ;  cursor blink on or off
input_len: equ input_cur_onoff - 5 ; length of current input
input_cursor: equ input_len - 5 ; offset of cursor to current start of string

CUR_BLINK_RATE: equ 15

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
cursor_shape: equ cursor_ptr - 2   ; char used for the current cursor 

; maths vars

LFSRSeed: equ cursor_shape -20 
randData: equ LFSRSeed - 2
xrandc: equ randData - 2
stackstore: equ xrandc - 2
seed1: equ  stackstore -2 
seed2: equ seed1 - 2

; cf storage vars

iErrorNum:  equ seed2-1         ;Error number
iErrorReg:  equ iErrorNum -1              ;Error register
iErrorVer:  equ iErrorReg - 1              ;Verify error flag

store_bank_active: equ iErrorVer - (5 + 8 ) 		; indicator of which storage banks are available to use 5 on board and 8 in cart

STORE_BLOCK_LOG:  equ   255      ; TODO remove.... Logical block size   

store_page: equ store_bank_active-STORE_BLOCK_LOG            ; page size for eeprom
store_ffpage: equ store_page-STORE_BLOCK_LOG            ; page size for eeprom
store_tmpid: equ store_ffpage - 1
store_filecache: equ store_tmpid+(2*5)   ;  TODO (using just one for now)  file id + extent count cache * 5
store_tmppageid: equ store_filecache-2
;
; spi vars
; 

spi_portbyte: equ store_tmppageid - 1      ; holds bit mask to send to spi bus
spi_device: equ spi_portbyte - 1    ; bit mask to or to select the spi device pin
;;;;; forth cli params

; TODO use a different frame buffer for forth???

f_cursor_ptr:  equ spi_device - 1  ; offset into frame buffer for any . or EMIT output
cli_buffer: equ f_cursor_ptr - 20     ; temp hold - maybe not needed
cli_origtoken: equ cli_buffer - 2     ; pointer to the text of token for this word being checked
cli_token: equ cli_origtoken - 2     ; pointer to the text of token for this word being checked
cli_execword: equ cli_token - 2      ; pointer to start of code for this word
cli_nextword: equ cli_execword - 2      ; pointer to start of next word in dict
cli_ptr: equ cli_nextword - 2           ; pointer to start of word to parse by forth kernel (working)
cli_origptr: equ cli_ptr - 2           ; pointer to start of word to parse which resets cli_ptr on each word test

cli_autodisplay: equ cli_origptr - 1 ;     ; true will auto update the display (slow) otherwise need to use DRAW
cli_var_array: equ cli_autodisplay - ( 10 * 2 ) ; word or string pointer variables using @0-@9
cli_ret_sp: equ cli_var_array - 2    ; ret stack pointer
cli_loop_sp: equ cli_ret_sp - 2   ; data stack pointer
cli_data_sp: equ cli_loop_sp - 2   ; data stack pointer
cli_ret_stack: equ cli_data_sp - 128      ; TODO could I just use normal stack for this? - use linked list for looping
cli_loop_stack: equ cli_data_sp - 128      ; TODO could I just use normal stack for this? - use linked list for looping
cli_data_stack: equ cli_loop_stack - 512		 ; 

; os/forth token vars

os_last_cmd: equ cli_data_stack-290         
os_current_i: equ os_last_cmd-2
os_cur_ptr: equ os_current_i-2
os_word_scratch: equ os_cur_ptr-30
os_tok_len: equ os_word_scratch - 2
os_tok_ptr: equ os_tok_len - 2               ; our current PC ptr
os_tok_malloc: equ os_tok_ptr - 2
os_last_new_uword: equ os_tok_malloc - 2    ; hold start of last user word added
os_input: equ os_last_new_uword-100
scratch: equ os_input-255


; temp locations for new word processing to save on adding more 

os_new_malloc: equ os_input
os_new_parse_len: equ os_new_malloc + 2
os_new_word_len: equ os_new_parse_len + 2
os_new_work_ptr: equ os_new_word_len + 2
os_new_src_ptr: equ os_new_work_ptr + 2
os_new_exec: equ os_new_src_ptr + 2
os_new_exec_ptr: equ os_new_exec + 2


os_view_disable: equ scratch - 1
os_view_af: equ os_view_disable - 2
os_view_hl: equ os_view_af -2
os_view_de: equ os_view_hl - 2
os_view_bc: equ os_view_de - 2


; with data stack could see memory filled with junk. need some memory management 
; malloc and free entry points added

free_list:  equ os_view_bc - 4     ; Block struct for start of free list (MUST be 4 bytes)
heap_size: equ  (free_list-08100h)      ; Number of bytes available in heap   TODO make all of user ram
;heap_start: equ free_list - heap_size  ; Starting address of heap
heap_end: equ free_list-1  ; Starting address of heap
heap_start: equ free_list - heap_size  ; Starting address of heap

;;;;


; change below to point to last memory alloc above
topusermem:  equ   heap_start
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
KEY_SHIFTLOCK: equ 4

;KEY_SHIFT:   equ 5
;KEY_SYMBOLSHIFT:  equ 6

KEY_UP: equ 14
KEY_DOWN: equ 15
KEY_LEFT: equ 16
KEY_RIGHT: equ 17
KEY_HOME: equ 18
KEY_END: equ 19

;if DEBUG_KEY
;	KEY_MATRIX_NO_PRESS: equ '.'
;	KEY_SHIFT:   equ '.'
;	KEY_SYMBOLSHIFT:  equ '.'
;else
	KEY_SHIFT:   equ '~'
	KEY_SYMBOLSHIFT:  equ '~'
	KEY_MATRIX_NO_PRESS: equ '~'
;endi



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

	if MALLOC_1
		call  heap_init
	endif

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

ld a, '_'
ld (debug_mark),a
ld a,0
ld (debug_mark+1),a

		ret


bootmsg:	db "z80-homebrew OS v1.0",0
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

;;;;;
;;;
; Moved out to mini and maxi versions
;
; include "firmware_key_4x4.asm"
; using existing 4 wire x 4 resistor array for input
;include "firmware_key_4x10.asm"
; need to mod the board for 5 rows due to resistor array
;include "firmware_key_5x10.asm"

; storage hardware interface

; use microchip serial eeprom for storage


if STORAGE_SE
	include "firmware_spi.asm"
	include "firmware_seeprom.asm"
endif

; use cf card for storage - throwing timeout errors. Hardware or software?????
;include "firmware_cf.asm"

; load up high level storage hardward abstractions
include "firmware_storage.asm"

; support routines for above hardware abstraction layer

include "firmware_general.asm"        ; general support functions
include "firmware_display.asm"      ; frame buffer screen abstraction layer
include "firmware_maths.asm"     ; any odd maths stuff   TODO removed until I fix up the rng code
include "firmware_strings.asm"   ; string handling
include "firmware_memory.asm"   ; malloc and free






; eof

