
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

