
; main constants (used here and in firmware)


DEBUG_KEY: equ 1


tos:	equ 0ffffh
stacksize: equ 128


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
key_actual_pressed: equ key_face_held - 1 
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


scratch: equ cursor_row-255

; change below to point to last memory alloc above
topusermem:  equ   scratch
; **********************************************************************
; **  Constants
; **********************************************************************

; Constants used by this code module
kDataReg:   EQU 0xc0           ;PIO port A data register
kContReg:   EQU 0xc2           ;PIO port A control register


portbdata:  equ 0xc1    ; port b data
portbctl:   equ 0xc3    ; port b control


hardware_init:	call key_init
		call lcd_init

		
	
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
include "firmware_lcd.asm"

; must supply cin, cout entry points
; test scancode
include "firmware_key_4x4.asm"




; Delay loops



aDelayInMS:
	push bc
	ld b,a
msdelay:
	push bc
	

	ld bc,041h
	call delayloop
	pop bc
	dec b
	jr nz,msdelay
	pop bc
	ret


delay250ms:
	;push de
	ld bc, 04000h
	jp delayloop
delay500ms:
	;push de
	ld bc, 08000h
	jp delayloop
delay1s:
	;push bc
   ; Clobbers A, d and e
    ld      bc,0      ; # 0ffffh = approx 1s
delayloop:
    bit     0,a    	; 8
    bit     0,a    	; 8
    bit     0,a    	; 8
    and     255  	; 7
    dec     bc      	; 6
    ld      a,c     	; 4
    or      b     	; 4
    jp      nz,delayloop   	; 10, total = 55 states/iteration
    ; 65536 iterations * 55 states = 3604480 states = 2.00248 seconds
	;pop de
	ret

; strcpy hl = dest, de source

strcpy:   LD   A, (DE)        ;Get character from string
            OR   A              ;Null terminator?
            RET  Z              ;Yes, so finished
		ld a,(de)
		ld (hl),a
            INC  DE             ;Point to next character
		inc hl
            JR   strcpy       ;Repeat
		ret


; eof

