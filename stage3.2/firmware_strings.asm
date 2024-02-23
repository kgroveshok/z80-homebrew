

; TODO string len
; input text string, end on cr with zero term
; bc is row and column to start prompt
; d is max length
; e is current cursor position
; hl is ptr to where string will be stored

input_str: 
		ld (input_ptr), hl
		ld (input_start), hl
		ld a,d
		ld (input_size), a
		ld a,0
		ld (input_cursor),a
.instr1:	

		; TODO do block cursor
		; TODO switch cursor depending on the modifer key

		; display entered text
        	LD   A, kLCD_Line3    ; TODO position cursor for now just put at second line
            	CALL fLCD_Pos       ;Position cursor to location in A
            	LD   de, (input_start)
            	CALL fLCD_Str       ;Display string pointed to by DE

		call cin
		cp 0
		jr z, .instr1

		; proecess keyboard controls first

		ld hl,(input_ptr)

		cp KEY_CR	 ; pressing enter ends input
		ret z

		cp KEY_BS 	; back space
		jr nz, .instr2
		; process back space

		; TODO stop back space if at start of string

		dec hl
		ld a,' '
		;ld a,0
		ld (hl),a
		ld (input_ptr),hl
		

		jr .instr1

.instr2:	; no special key pressed to see if we have room to store it

		; TODO do string size test

		ld (hl),a
		inc hl
		ld a,0
		ld (hl),a

		ld (input_ptr),hl
		
		jr .instr1


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


; TODO string_at 
; pass string which starts with lcd offset address and then null term string

; TODO string to dec
; TODO string to hex
; TODO byte to string hex
; TODO byte to string dec



; from z80uartmonitor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; OUTPUT VALUE OF A IN HEX ONE NYBBLE AT A TIME
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
hexout:	PUSH BC
		PUSH AF
		LD B, A
		; Upper nybble
		SRL A
		SRL A
		SRL A
		SRL A
		CALL TOHEX
		CALL cout   ; TODO should be going to frame buffer and not direct lcd
		
		; Lower nybble
		LD A, B
		AND 0FH
		CALL TOHEX
		CALL cout
		
		POP AF
		POP BC
		RET
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; TRANSLATE value in lower A TO 2 HEX CHAR CODES FOR DISPLAY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
TOHEX:
		PUSH HL
		PUSH DE
		LD D, 0
		LD E, A
		LD HL, .DATA
		ADD HL, DE
		LD A, (HL)
		POP DE
		POP HL
		RET

.DATA:
		DEFB	30h	; 0
		DEFB	31h	; 1
		DEFB	32h	; 2
		DEFB	33h	; 3
		DEFB	34h	; 4
		DEFB	35h	; 5
		DEFB	36h	; 6
		DEFB	37h	; 7
		DEFB	38h	; 8
		DEFB	39h	; 9
		DEFB	41h	; A
		DEFB	42h	; B
		DEFB	43h	; C
		DEFB	44h	; D
		DEFB	45h	; E
		DEFB	46h	; F
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 	ASCII char code for 0-9,A-F in A to single hex digit
;;    subtract $30, if result > 9 then subtract $7 more
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ATOHEX:
		SUB $30
		CP 10
		RET M		; If result negative it was 0-9 so we're done
		SUB $7		; otherwise, subtract $7 more to get to $0A-$0F
		RET		
; eof

