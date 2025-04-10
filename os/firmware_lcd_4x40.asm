; **********************************************************************
; **  Alphanumeric LCD example                  by Stephen C Cousins  **
; **********************************************************************
;
; **  Written as a Small Computer Monitor App
; **  www.scc.me.uk
;
; History
; 2018-05-20  v0.2.0  SCC  Example for LiNC80 SBC1 only
; 2018-06-28  v0.3.0  SCC  Added support for RC2014 and Z280RC
; 2019-09-14  v0.4.0  SCC  Added support for SC129 digital I/O module
;
; **********************************************************************
;
; This program is an example of one of the methods of interfacing an 
; alphanumeric LCD module. 
;
; In this example the display is connected to either a Z80 PIO or a 
; simple 8-bit output port. 
;
; This interfacing method uses 4-bit data mode and uses time delays
; rather than polling the display's ready status. As a result the 
; interface only requires 6 simple output lines:
;   Output bit 0 = not used
;   Output bit 1 = not used
;   Output bit 2 = RS         High = data, Low = instruction
;   Output bit 3 = E          Active high
;   Output bit 4 = DB4
;   Output bit 5 = DB5
;   Output bit 6 = DB6
;   Output bit 7 = DB7
; Display's R/W is connected to 0v so it is always in write mode
;
; This set up should work with any system supporting the RC2014 bus

; To set up PIO port A in mode 3 (control) using LiNC80 as example
;   I/O address 0x1A = 0b11001111 (0xCF)   Select mode 3 (control)
;   I/O address 0x1A = 0b00000000 (0x00)   All pins are output
;
; **********************************************************************

; Additonal for 4x40. E1 and E2 instead of just E 
; TODO swipe vidout signal on port a to activate E2

; **********************************************************************
; **  Constants
; **********************************************************************
; LCD constants required by LCD support module
kLCDPrt:    EQU kDataReg       ;LCD port is the PIO port A data reg
kLCDBitRS:  EQU 2              ;Port bit for LCD RS signal
kLCDBitE:   EQU 3              ;Port bit for LCD E signal           
kLCDBitE2:   EQU 0              ;Port bit for LCD E2 signal            VIDOUT
; TODO Decide which E is being set
kLCDWidth:  EQU display_cols             ;Width in characters

; **********************************************************************
; **  Code library usage
; **********************************************************************

; send character to current cursor position
; wraps and/or scrolls screen automatically



lcd_init:

; SCMonAPI functions used

; Alphanumeric LCD functions used
; no need to specify specific functions for this module

            LD   A, 11001111b
            OUT  (kContReg), A  ;Port A = PIO 'control' mode
            LD   A, 00000000b
            OUT  (kContReg),A   ;Port A = all lines are outputs

; Initialise alphanumeric LCD module
		ld a, 0
		ld (display_lcde1e2), a
            CALL fLCD_Init      ;Initialise LCD module
		ld a, 1
		ld (display_lcde1e2), a
            CALL fLCD_Init      ;Initialise LCD module

	ret

;
;;
; lcd functions
;
;

; what is at cursor position 

;get_cursor:	ld de, (cursor_row)   ;  row + col
;		call curptr
;		ret


; take current custor pos in de (d=row,e=col) and return a pointer to the frame buffer

curptr:
	push bc
	ld hl, display_fb0
cpr:	
	; loop for cursor whole row
	ld c, display_cols
cpr1:	inc hl
	dec c
	jr nz, cpr1
	dec b
	jr nz, cpr

	; add col	

cpr2:	inc hl
	dec e
	jr nz, cpr2

	pop bc
	ret
	




; write the frame buffer given in hl to hardware 
write_display: ld (display_write_tmp), hl 	 
	ld a, kLCD_Line1
            CALL fLCD_Pos       ;Position cursor to location in A
	ld b, display_cols
	ld de, (display_write_tmp)
	call write_len_string
	
	
	ld hl, (display_write_tmp)
	ld de, display_cols
	add hl,de
	ld (display_write_tmp),hl

	
	ld a, kLCD_Line2
            CALL fLCD_Pos       ;Position cursor to location in A
	ld b, display_cols
	ld de, (display_write_tmp)
	call write_len_string
	
	ld hl, (display_write_tmp)
	ld de, display_cols
	add hl,de
	ld (display_write_tmp),hl

	
	ld a, kLCD_Line3
            CALL fLCD_Pos       ;Position cursor to location in A
	ld b, display_cols
	ld de, (display_write_tmp)
	call write_len_string
	
	ld hl, (display_write_tmp)
	ld de, display_cols
	add hl,de
	ld (display_write_tmp),hl

	
	ld a, kLCD_Line4
            CALL fLCD_Pos       ;Position cursor to location in A
	ld b, display_cols
	ld de, (display_write_tmp)
	call write_len_string
		ret
	
	; write out a fixed length string given in b from de

write_len_string:   LD   A, (DE)        ;Get character from string
            CALL fLCD_Data      ;Write character to display
	inc de
	djnz write_len_string
	ret

; Some other things to do
;            LD   A, kLCD_Clear ;Display clear
;            LD   A, kLCD_Blink ;Display on with blinking block cursor
;            LD   A, kLCD_Under ;Display on with underscore cursor
;            LD   A, kLCD_On     ;Display on with no cursor
;            ;LD   A, kLCD_Off   ;Display off
;            CALL fLCD_Inst      ;Send instruction to display
;
;
;            halt
;
;
;MsgHello:   DB  "Hello World!",0
;MsgLiNC80:   DB  "From my Z80-homebrew",0

; Custom characters 5 pixels wide by 8 pixels high
; Up to 8 custom characters can be defined
;BitMaps:    
;; Character 0x00 = Battery icon
;            DB  01110b
;            DB  11011b
;            DB  10001b
;            DB  10001b
;            DB  11111b
;            DB  11111b
;            DB  11111b
;            DB  11111b
;; Character 0x01 = Bluetooth icon
;            DB  01100b
;            DB  01010b
;            DB  11100b
;            DB  01000b
;            DB  11100b
;            DB  01010b
;            DB  01100b
;            DB  00000b
;


; **********************************************************************
; **  Alphanumeric LCD support                  by Stephen C Cousins  **
; **********************************************************************
;
; **  Written as a Small Computer Monitor App 
; **  Version 0.1 SCC 2018-05-16
; **  www.scc.me.uk
;
; **********************************************************************
;
; This module provides support for alphanumeric LCD modules using with
; *  HD44780 (or compatible) controller
; *  5 x 7 pixel fonts
; *  Up to 80 characters in total (eg. 4 lines of 20 characters)
; *  Interface via six digital outputs to the display (see below)
;
; LCD module pinout:
;   1  Vss   0v supply
;   2  Vdd   5v supply
;   3  Vo    LCD input voltage (near zero volts via potentiometer)
;   4  RS    High = data, Low = instruction
;   5  R/W   High = Read, Low = Write
;   6  E     Enable signal (active high)
;   7  DB0   Data bit 0
;   8  DB1   Data bit 1
;   9  DB2   Data bit 2
;  10  DB3   Data bit 3
;  11  DB4   Data bit 4
;  12  DB5   Data bit 5
;  13  DB6   Data bit 6
;  14  DB7   Data bit 7
;  15  A     Backlight anode (+)
;  16  K     Backlight cathode (-)
;
; This interfacing method uses 4-bit data mode and uses time delays
; rather than polling the display's ready status. As a result the 
; interface only requires 6 simple output lines:
;   LCD E   = Microcomputer output port bit <kLCDBitE>
;   LCD RS  = Microcomputer output port bit <kLCDBitRS>
;   LCD DB4 = Microcomputer output port bit 4
;   LCD DB5 = Microcomputer output port bit 5
;   LCD DB6 = Microcomputer output port bit 6
;   LCD DB7 = Microcomputer output port bit 7
; Display's R/W is connected to 0v so it is always in write mode
; All 6 connections must be on the same port address <kLCDPrt>
; This method also allows a decent length of cable from micro to LCD
;
; **********************************************************************
;
; To include the code for any given function provided by this module, 
; add the appropriate #REQUIRES <FunctionName> statement at the top of 
; the parent source file.
; For example:  #REQUIRES   uHexPrefix
;
; Also #INCLUDE this file at some point after the #REQUIRES statements
; in the parent source file.
; For example:  #INCLUDE    ..\_CodeLibrary\Utilities.asm
;
; These are the function names provided by this module:
; fLCD_Init                     ;Initialise LCD
; fLCD_Inst                     ;Send instruction to LCD
; fLCD_Data                     ;Send data byte to LCD
; fLCD_Pos                      ;Position cursor
; fLCD_Str                      ;Display string
; fLCD_Def                      ;Define custom character
;
; **********************************************************************
;
; Requires SCMonAPI.asm to also be included in the project
;


; **********************************************************************
; **  Constants
; **********************************************************************

; Constants that must be defined externally
;kLCDPrt:   EQU 0xc0           ;Port address used for LCD
;kLCDBitRS: EQU 2              ;Port bit for LCD RS signal
;kLCDBitE:  EQU 3              ;Port bit for LCD E signal
;kLCDWidth: EQU 20             ;Width in characters

; general line offsets in any frame buffer


display_row_1: equ 0
display_row_2: equ display_row_1+display_cols
display_row_3: equ display_row_2 + display_cols
display_row_4: equ display_row_3 + display_cols
;display_row_4_eol: 


; Cursor position values for the start of each line

; E
kLCD_Line1: EQU 0x00 
kLCD_Line2: EQU kLCD_Line1+kLCDWidth
; E1
kLCD_Line3: EQU kLCD_Line2+kLCDWidth
kLCD_Line4: EQU kLCD_Line3+kLCDWidth 

; Instructions to send as A register to fLCD_Inst
kLCD_Clear: EQU 00000001b     ;LCD clear
kLCD_Off:   EQU 00001000b     ;LCD off
kLCD_On:    EQU 00001100b     ;LCD on, no cursor or blink
kLCD_Under: EQU 00001110b     ;LCD on, cursor = underscore
kLCD_Blink: EQU 00001101b     ;LCD on, cursor = blink block
kLCD_Both:  EQU 00001111b     ;LCD on, cursor = under+blink

; Constants used by this code module
kLCD_Clr:   EQU 00000001b     ;LCD command: Clear display
kLCD_Pos:   EQU 10000000b     ;LCD command: Position cursor
kLCD_Def:   EQU 01000000b     ;LCD command: Define character



; **********************************************************************
; **  LCD support functions
; **********************************************************************

; Initialise alphanumeric LCD module
; LCD control register codes:
;   DL   0 = 4-bit mode        1 = 8-bit mode
;   N    0 = 1-line mode       1 = 2-line mode
;   F    0 = Font 5 x 8        1 = Font 5 x 11
;   D    0 = Display off       1 = Display on
;   C    0 = Cursor off        1 = Cursor on
;   B    0 = Blinking off      1 = Blinking on
;   ID   0 = Decrement mode    1 = Increment mode
;   SH   0 = Entire shift off  1 = Entire shift on
fLCD_Init:  LD   A, 40
            CALL LCDDelay       ;Delay 40ms after power up
; For reliable reset set 8-bit mode - 3 times
            CALL WrFn8bit       ;Function = 8-bit mode
            CALL WrFn8bit       ;Function = 8-bit mode
            CALL WrFn8bit       ;Function = 8-bit mode
; Set 4-bit mode
            CALL WrFn4bit       ;Function = 4-bit mode
            CALL LCDDelay1      ;Delay 37 us or more
; Function set
            LD   A, 00101000b  ;Control reg:  0  0  1  DL N  F  x  x
            CALL fLCD_Inst      ;2 line, display on
; Display On/Off control
            LD   A, 00001100b  ;Control reg:  0  0  0  0  1  D  C  B 
            CALL fLCD_Inst      ;Display on, cursor on, blink off
; Display Clear
            LD   A, 00000001b  ;Control reg:  0  0  0  0  0  0  0  1
            CALL fLCD_Inst      ;Clear display
; Entry mode
            LD   A, 00000110b  ;Control reg:  0  0  0  0  0  1  ID SH
            CALL fLCD_Inst      ;Increment mode, shift off
; Display module now initialised
            RET
; ok to here

; Write instruction to LCD
;   On entry: A = Instruction byte to be written
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
fLCD_Inst:  PUSH AF
            PUSH AF
            CALL Wr4bits       ;Write bits 4 to 7 of instruction
            POP  AF
            RLA                 ;Rotate bits 0-3 into bits 4-7...
            RLA
            RLA
            RLA
            CALL Wr4bits       ;Write bits 0 to 3 of instruction
            LD   A, 2
            CALL LCDDelay       ;Delay 2 ms to complete 
            POP  AF
            RET
Wr4bits: 
		push af
		ld a, (display_lcde1e2)
		cp 0     ; e
		jr nz, .wea2	
		pop af
	    AND  0xF0           ;Mask so we only have D4 to D7
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
            SET  kLCDBitE, A	    ; TODO decide which E is being set
            res  kLCDBitE2, A	    ; TODO decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=High and RS=Low
            RES  kLCDBitE, A        ; TODO decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
            RET
.wea2:		pop af
	    AND  0xF0           ;Mask so we only have D4 to D7
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
            SET  kLCDBitE2, A	    ; TODO decide which E is being set
            res  kLCDBitE, A	    ; TODO decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=High and RS=Low
            RES  kLCDBitE2, A        ; TODO decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
            RET


; Write data to LCD
;   On entry: A = Data byte to be written
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
fLCD_Data:  PUSH AF
            PUSH AF
            CALL Wr4bitsa       ;Write bits 4 to 7 of data byte
            POP  AF
            RLA                 ;Rotate bits 0-3 into bits 4-7...
            RLA
            RLA
            RLA
            CALL Wr4bitsa       ;Write bits 0 to 3 of data byte
            LD   A, 150
Wait:      DEC  A              ;Wait a while to allow data 
            JR   NZ, Wait      ;  write to complete
            POP  AF
            RET
Wr4bitsa:   
		push af
		ld a, (display_lcde1e2)
		cp 0     ; e1
		jr nz, .we2	
		pop af
	    AND  0xF0           ;Mask so we only have D4 to D7
            SET  kLCDBitRS, A
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=High
            SET  kLCDBitE, A      ; TODO Decide which E is being set
            res  kLCDBitE2, A      ; TODO Decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=High and RS=High
            RES  kLCDBitE, A       ; TODO Decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=High
            RES  kLCDBitRS, A
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
            RET
.we2:		pop af
	    AND  0xF0           ;Mask so we only have D4 to D7
            SET  kLCDBitRS, A
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=High
            SET  kLCDBitE2, A      ; TODO Decide which E is being set
            res  kLCDBitE, A      ; TODO Decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=High and RS=High
            RES  kLCDBitE2, A       ; TODO Decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=High
            RES  kLCDBitRS, A
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
            RET


; Position cursor to specified location
;   On entry: A = Cursor position
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
fLCD_Pos:   PUSH AF
		; at this point set the E1 or E2 flag depending on position

		push bc
;		push af
		ld b, 0
		ld c, a
		ld a, kLCD_Line3-1
 		or a      ;clear carry flag
		sbc a,c    ; TODO may need to sub 80 from a to put in context of current frame  
		jr c, .pe1

		; E selection
		res 0, b         ; bit 0 unset e
;		pop af    ; before line 3 so recover orig pos
;		ld c, a    ; save for poking back
		jr .peset	        
.pe1:          	; E2 selection
		set 0, b         ; bit 0 set e1
		ld a, c
		sbc a, kLCD_Line3-1
		ld c, a	         ; save caculated offset
;		pop af     ; bin this original value now we have calculated form

.peset:		; set bit
		ld a, b
		ld (display_lcde1e2), a 	
		ld a, c
		pop bc

            OR   kLCD_Pos       ;Prepare position cursor instruction
            CALL fLCD_Inst      ;Write instruction to LCD
            POP  AF
            RET


; Output text string to LCD
;   On entry: DE = Pointer to null terminated text string
;   On exit:  BC HL IX IY I AF' BC' DE' HL' preserved
fLCD_Str:   LD   A, (DE)        ;Get character from string
            OR   A              ;Null terminator?
            RET  Z              ;Yes, so finished
            CALL fLCD_Data      ;Write character to display
            INC  DE             ;Point to next character
            JR   fLCD_Str       ;Repeat
		ret

; Define custom character
;   On entry: A = Character number (0 to 7)
;             DE = Pointer to character bitmap data
;   On exit:  A = Next character number
;             DE = Next location following bitmap
;             BC HL IX IY I AF' BC' DE' HL' preserved
; Character is 
fLCD_Def:   PUSH BC
            PUSH AF
            RLCA                ;Calculate location
            RLCA                ;  for bitmap data
            RLCA                ;  = 8 x CharacterNumber
            OR   kLCD_Def       ;Prepare define character instruction
            CALL fLCD_Inst      ;Write instruction to LCD
            LD   B, 0
Loop:      LD   A, (DE)        ;Get byte from bitmap
            CALL fLCD_Data      ;Write byte to display
            INC  DE             ;Point to next byte
            INC  B              ;Count bytes
            BIT  3, B           ;Finish all 8 bytes?
            JR   Z, Loop       ;No, so repeat
            POP  AF
            INC  A              ;Increment character number
            POP  BC
            RET


; **********************************************************************
; **  Private functions
; **********************************************************************

; Write function to LCD
;   On entry: A = Function byte to be written
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
WrFn4bit:   LD   A, 00100000b  ;4-bit mode
            JR   WrFunc
WrFn8bit:   LD   A, 00110000b  ;8-bit mode
WrFunc:     PUSH AF
		push af
		ld a, (display_lcde1e2)
		cp 0     ; e1
		jr nz, .wfea2	
		pop af
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
            SET  kLCDBitE, A     ; TODO Decide which E is being set
            RES  kLCDBitE2, A      ; TODO Decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=High and RS=Low
            RES  kLCDBitE, A      ; TODO Decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
	jr .wfskip
.wfea2:		pop af
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
            SET  kLCDBitE2, A     ; TODO Decide which E is being set
            RES  kLCDBitE, A      ; TODO Decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=High and RS=Low
            RES  kLCDBitE2, A      ; TODO Decide which E is being set
            OUT  (kLCDPrt), A   ;Output with E=Low and RS=Low
.wfskip:            LD  A, 5
            CALL LCDDelay       ;Delay 5 ms to complete
            POP  AF
            RET


; Delay in milliseconds
;   On entry: A = Number of milliseconds delay
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
LCDDelay1:  LD   A, 1           ;Delay by 1 ms
LCDDelay:   PUSH DE
            LD   E, A           ;Delay by 'A' ms
            LD   D, 0
            CALL aDelayInMS
            POP  DE
            RET


testlcd:
	ld a, kLCD_Line1
	call fLCD_Pos
	ld b, 40
	ld de, .ttext1
	call write_len_string

	ld a, kLCD_Line2
	call fLCD_Pos
	ld b, 40
	ld de, .ttext2
	call write_len_string
	ld a, kLCD_Line3
	call fLCD_Pos
	ld b, 40
	ld de, .ttext3
	call write_len_string
	ld a, kLCD_Line4
	call fLCD_Pos
	ld b, 40
	ld de, .ttext4
	call write_len_string

	halt


.ttext1: db "A234567890123456789012345678901234567890",0
.ttext2: db "B234567890123456789012345678901234567890",0
.ttext3: db "C234567890123456789012345678901234567890",0
.ttext4: db "D234567890123456789012345678901234567890",0
 


; eof

