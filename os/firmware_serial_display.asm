
; Serial display interface for SC114


display_row_1: equ 0
display_row_2: equ display_row_1+display_cols
display_row_3: equ display_row_2 + display_cols
display_row_4: equ display_row_3 + display_cols

kLCDWidth:  EQU display_cols             ;Width in characters
kLCD_Line1: EQU 0x00 
kLCD_Line2: EQU kLCD_Line1+kLCDWidth
; E1
kLCD_Line3: EQU kLCD_Line2+kLCDWidth
kLCD_Line4: EQU kLCD_Line3+kLCDWidth 

lcd_init:
	; no init as handled by the SCM bios
	ret


; low level functions for direct screen writes

; output char at pos?
fLCD_Str:
        ;out (SC114_SIO_1_OUT),a
	push bc
	ld c, $02
	rst $30
	pop bc
	ret

; position the cursor on the screen using A as realtive point in screen buffer (i.e. A=(x+(width/y)))
fLCD_Pos:
	; use ASCII escape to position
        ;out (SC114_SIO_1_OUT),a
	push bc
	ld c, $02
	rst $30
	pop bc

	ret

; output char at pos
fLCD_Data:
      ;  out (SC114_SIO_1_OUT),a
	push bc
	ld c, $02
	rst $30
	pop bc

	ret

; ascii cls 

.cls:   db 27, '[', 'H', 0

; write the frame buffer given in hl to hardware 
write_display:

API: equ 0

if API
	push bc
	ld b, 4

        ld (display_write_tmp), hl 	 

	; clear and home cursor

	ld c, 6
	ld de, .cls
	rst $30


.writeln:

	ld de, (display_write_tmp)
	ld c, 6
	rst $30
	ld c, 7
	rst $30

	ld hl, (display_write_tmp)
	ld de, display_cols
	add hl,de
	ld (display_write_tmp),hl

	djnz  .writeln

	pop bc


	ret
endif
	push hl
	push bc
	push de

;	ld c, 2
;	;ld de, .cls
;	ld a, 27
;	rst $30
;	ld c, 2
;	;ld de, .cls
;	ld a, '['
;	rst $30
;
;	ld c, 2
;	;ld de, .cls
;	ld a, 'H'
;	rst $30
;

	ld c, 2
	;ld de, .cls
	ld a, 27
	rst $30


	ld c, 2
	;ld de, .cls
	ld a, '['
	rst $30
	ld c, 2
	;ld de, .cls
	ld a, '2'
	rst $30
	ld c, 2
	;ld de, .cls
	ld a, 'J'
	rst $30
	pop de
	pop bc
	pop hl


        ld (display_write_tmp), hl 	 
	ld a, kLCD_Line1
        ;    CALL fLCD_Pos       ;Position cursor to location in A
	ld b, display_cols
	ld de, (display_write_tmp)
	call write_len_string
	

push hl
push de
push bc
	ld c, 7
	rst $30
pop bc
pop de
pop hl

	
	ld hl, (display_write_tmp)
	ld de, display_cols
	add hl,de
	ld (display_write_tmp),hl

	
	ld a, kLCD_Line2
        ;    CALL fLCD_Pos       ;Position cursor to location in A
	ld b, display_cols
	ld de, (display_write_tmp)
	call write_len_string
	
	ld hl, (display_write_tmp)
	ld de, display_cols
	add hl,de
	ld (display_write_tmp),hl

push hl
push de
push bc
	ld c, 7
	rst $30
pop bc
pop de
pop hl

	
	ld a, kLCD_Line3
         ;   CALL fLCD_Pos       ;Position cursor to location in A
	ld b, display_cols
	ld de, (display_write_tmp)
	call write_len_string
	
	ld hl, (display_write_tmp)
	ld de, display_cols
	add hl,de
	ld (display_write_tmp),hl

push hl
push de
push bc
	ld c, 7
	rst $30
pop bc
pop de
pop hl

	
	ld a, kLCD_Line4
          ;  CALL fLCD_Pos       ;Position cursor to location in A
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


; eof
