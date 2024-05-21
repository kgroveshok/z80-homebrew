

; TODO string len
; input text string, end on cr with zero term
; a offset into frame buffer to start prompt
; d is max length
; e is display size TODO
; c is current cursor position
; hl is ptr to where string will be stored


input_str:    	ld (input_at_pos),a      ; save display position to start
		ld (input_start), hl     ; save ptr to buffer
		ld a,d
	        ld (input_size), a       ; save length of input area
		ld a, 0
		ld (input_cursor),a      ; init cursor start position 
		ld a,e
	        ld (input_display_size), a       ; save length of input area that is displayed TODO

		; init cursor shape
		ld hl, cursor_shape
		ld a, '_'
		ld (hl), a
		inc hl
		ld a, 0
		ld (hl), a


	if DEBUG_INPUT
		push af
		ld a, 'I'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
.is1:		; main entry loop

		; display string

		ld de, (input_start)
		ld a, (input_at_pos)
		call str_at_display
;	        call update_display

		; find place to put the cursor
		ld c, (input_at_pos)
		ld h, (input_cursor)
		ld a, 0
		add h
		add c
		ld l, a
		ld de, cursor_shape
	if DEBUG_INPUT
		push af
		ld a, 'c'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
		call str_at_display
	        call update_display
		


		; get ptr to char to input into

		ld hl, (input_start)
		ld a, (input_cursor)
		call addatohl
		push hl

		; wait
	
		; TODO loop without wait to flash the cursor and char under cursor	
		call cin_wait

		pop hl

	if DEBUG_INPUT
		push af
		ld a, 'i'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
		cp KEY_LEFT
		jr nz, .isk1
		ld a, (input_cursor)
		dec  a 		; TODO check underflow
		ld (input_cursor), a
		
		jp .is1

.isk1:		cp KEY_RIGHT
		jr nz, .isk2

		ld a, (input_cursor)
		inc  a 		; TODO check overflow
		ld (input_cursor), a
		jp .is1

.isk2:		cp KEY_UP
		jr nz, .isk3

		jp .is1

.isk3:		cp KEY_BS
		jr nz, .isk4

		ld a, (input_cursor)
		dec  a 		; TODO check underflow
		ld (input_cursor), a
		ld a, 0
		dec hl
		ld (hl), a

		jp .is1

.isk4:		cp KEY_CR
		jr z, .endinput

		; else add the key press to the end

		ld c, a			; save key pressed

		ld a,(hl)		; get what is currently under char

		cp 0			; we are at the end of the string
		jr nz, .updchar
		
		; add a char to the end of the string
	
		ld (hl),c
		inc hl
		ld a,0
		ld (hl),a
		ld a, (input_cursor)
		inc a				; TODO check max string length and scroll 
		ld (input_cursor), a		; inc cursor pos
				
	if DEBUG_INPUT
		push af
		ld a, '+'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
		jp .is1
		



.updchar:
		ld (hl), c		; otherwise overwrite current char

		ld a, (input_cursor)
		inc  a 		; TODO check overflow
		ld (input_cursor), a
		jp .is1

.endinput:	; TODO look for end of string

		; add trailing space for end of token

		ld a, ' '
		ld (hl),a
		; TODO eof of parse marker

		inc hl
		ld a, 0
		ld (hl),a


		ret


input_str_prev:	ld (input_at_pos), a
		ld (input_start), hl
		ld a,1			; add cursor
		ld (hl),a
		inc hl
		ld a,0
		ld (hl),a
		ld (input_ptr), hl
		ld a,d
		ld (input_size), a
		ld a,0
		ld (input_cursor),a
.instr1:	

		; TODO do block cursor
		; TODO switch cursor depending on the modifer key

		; update cursor shape change on key hold

		ld hl, (input_ptr)
		dec hl
		ld a,(cursor_shape)
		ld (hl), a

		; display entered text
		ld a,(input_at_pos)
            	CALL fLCD_Pos       ;Position cursor to location in A
            	LD   de, (input_start)
            	CALL fLCD_Str       ;Display string pointed to by DE

		call cin
		cp 0
		jr z, .instr1

		; proecess keyboard controls first

		ld hl,(input_ptr)

		cp KEY_CR	 ; pressing enter ends input
		jr z, .instrcr

		cp KEY_BS 	; back space
		jr nz, .instr2
		; process back space

		; TODO stop back space if at start of string
		dec hl
		dec hl ; to over write cursor
		ld a,(cursor_shape)
		;ld a,0
		ld (hl),a
		inc hl
		ld a," "
		ld (hl),a
		ld (input_ptr),hl
		

		jr .instr1

.instr2:	cp KEY_LEFT    ; cursor left
		jr nz, .instr3
		dec hl
		ld (input_ptr),hl
		jr .instr1
	
.instr3:	cp KEY_RIGHT ; cursor right
		jr nz, .instr4
		inc hl
		ld (input_ptr),hl
		jr .instr1

.instr4:	cp KEY_HOME    ; jump to start of line
		jr nz, .instr5
		dec hl
		ld (input_ptr),hl
		jr .instr1

.instr5:	cp KEY_END     ; jump to end of line
		jr nz, .instr6
		dec hl
		ld (input_ptr),hl
		jr .instr1
.instr6:        cp KEY_UP      ; recall last command
		jr nz, .instrnew

	ld hl, scratch
	ld de, os_last_cmd
	call strcpy
		jr .instr1


.instrnew:	; no special key pressed to see if we have room to store it

		; TODO do string size test

		dec hl ; to over write cursor
		ld (hl),a
		inc hl
		ld a,(cursor_shape)
		ld (hl),a
		inc hl
		ld a,0
		ld (hl),a

		ld (input_ptr),hl
		
		jr .instr1
.instrcr:	dec hl		; remove cursor
		ld a,' '	; TODO add a trailing space for safety
		ld (hl),a
		inc hl
		ld a,0
		ld (hl),a


		; if at end of line scroll up   
		; TODO detecting only end of line 4 for scroll up 

		;ld  

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


; TODO string_at 
; pass string which starts with lcd offset address and then null term string

; TODO string to dec
; TODO string to hex
; TODO byte to string hex
; TODO byte to string dec



; from z80uartmonitor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; OUTPUT VALUE OF A IN HEX ONE NYBBLE AT A TIME
; pass hl for where to put the text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
hexout:	PUSH BC
		PUSH AF
		LD B, A
		; Upper nybble
		SRL A
		SRL A
		SRL A
		SRL A
		CALL tohex
		ld (hl),a
		inc hl	
		
		; Lower nybble
		LD A, B
		AND 0FH
		CALL tohex
		ld (hl),a
		inc hl	
		
		POP AF
		POP BC
		RET
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; TRANSLATE value in lower A TO 2 HEX CHAR CODES FOR DISPLAY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
tohex:
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
atohex:
		SUB $30
		CP 10
		RET M		; If result negative it was 0-9 so we're done
		SUB $7		; otherwise, subtract $7 more to get to $0A-$0F
		RET		




; Get 2 ASCII characters as hex byte from pointer in hl

BYTERD:
	LD	D,00h		;Set up
	CALL	HEXCON		;Get byte and convert to hex
	ADD	A,A		;First nibble so
	ADD	A,A		;multiply by 16
	ADD	A,A		;
	ADD	A,A		;
	LD	D,A		;Save hi nibble in D
HEXCON:
	ld a, (hl)		;Get next chr
	inc hl
	SUB	030h		;Makes '0'-'9' equal 0-9
	CP	00Ah		;Is it 0-9 ?
	JR	C,NALPHA	;If so miss next bit
	SUB	007h		;Else convert alpha
NALPHA:
	OR	D		;Add hi nibble back
	RET			;


;
; Get a word (16 bit) in hexadecimal notation. The result is returned in HL.
; Since the routines get_byte and therefore get_nibble are called, only valid
; characters (0-9a-f) are accepted.
;
;get_word        push    af
;                call    get_byte        ; Get the upper byte
;                ld      h, a
;                call    get_byte        ; Get the lower byte
;                ld      l, a
;                pop     af
;                ret
;
; Get a byte in hexadecimal notation. The result is returned in A. Since
; the routine get_nibble is used only valid characters are accepted - the 
; input routine only accepts characters 0-9a-f.
;
get_byte:        push    bc              ; Save contents of B (and C)
		ld a,(hl)
		inc hl
                call    nibble2val      ; Get upper nibble
                rlc     a
                rlc     a
                rlc     a
                rlc     a
                ld      b, a            ; Save upper four bits
		ld a,(hl)
                call    nibble2val      ; Get lower nibble
                or      b               ; Combine both nibbles
                pop     bc              ; Restore B (and C)
                ret
;
; Get a hexadecimal digit from the serial line. This routine blocks until
; a valid character (0-9a-f) has been entered. A valid digit will be echoed
; to the serial line interface. The lower 4 bits of A contain the value of 
; that particular digit.
;
;get_nibble      ld a,(hl)           ; Read a character
;                call    to_upper        ; Convert to upper case
;                call    is_hex          ; Was it a hex digit?
;                jr      nc, get_nibble  ; No, get another character
 ;               call    nibble2val      ; Convert nibble to value
 ;               call    print_nibble
 ;               ret
;
; is_hex checks a character stored in A for being a valid hexadecimal digit.
; A valid hexadecimal digit is denoted by a set C flag.
;
;is_hex          cp      'F' + 1         ; Greater than 'F'?
;                ret     nc              ; Yes
;                cp      '0'             ; Less than '0'?
;                jr      nc, is_hex_1    ; No, continue
;                ccf                     ; Complement carry (i.e. clear it)
;                ret
;is_hex_1        cp      '9' + 1         ; Less or equal '9*?
;                ret     c               ; Yes
;                cp      'A'             ; Less than 'A'?
;                jr      nc, is_hex_2    ; No, continue
;                ccf                     ; Yes - clear carry and return
;                ret
;is_hex_2        scf                     ; Set carry
;                ret
;
; Convert a single character contained in A to upper case:
;
to_upper:        cp      'a'             ; Nothing to do if not lower case
                ret     c
                cp      'z' + 1         ; > 'z'?
                ret     nc              ; Nothing to do, either
                and     $5f             ; Convert to upper case
                ret
;
; Expects a hexadecimal digit (upper case!) in A and returns the
; corresponding value in A.
;
nibble2val:      cp      '9' + 1         ; Is it a digit (less or equal '9')?
                jr      c, nibble2val_1 ; Yes
                sub     7               ; Adjust for A-F
nibble2val_1:    sub     '0'             ; Fold back to 0..15
                and     $f              ; Only return lower 4 bits
                ret
;
; Print_nibble prints a single hex nibble which is contained in the lower 
; four bits of A:
;
;print_nibble    push    af              ; We won't destroy the contents of A
;                and     $f              ; Just in case...
;                add     a, '0'             ; If we have a digit we are done here.
;                cp      '9' + 1         ; Is the result > 9?
;                jr      c, print_nibble_1
;                add     a, 'A' - '0' - $a  ; Take care of A-F
;print_nibble_1  call    putc            ; Print the nibble and
;                pop     af              ; restore the original value of A
;                ret
;;
;; Send a CR/LF pair:
;
;crlf            push    af
;                ld      a, cr
;                call    putc
;                ld      a, lf
;                call    putc
;                pop     af
;                ret
;
; Print_word prints the four hex digits of a word to the serial line. The 
; word is expected to be in HL.
;
;print_word      push    hl
;                push    af
;                ld      a, h
;                call    print_byte
;                ld      a, l
;                call    print_byte
;                pop     af
;                pop     hl
;                ret
;
; Print_byte prints a single byte in hexadecimal notation to the serial line.
; The byte to be printed is expected to be in A.
;
;print_byte      push    af              ; Save the contents of the registers
;                push    bc
;                ld      b, a
;                rrca
;                rrca
;                rrca
;                rrca
;                call    print_nibble    ; Print high nibble
;                ld      a, b
;                call    print_nibble    ; Print low nibble
;                pop     bc              ; Restore original register contents
;                pop     af
;                ret





fourehexhl: 
	ld a,(hl)
	call atohex
		SRL A
		SRL A
		SRL A
		SRL A
	ld b, a
	inc hl
	ld a,(hl)
	inc hl
	call atohex
	add b
	ld d,a
	ld a,(hl)
	call atohex
		SRL A
		SRL A
		SRL A
		SRL A
	ld b, a
	inc hl
	ld a,(hl)
	inc hl
	call atohex
	add b
	ld e, a
	push de
	pop hl
	ret

; pass hl. returns z set if the byte at hl is a digit
;isdigithl: 
;	push bc
;	ld a,(hl)
;	cp ':'
;	jr nc, .isdf 		; >
;	cp '0'
;	jr c, .isdf		; <
;
;	; TODO find a better way to set z
;
;	ld b,a
;	cp b
;	pop bc
;	ret
;
;.isdf:	; not digit so clear z
;
;	; TODO find a better way to unset z
;
;	ld b,a
;	inc b
;	cp b
;
;	pop bc
;	ret
	
	


; pass hl as the four byte address to load

get_word_hl: 
	push hl
	call get_byte
	
	ld b, a

	pop hl
	inc hl
	inc hl

; TODO not able to handle a-f 
	ld a,(hl)
;	;cp ':'
;	cp 'g'
;	jr nc, .single_byte_hl 		; >
;	cp 'G'
;	jr nc, .single_byte_hl 		; >
;	cp '0'
;	jr c, .single_byte_hl		; <

	;call isdigithl
	cp 0
	jr z, .single_byte_hl

.getwhln:   ; hex word so get next byte

	call get_byte
	ld l, a
	ld h,b
	ret
.single_byte_hl:   ld l,b
		ld h,0
		ret




	ld hl,asc+1
;	ld a, (hl)
;	call nibble2val
	call get_byte

;	call fourehexhl
	ld (scratch+52),a
	
	ld hl,scratch+50
	ld (os_cur_ptr),hl

	ret


; from https://wikiti.brandonw.net/index.php?title=Z80_Routines:Other:DispA

; Decimal Unsigned Version

;Number in a to decimal ASCII
;adapted from 16 bit found in z80 Bits to 8 bit by Galandros
;Example: display a=56 as "056"
;input: a = number
;Output: a=0,value of a in the screen
;destroys af,bc (don't know about hl and de)
DispAToASCII:
	ld	c,-100
	call	.Na1
	ld	c,-10
	call	.Na1
	ld	c,-1
.Na1:	ld	b,'0'-1
.Na2:	inc	b
	add	a,c
	jr	c,.Na2
	sub	c		;works as add 100/10/1
	push af		;safer than ld c,a
	ld	a,b		;char is in b
;TODO	CALL	PUTCHAR	;plot a char. Replace with bcall(_PutC) or similar.
	pop af		;safer than ld a,c
	ret

; Decimal Signed Version

; DispA
; --------------------------------------------------------------
; Converts a signed integer value to a zero-terminated ASCII
; string representative of that value (using radix 10).
; --------------------------------------------------------------
; INPUTS:
;     HL     Value to convert (two's complement integer).
;     DE     Base address of string destination. (pointer).
; --------------------------------------------------------------
; OUTPUTS:
;     None
; --------------------------------------------------------------
; REGISTERS/MEMORY DESTROYED
; AF HL
; --------------------------------------------------------------

;DispHLToASCII:
;   push    de
;   push    bc
;
;; Detect sign of HL.
;    bit    7, h
;    jr     z, ._DoConvert
;
;; HL is negative. Output '-' to string and negate HL.
;    ld     a, '-'
;    ld     (de), a
;    inc    de
;
;; Negate HL (using two's complement)
;    xor    a
;    sub    l
;    ld     l, a
;    ld     a, 0     ; Note that XOR A or SUB A would disturb CF
;    sbc    a, h
;    ld     h, a
;
;; Convert HL to digit characters
;._DoConvert:
;    ld     b, 0     ; B will count character length of number
;-   ld     a, 10
;    syscall  .DivHLByA  ; HL = HL / A, A = remainder
;    push   af
;    inc    b
;    ld     a, h
;    or     l
;    jr     nz, -
;
;; Retrieve digits from stack
;-   pop    af
;    or     $30
;    ld     (de), a
;    inc    de
;    djnz   -
;
;; Terminate string with NULL
;    xor    a
;    ld     (de), a
;
;    pop    bc
;    pop    de
;    ret

;Comments
;
;    This routine uses the common positive-integer radix conversion algorithm of repeatedly dividing a value by the desired radix (base case: the value is zero) and saving the remainders of each division.
;    As this algorithm gives the digits in reverse order, they are pushed onto the hardware stack so that subsequently popping them yields the correct order.
;    Note that the output string will not be fixed-width.
;
;Example Usage
;
;    ld    hl, -1004
;    ld    de, OP1
;    call  DispA
;    ld    hl, OP1
;    syscall  PutS


; from https://github.com/Zeda/Z80-Optimized-Routines/blob/master/conversion/string_to_uint16.z80


;Converts an ASCII string to an unsigned 16-bit integer
;Quits when it reaches a non-decimal digit

string_to_uint16:
atoui_16:
;Input:
;     DE points to the string
;Outputs:
;     HL is the result
;     A is the 8-bit value of the number
;     DE points to the byte after the number
;Destroys:
;     BC
;       if the string is non-empty, BC is HL/10
;Size:  24 bytes
;Speed: 42+d(104+{0,9})
;       d is the number of digits in the number
;       max is 640 cycles for a 5 digit number
;Assuming no leading zeros:
;1 digit:  146cc
;2 digit:  250cc
;3 digit:  354cc or 363cc (avg: 354.126cc)
;4 digit:  458cc or 467cc (avg: 458.27cc)
;5 digit:  562cc or 571cc or 580cc (avg: 562.4104cc)
;avg: 544.81158447265625cc (544+13297/16384)
;===============================================================
  ld hl,0
.u16a:
  ld a,(de)
  sub 30h
  cp 10
  ret nc
  inc de
  ld b,h
  ld c,l
  add hl,hl
  add hl,hl
  add hl,bc
  add hl,hl
  add a,l
  ld l,a
  jr nc,.u16a
  inc h
  jp .u16a


; from https://github.com/Zeda/Z80-Optimized-Routines/blob/master/conversion/string_to_uint16.z80

;written by Zeda
;Converts a 16-bit unsigned integer to an ASCII string.

uitoa_16:
;Input:
;   DE is the number to convert
;   HL points to where to write the ASCII string (up to 6 bytes needed).
;Output:
;   HL points to the null-terminated ASCII string
;      NOTE: This isn't necessarily the same as the input HL.
  push de
  push bc
  push af
  ex de,hl

  ld bc,-10000
  ld a,'0'-1
  inc a
  add hl,bc 
   jr c,$-2
  ld (de),a
  inc de

  ld bc,1000
  ld a,'9'+1
  dec a 
  add hl,bc 
   jr nc,$-2
  ld (de),a
  inc de

  ld bc,-100
  ld a,'0'-1
  inc a 
  add hl,bc 
   jr c,$-2
  ld (de),a
  inc de

  ld a,l
  ld h,'9'+1
  dec h 
  add a,10 
   jr nc,$-3
  add a,'0'
  ex de,hl
  ld (hl),d
  inc hl
  ld (hl),a
  inc hl
  ld (hl),0

;Now strip the leading zeros
  ld c,-6
  add hl,bc
  ld a,'0'
  inc hl 
  cp (hl) 
  jr z,$-2

;Make sure that the string is non-empty!
  ld a,(hl)
  or a
  jr nz,.atoub
  dec hl
.atoub:

  pop af
  pop bc
  pop de
  ret

; from https://github.com/Zeda/Z80-Optimized-Routines/blob/master/conversion/toUpper.z80

toUpper:
;A is the char.
;If A is a lowercase letter, this sets it to the matching uppercase
;18cc or 30cc or 41cc
;avg: 26.75cc
  cp 'a'
  ret c
  cp 'z'+1
  ret nc
  sub 'a'-'A'
  ret

; https://tutorials.eeems.ca/ASMin28Days/lesson/day16.html#cmp

; String Length
;With a length-prefixed string, finding the length is trivial. For a null-terminated string, the process is decidedly more involved. This is where CPIR comes in.

; Get the length of the null-terminated string starting at $8000 hl
;    LD     HL, $8000

strlenz:

    XOR    A               ; Zero is the value we are looking for.
    LD     B, A             ; Since we haven't the slightest clue as to the 
    LD     C, A             ; actual size of the string, put 0 in BC to search
                           ; 65, 536 bytes (the entire addressable memory space).
    CPIR                   ; Begin search for a byte equalling zero.

; BC has been decremented so that it holds -length. Now need to synthesize a NEG BC.
    LD     H, A             ; Zero HL (basically set it to 65, 536) to get the
    LD     L, A             ; number of bytes
    SBC    HL, BC           ; Find the size. CPIR doesn't affect carry.
    DEC    HL              ; Compensate for null.
	ret

; Get the length of the A terminated string starting at $8000 hl
;    LD     HL, $8000

strlent:

                  ; A is the value we are looking for.
    LD     B, 0             ; Since we haven't the slightest clue as to the 
    LD     C, 0             ; actual size of the string, put 0 in BC to search
                           ; 65, 536 bytes (the entire addressable memory space).
    CPIR                   ; Begin search for a byte equalling zero.

; BC has been decremented so that it holds -length. Now need to synthesize a NEG BC.
    LD     H, 0             ; Zero HL (basically set it to 65, 536) to get the
    LD     L, 0             ; number of bytes
    SBC    HL, BC           ; Find the size. CPIR doesn't affect carry.
    DEC    HL              ; Compensate for null.
	ret


;Comparing Strings

;IN    HL     Address of string1.
;      DE     Address of string2.
;OUT   zero   Set if string1 = string2, reset if string1 != string2.
;      carry  Set if string1 > string2, reset if string1 <= string2.

strcmp:
    PUSH   HL
    PUSH   DE

    LD     A, (DE)          ; Compare lengths to determine smaller string
    CP     (HL)            ; (want to minimize work).
    JR     C, Str1IsBigger
    LD     A, (HL)

Str1IsBigger:
    LD     C, A             ; Put length in BC
    LD     B, 0
    INC    DE              ; Increment pointers to meat of string.
    INC    HL

CmpLoop:
    LD     A, (DE)          ; Compare bytes.
    CPI
    JR     NZ, NoMatch      ; If (HL) != (DE), abort.
    INC    DE              ; Update pointer.
    JP     PE, CmpLoop

    POP    DE
    POP    HL
    LD     A, (DE)          ; Check string lengths to see if really equal.
    CP     (HL)
    RET

NoMatch:
    DEC    HL
    CP     (HL)            ; Compare again to affect carry.
    POP    DE
    POP    HL
    RET


findchar:
	; HL string to search in 
	; A char to locate
	; B max string length to search

	; returns hl pointer to char
	; b contains position
	; if b or a are zero then not found
	push de
	push bc

.fc1:	ld e,(hl)
	cp e
	jr z,.fc2
	inc hl
	djnz .fc1

	pop bc
	pop de
	ld a, 0
	ld b, 0 
	ret
.fc2:
	ld e,b
	pop bc
	push af
	ld a,b
	sub e
	ld b, a
	pop af
	
	


	pop de
	ret

; eof






