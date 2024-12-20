

; bit mask for each scan column and row for teing the matrix

; out 
key_row_bitmask:    db 128, 64, 32, 16
; in
key_col_bitmask:    db 1, 2, 4, 8

; row/col to character map

; char, state use   123xxsss   - bit 8,7,6 this key selects specified state, s is this key is member of that state
;  

; physical key matrix map to face of key


;      	1	2	3	A
;   	abc”	def&	ghi$	s1
;			
;	4	5	6	B
; 	jkl,	mno.	pqr:	s2
;			
; 	7	8	9	C
;	stu;	vwx@	yz?!	s3
;			
; 	*	0	#	D
; 	shift lck '	Space < >	Enter ( )	s4
;       tab bs 		




key_init:

; SCMonAPI functions used

; Alphanumeric LCD functions used
; no need to specify specific functions for this module


            LD   A, 11001111b
            OUT  (portbctl), A  ;Port A = PIO 'control' mode
;            LD   A, 00000000b
            LD   A, 00001111b
            OUT  (portbctl),A   ;Port A = all lines are outputs


	; TODO Configure cursor shapes

	; Load cursor shapes 
            LD   A, 1           ;First character to define (0 to 7)
            LD   DE, .cursor_shapes    ;Pointer to start of bitmap data
            LD   B, 2           ;Number of characters to define
.DefLoop:   CALL fLCD_Def       ;Define custom character
            DJNZ .DefLoop       ;Repeat for each character

		ld a, 1
	ld (cursor_shape),a
	ret

; Custom characters for cursor shapes 5 pixels wide by 8 pixels high
; Up to 8 custom characters can be defined
.cursor_shapes:    
;; Character 0x00 = Normal
            DB  11111b
            DB  11111b
            DB  11111b
            DB  11111b
            DB  11111b
            DB  11111b
            DB  11111b
            DB  11111b
;; Character 0x01 = Modifier
            DB  11111b
            DB  11011b
            DB  11011b
            DB  11011b
            DB  11011b
            DB  11111b
            DB  11011b
            DB  11111b




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

; keyboard scanning 


; key_rows: equ 4
; key_cols: equ 4
; keyscan_table: edu ( tos-stacksize-(key_rows*key_cols))

; key_scanr: equ key_row_bitmask
; key_scanc: equ key_col_bitmask

; key_char_map: equ key_map



; character in from keyboard

.matrix_to_char: db "D#0*C987B654A321"


; map the physical key to a char dependant on state

.key_map_fa: 

		db 'D'
		db KEY_CR    ; cr
		db ' '
		db  KEY_SHIFTLOCK   ; TODO Shift lock
		db 'C'
		db 'y'
		db 'v'
		db 's'
		db 'B'
		db 'p'
		db 'm'
		db 'j'
		db 'A'
		db 'g'
		db 'd'
		db 'a'

.key_map_fb:

		db 'A'
		db '+' 
		db '<'
		db  "'"  

		db 'A'
		db 'z'
		db 'w'
		db 't'
		db 'A'
		db 'q'
		db 'n'
		db 'k'
		db 'A'
		db 'h'
		db 'e'
 		db 'b'

.key_map_fc: 


		db 'A'
		db '-' 
		db '>'
		db  '='   	
		db 'A'
		db '?'
		db 'x'
		db 'u'
		db 'A'
		db 'r'
		db 'o'
		db 'l'
		db 'A'
		db 'i'
		db 'f'
		db 'c'

	
.key_map_fd:

		db 'A'
		db '/' 
		db '%' 
		db KEY_BS  ; back space
		db 'A'
		db '!'
		db '@'
		db ';'
		db 'A'
		db ':'
		db '.'
		db ','
		db 'A'
		db '$'
		db '&'
	 	db '"'

		
	

; add cin and cin_wait

cin_wait: 	call cin
	cp 0
	jr z, cin_wait   ; block until key press

	push af   ; save key pressed

.cin_wait1:	call cin
	cp 0
	jr nz, .cin_wait1  	; wait for key release

	pop af   ; get key
	ret


cin: 	call .mtoc

	; no key held
	cp 0
	ret z

	; stop key bounce

;	ld (key_held),a		 ; save it
	ld b, a

.cina1:	push bc
	call .mtoc
	pop bc
	cp b
	jr z, .cina1
	ld a,b		
	ret

; detect keyboard modifier key press and apply new overlay to the face key held
; hl is the key modifer flag, de map to apply to key_face_held and store in key_actual_pressed

;.cin_map_modifier: 
;	ld a, (hl)
;	and 255
;	ret NZ		; modifier key not flagged
;
;	; get key face
;
;	ld b,(key_face_held)
;
;	ld b, key_cols * key_rows
;
;	push de
;	pop hl
;
;.mmod1: ld a,(hl)   ; get map test
;	cp b
;	jr z, .mmod2
;
;
;
;.mmod2: inc hl    ; 
;
;	
;
;	
;
;	ld hl,key_actual_pressed
;	ld (hl),a,
;	ret

	

; map matrix key held to char on face of key

.mtoc:


	; TODO optimise the code....

; scan keyboard row 1
	ld a, 128
	ld hl, keyscan_table
	call .rowscan

	 

	ld a, 64
	ld hl, keyscan_table+key_cols
	call .rowscan




	ld a, 32
	ld hl, keyscan_table+(key_cols*2)
	call .rowscan



	ld a, 16
	ld hl, keyscan_table+(key_cols*3)
	call .rowscan


	; flag if key D is held down and remove from reporting
	ld bc, .key_map_fd  
	ld hl, keyscan_table
	ld de, key_fd
	call .key_shift_hold
	cp 255
	jr z, .cinmap
	; flag if key C is held down and remove from reporting
	ld bc, .key_map_fc  
	ld hl, keyscan_table+key_cols
	ld de, key_fc
	call .key_shift_hold
	cp 255
	jr z, .cinmap
	; flag if key B is held down and remove from reporting
	ld bc, .key_map_fb  
	ld hl, keyscan_table+(key_cols*2)
	ld de, key_fb
	call .key_shift_hold
	cp 255
	jr z, .cinmap
	; flag if key A is held down and remove from reporting
	ld bc, .key_map_fa  
	ld hl, keyscan_table+(key_cols*3)
	ld de, key_fa
	call .key_shift_hold
	cp 255
	jr z, .cinmap

	ld de, .matrix_to_char


.cinmap: 
	if DEBUG_KEY
            LD   A, kLCD_Line4
            CALL fLCD_Pos       ;Position cursor to location in A
		push de
            LD   DE, keyscan_table
            CALL fLCD_Str       ;Display string pointed to by DE
		pop de
	endif

	; scan key matrix table for any held key

	; de holds either the default matrix or one selected above

	ld hl, keyscan_table
	ld b,key_cols*key_rows

.cin1:	ld a,(hl)
	cp '#'
	jr z, .cinhit
	inc hl
	inc de
	dec b
	jr nz, .cin1
	; no key found held
	ld a,0
	ret
.cinhit: push de
	pop hl
	ld a,(hl)
	ret

; flag a control key is held 
; hl is key pin, de is flag indicator

.key_shift_hold:
	push bc
	ld a, 1
	ld (cursor_shape),a
	ld b, 0
	ld a, (hl)
	cp '.'
	jr z, .key_shift1
	ld b, 255
	ld a, '+'    ; hide key from later scans
	ld (hl),a
	ld a, 2
	ld (cursor_shape),a
.key_shift1:
	; write flag indicator
	ld a,b
	ld (de),a

	pop de    ; de now holds the key map ptr
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

;if DEBUG_KEY_MATRIX

; test function to display hardware view of matrix state

matrix:



; scan keyboard row 1
	ld a, 128
	ld hl, keyscan_table_row1
	call .rowscan

	ld a, 64
	ld hl, keyscan_table_row2
	call .rowscan

	ld a, 32
	ld hl, keyscan_table_row3
	call .rowscan

	ld a, 16
	ld hl, keyscan_table_row4
	call .rowscan

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

	call delay250ms
	jp matrix

; pass de as row display flags
.rowscan: 
	out (portbdata),a
	in a,(portbdata)
	ld c,a
	; reset flags for the row 
	ld b,'.'
	and 1
	jr z, .p1on
	ld b,'#'
.p1on:
	ld (hl), b
	inc hl

	ld b,'.'
	ld a,c
	and 2
;	bit 0,a
	jr z, .p2on
	ld b,'#'
.p2on:
	ld (hl), b
	inc hl
;
	ld b,'.'
	ld a,c
	and 4
;;	bit 0,a
	jr z, .p3on
	ld b,'#'
.p3on:
	ld (hl), b
	inc hl
;;
	ld b,'.'
;;	bit 0,a
	ld a,c
	and 8
	jr z, .p4on
	ld b,'#'
.p4on:
	ld (hl), b
	inc hl

; zero term
	ld b,0
	ld (hl), b

.rscandone: ret



;endif


; eof
