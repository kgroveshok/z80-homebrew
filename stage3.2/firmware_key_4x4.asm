
DEBUG_KEY: equ 1

; bit mask for each scan column and row for testing the matrix

; out 
key_row_bitmask:    db 128, 64, 32, 16
; in
key_col_bitmask:    db 1, 2, 4, 8

; row/col to character map

; char, state use   123xxsss   - bit 8,7,6 this key selects specified state, s is this key is member of that state
;  

; physical key matrix map to face of key

key_map_face: 
		db '1'
		db '2'
		db '3'
		db 'A'

		db '4'
		db '5'
		db '6'
		db 'B'

		db '7'
		db '8'
		db '9'
		db 'C'

		db '*'
		db '0'
		db '#'
		db 'D'

; map the physical key to a char dependant on state

key_map: 
		db '1',000000000b
		db '2',000000000b
		db '3',000000000b
		db 'A',000000000b

		db '4',000000000b
		db '5',000000000b
		db '6',000000000b
		db 'B',000000000b
		db '7',000000000b
		db '8',000000000b
		db '9',000000000b
		db 'C',000000000b
		db '*',010000000b
		db '0',000000000b
		db '#',000000000b
		db 'D',000000000b

		db 0,000000000b


		db 'a',000000010b
		db 'b',000000010b
		db 'c',000000010b
		db 'd',000000010b
		db 'e',000000010b
		db 'f',000000010b
		db 'g',000000010b
		db 'h',000000010b
		db 'i',000000010b
		db 'j',000000010b
		db 'k',000000010b
		db 'l',000000010b
		db '*',010000010b
		db 'm',000000010b
		db '#',00000100b
		db 'n',000000010b


key_init:

; SCMonAPI functions used

; Alphanumeric LCD functions used
; no need to specify specific functions for this module


            LD   A, 11001111b
            OUT  (portbctl), A  ;Port A = PIO 'control' mode
            LD   A, 00000000b
            LD   A, 00001111b
            OUT  (portbctl),A   ;Port A = all lines are outputs

	ret

; keyboard scanning 


; key_rows: equ 4
; key_cols: equ 4
; keyscan_table: edu ( tos-stacksize-(key_rows*key_cols))

; key_scanr: equ key_row_bitmask
; key_scanc: equ key_col_bitmask

; key_char_map: equ key_map



; character in from keyboard
; TODO add the key modifier state to what cin returns

matrix_to_char: db "D#0*C987B654A321"

cin: 	

; scan keyboard row 1
	ld a, 128
	ld hl, keyscan_table
	call rowscan

	ld a, 64
	ld hl, keyscan_table+key_cols
	call rowscan

	ld a, 32
	ld hl, keyscan_table+(key_cols*2)
	call rowscan

	ld a, 16
	ld hl, keyscan_table+(key_cols*3)
	call rowscan

if DEBUG_KEY
            LD   A, kLCD_Line4
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, keyscan_table
            CALL fLCD_Str       ;Display string pointed to by DE
endif

	; scan key matrix table for any held key

	ld hl, keyscan_table
	ld de, matrix_to_char
	ld b,key_cols*key_rows

cin1:	ld a,(hl)
	cp '#'
	jr z, cinhit
	inc hl
	inc de
	dec b
	jr nz, cin1
	; no key found held
	ld a,0
	ret
cinhit: push de
	pop hl
	ld a,(hl)
	ret

	
	










	ret

;	push hl
;	push de
;	push bc
;	call keyscan
;	; map key matrix to ascii value of key face
;
;	ld hl, key_face_map
;	ld de, keyscan_table
;
;	; get how many keys to look at
;	ld b, keyscan_table_len
;	
;
;	; at this stage fall out on first key hit
;	; TODO handle multiple key press
;
;map1:	ld a,(hl)
;	cp '#'
;	jr z, keyhit
;	inc hl
;	inc de
;	dec b
;	jr nz, map1
;nohit:	ld a, 0
;	jr keydone
;keyhit: push de
;	pop hl
;	ld a,(hl)
;keydone:
;	push bc
;	push de
; 	push hl
;	ret 
;

; send character to current cursor position
; wraps and/or scrolls screen automatically

cout: 
	ret





; scan physical key matrix


;keyscan:
;
;; for each key_row use keyscanr bit mask for out
;; then read in for keyscanc bitmask
;; save result of row scan to keyscantable
;
;; scan keyboard row 1
;
;	ld b, key_rows
;	ld hl, key_scanr
;	ld de, keyscan_table
;
;rowloop:
;
;	ld a,(hl)		; out bit mask to energise keyboard row
;	call rowscan
;	inc hl
;	dec b
;	jr nz, rowloop
;
;	ret
;
;
;; pass a out bitmask, b row number
;arowscan: 
;	push bc
;
;	ld d, b
;
;	; calculate buffer location for this row
;
;	ld hl, keyscan_table	
;kbufr:  ld e, key_cols
;kbufc:	inc hl
;	dec e
;	jr nz, kbufc
;	dec d
;	jr nz, kbufr
;
;	; energise row and read columns
;
;	out (portbdata),a
;	in a,(portbdata)
;	ld c,a
;
;
;	; save buffer loc
;
;	ld (keybufptr), hl
;
;	ld hl, key_scanc
;	ld d, key_cols
;
;	; for each column check each bit mask
;
;colloop:
;	
;
;	; reset flags for the row 
;
;	ld b,'.'
;	and (hl)
;	jr z, maskskip
;	ld b,'#'
;maskskip:
;	; save  key state
;	push hl
;	ld hl, (keybufptr)
;	ld (hl), b
;	inc hl
;	ld (keybufptr), hl
;
;	; move to next bit mask
;	pop hl
;	inc hl
;
;	dec d
;	jr nz, colloop
;
;	ret
;
;
;;
; lcd functions
;
;

; test function to display hardware view of matrix state

matrix:


; Display text on second line
;            LD   A, kLCD_Line3
;            CALL fLCD_Pos       ;Position cursor to location in A
;            LD   DE, scanline3
;            CALL fLCD_Str       ;Display string pointed to by DE

; Display text on second line
;            LD   A, kLCD_Line4
;            CALL fLCD_Pos       ;Position cursor to location in A
;            LD   DE, scanline4
;            CALL fLCD_Str       ;Display string pointed to by DE

; Define custom character(s)
;            LD   A, 0           ;First character to define (0 to 7)
;            LD   DE, BitMaps    ;Pointer to start of bitmap data
;            LD   B, 2           ;Number of characters to define
;DefLoop:   CALL fLCD_Def       ;Define custom character
;            DJNZ DefLoop       ;Repeat for each character


; Display custom character 0
;            LD   A, kLCD_Line1+14
;            CALL fLCD_Pos       ;Position cursor to location in A
;            LD   A, 0
;            CALL fLCD_Data      ;Write character in A at cursor

; Display custom character 1
;            LD   A, kLCD_Line2+14
;            CALL fLCD_Pos      ;Position cursor to location in A
;            LD   A, 1
;            CALL fLCD_Data     ;Write character in A at cursor


;	    ld a, 128
;		out (portbdata),a
;		call delay1s
;            LD   A, kLCD_Line1
;            CALL fLCD_Pos       ;Position cursor to location in A
;            LD   DE, scanline1
;            CALL fLCD_Str       ;Display string pointed to by DE
;	    ld a, 64
;out (portbdata),a
;		call delay1s
;
;            LD   A, kLCD_Line2
;            CALL fLCD_Pos       ;Position cursor to location in A
;            LD   DE, yes
;		in a, (portbdata)
;;		ld a, 0
;		bit 0 ,a
;		jr nz, s1
;		ld de, no			
;s1:            CALL fLCD_Str       ;Display string pointed to by DE
;;
;	jp keyscan
;		halt		


; config port b all outputs and add an led to any pin on port b and flash it


; scan keyboard row 1
	ld a, 128
	ld hl, keyscan_table_row1
	call rowscan

	ld a, 64
	ld hl, keyscan_table_row2
	call rowscan

	ld a, 32
	ld hl, keyscan_table_row3
	call rowscan

	ld a, 16
	ld hl, keyscan_table_row4
	call rowscan

; Display text on first line
            LD   A, kLCD_Line1
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, keyscan_table_row1
            ;LD   DE, MsgHello
            CALL fLCD_Str       ;Display string pointed to by DE

; Display text on second line
            LD   A, kLCD_Line2
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, keyscan_table_row2
            CALL fLCD_Str       ;Display string pointed to by DE
            LD   A, kLCD_Line3
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, keyscan_table_row3
            CALL fLCD_Str       ;Display string pointed to by DE
            LD   A, kLCD_Line4
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, keyscan_table_row4
            CALL fLCD_Str       ;Display string pointed to by DE

;	call delay1s
	call delay250ms
	jp matrix

; pass de as row display flags
rowscan: 
	out (portbdata),a
	in a,(portbdata)
	ld c,a
	; reset flags for the row 
	ld b,'.'
	and 1
	jr z, p1on
	ld b,'#'
p1on:
	ld (hl), b
	inc hl

	ld b,'.'
	ld a,c
	and 2
;	bit 0,a
	jr z, p2on
	ld b,'#'
p2on:
	ld (hl), b
	inc hl
;
	ld b,'.'
	ld a,c
	and 4
;;	bit 0,a
	jr z, p3on
	ld b,'#'
p3on:
	ld (hl), b
	inc hl
;;
	ld b,'.'
;;	bit 0,a
	ld a,c
	and 8
	jr z, p4on
	ld b,'#'
p4on:
	ld (hl), b
	inc hl

; zero term
	ld b,0
	ld (hl), b

rscandone: ret
