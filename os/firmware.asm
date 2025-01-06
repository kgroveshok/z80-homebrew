
; main constants (used here and in firmware)

; TODO have page 0 of storage as bios

Device_A: equ 0h
Device_B: equ 040h          ; Sound
Device_C: equ 080h          ; Storage and ext cart devices
Device_D: equ 0c0h             ; Keyboard and LCD

; Odd specific debug points for testing hardware dev

DEBUG_SOUND: equ 1
DEBUG_STK_FAULT: equ 0
DEBUG_INPUT: equ 1     ; Debug input entry code
DEBUG_KEYCINWAIT: equ 0
DEBUG_KEYCIN: equ 0
DEBUG_KEY: equ 0
DEBUG_KEY_MATRIX: equ 0
DEBUG_STORECF: equ 0
DEBUG_STORESE: equ 1        ; TODO  w locks up, r returns. 
DEBUG_SPI_HARD_CE0: equ 0    ; only handshake on CE0 on port A
DEBUG_SPI: equ 0    ; low level spi tests

; Enable many break points

DEBUG_FORTH_PARSE_EXEC: equ 1     ; 6
DEBUG_FORTH_PARSE_EXEC_SLOW: equ 0     ; 6
DEBUG_FORTH_PARSE_NEXTWORD: equ 0
DEBUG_FORTH_JP: equ 0
DEBUG_FORTH_MALLOC: equ 1
DEBUG_FORTH_MALLOC_INT: equ 1
DEBUG_FORTH_DOT: equ 1
DEBUG_FORTH_DOT_WAIT: equ 0
DEBUG_FORTH_MATHS: equ 0
DEBUG_FORTH_TOK: equ 1     ; 4
DEBUG_FORTH_PARSE: equ 1    ; 3
DEBUG_FORTH: equ 1  ;2
DEBUG_FORTH_WORDS: equ 1   ; 1
DEBUG_FORTH_PUSH: equ 1   ; 1
DEBUG_FORTH_UWORD: equ 1   ; 1

; Enable key point breakpoints

DEBUG_FORTH_DOT_KEY: equ 0
DEBUG_FORTH_PARSE_KEY: equ 1   ; 5
DEBUG_FORTH_WORDS_KEY: equ 1   ; 1



; House keeping and protections

DEBUG_FORTH_STACK_GUARD: equ 1
DEBUG_FORTH_MALLOC_GUARD: equ 0
DEBUG_FORTH_MALLOC_HIGH: equ 0     ; warn only if more than 255 chars being allocated. would be highly unusual!
FORTH_ENABLE_FREE: equ 0
FORTH_ENABLE_POPFREE: equ 0
FORTH_ENABLE_FLOATMATH: equ 0


CALLMONITOR: macro
	call break_point_state
	endm

MALLOC_1: equ 0        ; from dk88 
MALLOC_2: equ 0           ; broke
MALLOC_3: equ 0           ; really broke
MALLOC_4: equ 1              ; mine pretty basic reuse and max of 250 chars

if BASE_KEV 
stacksize: equ 512*2

STACK_RET_SIZE: equ 128
STACK_LOOP_SIZE: equ 512
STACK_DATA_SIZE: equ 512
endif
if BASE_SC114
;tos:	equ 0f000h
stacksize: equ 256
STACK_RET_SIZE: equ 64
STACK_LOOP_SIZE: equ 256
STACK_DATA_SIZE: equ 256
endif


if STORAGE_SE == 0
	STORE_BLOCK_PHY:   equ 64    ; physical block size on storage   64byte on 256k eeprom
	STORE_DEVICE_MAXBLOCKS:  equ  512 ; how many blocks are there on this storage device
endif

; memory allocation 

chk_stund: equ tos+2           ; underflow check word
chk_stovr: equ chk_stund-stacksize -2; overflow check word

; keyscan table needs rows x cols buffer
;key_rows: equ 5     ; TODO move out to mini and maxi + 1 null
;key_cols: equ 10    ; TODO move out to mini and maxi + 1 null

keyscan_table_row1: equ chk_stovr -key_cols-1
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

; flag for enabling/disabling various hardware diags 

hardware_diag: equ key_face_held - 1

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

hardware_word: equ hardware_diag - 2

; debug marker - optional display of debug point on the debug screens

debug_mark: equ hardware_word - 4

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

;display_rows: equ 4     ; move out to mini and mega files
;display_cols: equ 20

display_fb_len: equ display_rows*display_cols

; primary frame buffer   
display_fb0: equ  key_shift-display_fb_len-display_fb_len-1          ; cli input     TODO why is that doubling up?
; working frame buffers
display_fb1: equ  display_fb0-display_fb_len-display_fb_len-1          ; default running program
display_fb3: equ  display_fb1-display_fb_len - 1
display_fb2: equ  display_fb3-display_fb_len - 1
;
; pointer to active frame buffer
display_fb_active: equ display_fb2 - 2
display_lcde1e2: equ display_fb_active - 1         ; 0=e1, 1=e2   For E1/E2 selection when using the lcd 4x40 display
display_write_tmp: equ display_lcde1e2 - 2


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

store_bank_active: equ iErrorVer - (5 + 8 ) 		; TODO not used.  indicator of which storage banks are available to use 5 on board and 8 in cart

STORE_BLOCK_LOG:  equ   255      ; TODO remove.... Logical block size   

store_page: equ store_bank_active-STORE_BLOCK_LOG            ; page size for eeprom
store_ffpage: equ store_page-STORE_BLOCK_LOG            ; page size for eeprom
store_tmpid: equ store_ffpage - 1		; page temp id
store_tmpext: equ store_tmpid - 1		; file extent temp
store_openext: equ store_tmpext - 1		; file extent of current opened file for read
store_openmaxext: equ store_openext - 1		; max extent of current opened file for read
store_filecache: equ store_openmaxext+(2*5)   ;  TODO (using just one for now)  file id + extent count cache * 5
store_tmppageid: equ store_filecache-2    ; phyical page id temp
;
; spi vars


spi_cartdev: equ store_tmppageid - 1      ; holds bit mask to send to portb (ext spi) devices
spi_cartdev2: equ spi_cartdev - 1      ; holds bit mask to send to portb's shift reg devices
spi_portbyte: equ spi_cartdev2 - 1      ; holds bit mask to send to spi bus 
spi_device: equ spi_portbyte - 1    ; bit mask to send to porta (eeproms) devices

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

cli_mvdot: equ cli_origptr - 1 ;     ; true will move the cursor once something is displayed
cli_autodisplay: equ cli_mvdot - 1 ;     ; true will auto update the display (slow) otherwise need to use DRAW
cli_var_array: equ cli_autodisplay - ( 10 * 2 ) ; word or string pointer variables using V@0-V@9
cli_ret_sp: equ cli_var_array - 2    ; ret stack pointer
cli_loop_sp: equ cli_ret_sp - 2   ; data stack pointer
cli_data_sp: equ cli_loop_sp - 2   ; data stack pointer

chk_ret_und: equ cli_data_sp-2           ; underflow check word
cli_ret_stack: equ chk_ret_und - STACK_RET_SIZE      ; TODO could I just use normal stack for this? - use linked list for looping
chk_ret_ovr: equ cli_ret_stack -2; overflow check word
cli_loop_stack: equ chk_ret_ovr - STACK_LOOP_SIZE      ; TODO could I just use normal stack for this? - use linked list for looping
chk_loop_ovr: equ cli_loop_stack -2; overflow check word
cli_data_stack: equ chk_loop_ovr - STACK_DATA_SIZE		 ; 
chk_data_ovr: equ cli_data_stack -2; overflow check word

; os/forth token vars

os_last_cmd: equ chk_data_ovr-255
os_cli_cmd: equ os_last_cmd-255              ; cli command entry line
os_current_i: equ os_cli_cmd-2
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

; resume memory alloocations....

os_view_disable: equ scratch - 1
os_view_af: equ os_view_disable - 2
os_view_hl: equ os_view_af -2
os_view_de: equ os_view_hl - 2
os_view_bc: equ os_view_de - 2


; stack checksum word

chk_word: equ os_view_bc - 2		 ; this is the word to init and then check against to detect stack corruption. Held far away from all stacks

; with data stack could see memory filled with junk. need some memory management 
; malloc and free entry points added

;free_list:  equ chk_word - 4     ; Block struct for start of free list (MUST be 4 bytes)
;heap_size: equ  (free_list-08100h)      ; Number of bytes available in heap   TODO make all of user ram
;;heap_start: equ free_list - heap_size  ; Starting address of heap
;heap_end: equ free_list-1  ; Starting address of heap
;heap_start: equ free_list - heap_size  ; Starting address of heap

;heap_start: equ free_list - heap_size  ; Starting address of heap
heap_end: equ chk_word-1  ; Starting address of heap


;if BASE_KEV 
;heap_start: equ 0800eh  ; Starting address of heap
;free_list:  equ 0800ah      ; Block struct for start of free list (MUST be 4 bytes)
;heap_size: equ  heap_end-heap_start      ; Number of bytes available in heap   TODO make all of user ram
;endif

;if BASE_SC114
;heap_start: equ baseram+15  ; Starting address of heap
;free_list:  equ baseram+10      ; Block struct for start of free list (MUST be 4 bytes)
;endif


;;;;


; change below to point to last memory alloc above
topusermem:  equ   heap_start

;if BASE_KEV 
;baseusermem: equ 08000h
;endif

;if BASE_SC114
;;aseusermem:     equ    12
;baseusermem:     equ    prompt
;;baseusermem:     equ    endofcode
;endif


; **********************************************************************
; **  Constants
; **********************************************************************

; Constants used by this code module
kDataReg:   EQU Device_D           ;PIO port A data register
kContReg:   EQU Device_D+2           ;PIO port A control register


portbdata:  equ Device_D+1    ; port b data
portbctl:   equ Device_D+3    ; port b control


;KEY_SHIFT:   equ 5
;KEY_SYMBOLSHIFT:  equ 6

KEY_SHIFTLOCK: equ 4


KEY_UP: equ 5
KEY_NEXTWORD: equ 6
KEY_PREVWORD: equ 7
KEY_BS: equ 8
KEY_TAB:  equ 9
KEY_DOWN: equ 10
KEY_LEFT: equ 11
KEY_RIGHT: equ 12
KEY_CR:   equ 13
KEY_HOME: equ 14
KEY_END: equ 15

KEY_F1: equ 16
KEY_F2: equ 17
KEY_F3: equ 18
KEY_F4: equ 19

KEY_F5: equ 20
KEY_F6: equ 21
KEY_F7: equ 22
KEY_F8: equ 23

KEY_F9: equ 24
KEY_F10: equ 25
KEY_F11: equ 26
KEY_F12: equ 27

;if DEBUG_KEY
;	KEY_MATRIX_NO_PRESS: equ '.'
;	KEY_SHIFT:   equ '.'
;	KEY_SYMBOLSHIFT:  equ '.'
;else
	KEY_SHIFT:   equ '~'
	KEY_SYMBOLSHIFT:  equ '~'
	KEY_MATRIX_NO_PRESS: equ '~'
;endi




; Macro to make adding debug marks easier

DMARK: macro str
	push af
	ld a, (.dmark)
	ld (debug_mark),a
	ld a, (.dmark+1)
	ld (debug_mark+1),a
	ld a, (.dmark+2)
	ld (debug_mark+2),a
	jr .pastdmark
.dmark: db str
.pastdmark: pop af

endm



;TODO macro to calc col and row offset into screen



hardware_init:

		ld a, 0
		ld (hardware_diag), a

		; clear all the buffers

		ld hl, display_fb1
		ld (display_fb_active), hl

		call clear_display

		ld hl, display_fb2
		ld (display_fb_active), hl

		call clear_display

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
	if MALLOC_4
		call  heap_init
	endif

	; init sound hardware if present

	if SOUND_ENABLE
		call sound_init
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
if display_cols == 20	
        ld a, display_row_1  
else
        ld a, display_row_1 +10 
endif
	ld de, bootmsg
	call str_at_display
	call update_display


	call delay1s
	call delay1s
if display_cols == 20	
            LD   A, display_row_3+2
else
            LD   A, display_row_3+12
endif
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
ld (debug_mark+1),a
ld (debug_mark+2),a
ld a,0
ld (debug_mark+3),a

		ret


bootmsg:	db "z80-homebrew OS v1.0",0
bootmsg1:	db "by Kevin Groves",0
;bootmsg2:	db "Firmware v0.1",0

; a 4x20 lcd
; cout for display, low level positioning and writing functions (TODO) for hardware abstraction

;if display_cols == 20
;	include "firmware_lcd_4x20.asm"
;endif

;if display_cols == 40
;	include "firmware_lcd_4x40.asm"
;endif

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
else
   ; create some stubs for the labels
se_readbyte: ret
se_writebyte: ret
storage_init: ret

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

; device C
if SOUND_ENABLE
	include "firmware_sound.asm"
endif

include "firmware_diags.asm"



; eof

