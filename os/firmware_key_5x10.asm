; 5 x 10 decade counter scanner


; TODO do cursor shape change for shift keys
; TODO rows are round the wrong way for the pin sequence on the header. Reverse the row mappings
; TODO hard coded positions for the shift keys. Change to work like 4x4 and detect and then hide them


; bit mask for each scan column and row for teing the matrix


key_init:

; SCMonAPI functions used

; Alphanumeric LCD functions used
; no need to specify specific functions for this module


            LD   A, 11001111b
            OUT  (portbctl), A  ;Port A = PIO 'control' mode
;            LD   A, 00000000b
            LD   A, 00011111b
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

;.matrix_to_char: db "1234567890qwertyuiopasdfghjkl_+zxcvbnm,."
.matrix_to_char:
		db KEY_SHIFT,"zxcv",KEY_UP,KEY_DOWN,"m",KEY_LEFT, KEY_RIGHT,0
		db KEY_SHIFT,"zxcvbnm ",KEY_SYMBOLSHIFT,0
		db "asdfghjkl",KEY_CR,0
		db "qwertyuiop",0
		 db "1234567890",0
.matrix_to_shift:
		db KEY_SHIFT,"zxcv",KEY_UP,KEY_DOWN,"m",KEY_HOME, KEY_END,0
		db KEY_SHIFT,"ZXCVBNM",KEY_BS,KEY_SYMBOLSHIFT,0
		db "ASDFGHJKL",KEY_CR,0
		db "QWERTYUIOP",0
		 db "!",'"',"#$%^&*()",0
.matrix_to_symbolshift:
		db KEY_SHIFT,"zxcv",KEY_UP,KEY_DOWN,"m",KEY_LEFT, KEY_RIGHT,0
		db KEY_SHIFT,"<>:;b,.",KEY_BS,KEY_SYMBOLSHIFT,0
		db "_?*fghjk=",KEY_CR,0
		db "-/+*[]{}@#",0
		 db "1234567890",0
;.matrix_to_char: db "D#0*C987B654A321"


; map the physical key to a char dependant on state

;.key_map_fa: 
;
;		db 'D'
;		db KEY_CR    ; cr
;		db ' '
;		db  KEY_SHIFTLOCK   ; TODO Shift lock
;		db 'C'
;		db 'y'
;		db 'v'
;		db 's'
;		db 'B'
;		db 'p'
;		db 'm'
;		db 'j'
;		db 'A'
;		db 'g'
;		db 'd'
;		db 'a'
;
;.key_map_fb:
;
;		db 'A'
;		db '+' 
;		db '<'
;		db  "'"  
;
;		db 'A'
;		db 'z'
;		db 'w'
;		db 't'
;		db 'A'
;		db 'q'
;		db 'n'
;		db 'k'
;		db 'A'
;		db 'h'
;		db 'e'
 ;		db 'b'
;
;.key_map_fc: 
;
;
;		db 'A'
;		db '-' 
;		db '>'
;		db  '='   	
;		db 'A'
;		db '?'
;		db 'x'
;		db 'u'
;		db 'A'
;		db 'r'
;		db 'o'
;		db 'l'
;		db 'A'
;		db 'i'
;		db 'f'
;		db 'c'
;
;	
;.key_map_fd:
;
;		db 'A'
;		db '/' 
;		db '%' 
;		db KEY_BS  ; back space
;		db 'A'
;		db '!'
;		db '@'
;		db ';'
;		db 'A'
;		db ':'
;		db '.'
;		db ','
;		db 'A'
;		db '$'
;		db '&'
;	 	db '"'

		
	

; add cin and cin_wait

cin_wait: 	call cin
			if DEBUG_KEYCINWAIT
				push af
				
				ld hl,key_repeat_ct
				ld (hl),a
				inc hl
				call hexout
				ld hl,key_repeat_ct+3
				ld a,0
				ld (hl),a

				    LD   A, kLCD_Line1+11
				    CALL fLCD_Pos       ;Position cursor to location in A
				    LD   DE, key_repeat_ct
				    ;LD   DE, MsgHello
				    CALL fLCD_Str       ;Display string pointed to by DE



				pop af
			endif
	cp 0
	jr z, cin_wait   ; block until key press

				if DEBUG_KEYCINWAIT
					push af

					ld a, 'A'	
					ld hl,key_repeat_ct
					ld (hl),a
					inc hl
					ld a,0
					ld (hl),a

					    LD   A, kLCD_Line2+11
					    CALL fLCD_Pos       ;Position cursor to location in A
					    LD   DE, key_repeat_ct
					    ;LD   DE, MsgHello
					    CALL fLCD_Str       ;Display string pointed to by DE

				call delay500ms

					pop af
				endif
	push af   ; save key pressed

.cin_wait1:	
				if DEBUG_KEYCINWAIT
					push af

					ld a, 'b'	
					ld hl,key_repeat_ct
					ld (hl),a
					inc hl
					ld a,0
					ld (hl),a

					    LD   A, kLCD_Line2+11
					    CALL fLCD_Pos       ;Position cursor to location in A
					    LD   DE, key_repeat_ct
					    ;LD   DE, MsgHello
					    CALL fLCD_Str       ;Display string pointed to by DE


				call delay500ms

					pop af
				endif

call cin
	cp 0
	jr nz, .cin_wait1  	; wait for key release
if DEBUG_KEYCINWAIT
	push af

	ld a, '3'	
	ld hl,key_repeat_ct
	ld (hl),a
	inc hl
	ld a,0
	ld (hl),a

            LD   A, kLCD_Line2+11
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, key_repeat_ct
            ;LD   DE, MsgHello
            CALL fLCD_Str       ;Display string pointed to by DE


call delay500ms

	pop af
endif

	pop af   ; get key
	ret


cin: 	call .mtoc

if DEBUG_KEYCIN
	push af
	
	ld hl,key_repeat_ct
	ld (hl),a
	inc hl
	call hexout
	ld hl,key_repeat_ct+3
	ld a,0
	ld (hl),a

            LD   A, kLCD_Line3+15
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, key_repeat_ct
            ;LD   DE, MsgHello
            CALL fLCD_Str       ;Display string pointed to by DE


call delay500ms

	pop af
endif


	; no key held
	cp 0
	ret z

if DEBUG_KEYCIN
	push af

	ld a, '1'	
	ld hl,key_repeat_ct
	ld (hl),a
	inc hl
	ld a,0
	ld (hl),a

            LD   A, kLCD_Line4+15
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, key_repeat_ct
            ;LD   DE, MsgHello
            CALL fLCD_Str       ;Display string pointed to by DE


call delay500ms

	pop af
endif

	; stop key bounce

	ld (key_held),a		 ; save it
	ld b, a

.cina1:	push bc
if DEBUG_KEYCIN
	push af

	ld hl,key_repeat_ct
	inc hl
	call hexout
	ld hl,key_repeat_ct+3
	ld a,0
	ld (hl),a
	ld hl,key_repeat_ct
	ld a, '2'	
	ld (hl),a

            LD   A, kLCD_Line4+15
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, key_repeat_ct
            ;LD   DE, MsgHello
            CALL fLCD_Str       ;Display string pointed to by DE

	pop af
endif
	call .mtoc
	pop bc
	cp b
	jr z, .cina1
	ld a,b		
if DEBUG_KEYCIN
	push af

	ld hl,key_repeat_ct
	inc hl
	call hexout
	ld hl,key_repeat_ct+3
	ld a,0
	ld (hl),a
	ld hl,key_repeat_ct
	ld a, '3'	
	ld (hl),a

            LD   A, kLCD_Line4+15
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, key_repeat_ct
            ;LD   DE, MsgHello
            CALL fLCD_Str       ;Display string pointed to by DE

	pop af
endif
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

; test decade counter strobes

;.decadetest1:

; reset counter
;ld a, 128
;out (portbdata),a


;ld b, 5
;.dec1:
;ld a, 0
;out (portbdata),a
;call delay1s

;ld a, 32
;out (portbdata),a
;call delay1s
;call delay1s
;call delay1s
;
;ld a, 64+32
;out (portbdata),a
;call delay1s
;;djnz .dec1
;
;jp .decadetest1










	; scan keyboard matrix and generate raw scan map
	call matrix

	; reuse c bit 0 left modifer button - ie shift
        ; reuse c bit 1 for right modifer button - ie symbol shift
	; both can be used with their other mappings and if seen together can do extra mappings (forth keywords????)

	ld c, 0

	; TODO set flags for modifer key presses 
	; TODO do a search for modifer key...

	ld hl,keyscan_table_row5

	ld a, (hl)
	cp '#'
	jr nz, .nextmodcheck
	set 0, c
	ld hl, .matrix_to_shift
	jr .dokeymap
	; TODO for now igonre
.nextmodcheck:
	ld hl,keyscan_table_row5+9

	ld a, (hl)
	cp '#'
	jr nz, .donemodcheck
	set 1, c 
	ld hl, .matrix_to_symbolshift
	jr .dokeymap
.donemodcheck:
	; no modifer found so just map to normal keys
	; get mtoc map matrix to respective keys
	ld hl, .matrix_to_char

.dokeymap:
	;ld (key_fa), c 
	call .mapkeys


if DEBUG_KEY

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
            LD   A, kLCD_Line1+10
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, keyscan_table_row5
            CALL fLCD_Str       ;Display string pointed to by DE

	;call delay250ms
endif
;	jp testkey

; get first char reported

	ld hl,keyscan_table_row5

	;ld b, 46   ; 30 keys to remap + 8 nulls 
	ld b, ((key_cols+1)*key_rows)    ; 30 keys to remap + 8 nulls 
.findkey:
	ld a,(hl)
	cp 0
	jr z, .nextkey
	cp KEY_MATRIX_NO_PRESS
	jr nz, .foundkey
.nextkey:
	inc hl
	djnz .findkey
	ld a,0
	ret
.foundkey:
	ld a,(hl)
	ret
	

; convert the raw key map given hl for destination key
.mapkeys:
	ld de,keyscan_table_row5

	ld b, ((key_cols+1)*key_rows)    ; 30 keys to remap + 8 nulls 
.remap:
	ld a,(de)
	cp '#'
	jr nz, .remapnext
	;CALLMONITOR
	ld a,(hl)
	ld (de),a



.remapnext:
	inc hl
	inc de
	djnz .remap
	
	ret



.mtocold2:

;	; flag if key D is held down and remove from reporting
;	ld bc, .key_map_fd  
;	ld hl, keyscan_table
;	ld de, key_fd
;	call .key_shift_hold
;	cp 255
;	jr z, .cinmap
;	; flag if key C is held down and remove from reporting
;	ld bc, .key_map_fc  
;	ld hl, keyscan_table+key_cols
;	ld de, key_fc
;	call .key_shift_hold
;	cp 255
;	jr z, .cinmap
;	; flag if key B is held down and remove from reporting
;	ld bc, .key_map_fb  
;	ld hl, keyscan_table+(key_cols*2)
;	ld de, key_fb
;	call .key_shift_hold
;	cp 255
;	jr z, .cinmap
;	; flag if key A is held down and remove from reporting
;	ld bc, .key_map_fa  
;	ld hl, keyscan_table+(key_cols*3)
;	ld de, key_fa
;	call .key_shift_hold
;	cp 255
;	jr z, .cinmap

	ld de, .matrix_to_char


.cinmap1: 
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

.cin11:	ld a,(hl)
	cp '#'
	jr z, .cinhit1
	inc hl
	inc de
	dec b
	jr nz, .cin11
	; no key found held
	ld a,0
	ret
.cinhit1: push de
	pop hl
	ld a,(hl)
	ret

; flag a control key is held 
; hl is key pin, de is flag indicator

.key_shift_hold1:
	push bc
	ld a, 1
	ld (cursor_shape),a
	ld b, 0
	ld a, (hl)
	cp '.'
	jr z, .key_shift11
	ld b, 255
	ld a, '+'    ; hide key from later scans
	ld (hl),a
	ld a, 2
	ld (cursor_shape),a
.key_shift11:
	; write flag indicator
	ld a,b
	ld (de),a

	pop de    ; de now holds the key map ptr
	ret

	

; scans keyboard matrix and flags key press in memory array	
	
matrix:
	;call matrix
	; TODO optimise the code....


;ld hl, keyscan_table_row1
;ld de, keyscan_table_row1+1
;ld bc,46
;ld a,KEY_MATRIX_NO_PRESS
;ldir



; reset counter
ld a, 128
out (portbdata),a

ld b, 10
ld c, 0       ; current clock toggle

.colscan:

; set current column
; disable clock enable and set clock low

;ld a, 0
;out (portbdata),a

; For each column scan for switches

push bc
ld hl, keyscan_scancol
call .rowscan
pop bc


; get back current column

; translate the row scan

; 
; row 1

ld a,b

LD   hl, keyscan_table_row1+10

call subafromhl
;call addatohl

ld de, keyscan_scancol

ld a,(de)
ld (hl),a




; row 2

ld a,b

LD   hl, keyscan_table_row2+10

;call addatohl
call subafromhl


ld de, keyscan_scancol+1

ld a,(de)
ld (hl),a


; row 3

ld a,b

LD   hl, keyscan_table_row3+10

;call addatohl
call subafromhl

ld de, keyscan_scancol+2

ld a,(de)
ld (hl),a



; row 4

ld a,b

LD   hl, keyscan_table_row4+10

;call addatohl
call subafromhl

ld de, keyscan_scancol+3

ld a,(de)
ld (hl),a

; row 5

ld a,b

LD   hl, keyscan_table_row5+10

;call addatohl
call subafromhl

ld de, keyscan_scancol+4

ld a,(de)
ld (hl),a

; handshake next column


ld a, 64
out (portbdata),a

ld a, 0
out (portbdata),a

; toggle clk and move to next column
;ld a, 64
;cp c
;
;jr z, .coltoglow
;ld c, a
;jr .coltog
;.coltoglow:
;ld c, 0
;.coltog:
;ld a, c
;out (portbdata),a

djnz .colscan

ld a,10
LD   hl, keyscan_table_row1
call addatohl
ld a, 0
ld (hl), a


ld a,10
LD   hl, keyscan_table_row2
call addatohl
ld a, 0
ld (hl), a

ld a,10
LD   hl, keyscan_table_row3
call addatohl
ld a, 0
ld (hl), a

ld a,10
LD   hl, keyscan_table_row4
call addatohl
ld a, 0
ld (hl), a

ld a,10
LD   hl, keyscan_table_row5
call addatohl
ld a, 0
ld (hl), a

if DEBUG_KEY_MATRIX

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
            LD   A, kLCD_Line4+10
            CALL fLCD_Pos       ;Position cursor to location in A
            LD   DE, keyscan_table_row5
            CALL fLCD_Str       ;Display string pointed to by DE

;call delay250ms
	jp matrix
endif
ret

; using decade counter....


; TODO reset decade counter to start of scan

; reset 15
; clock 14
; ce 13

; 1 - q5
; 2 - q1
; 3 - q0
; 4 - q2
; 5 - q6
; 6 - q7
; 7 - q3
; 8 - vss
; 9 - q8
; 10 - q4
; 11 - q9
; 12 - cout
; 16 - vdd

; clock      ce       reset     output
; 0          x        0         n
; x          1        0         n
; x          x        1         q0
; rising     0        0         n+1
; falling    x        0         n
; x          rising   0         n
; 1          falling  0         x+1
;
; x = dont care, if n < 5 carry = 1 otherwise 0

; 
; reset 
; 13=0, 14=0, 15=1 .. 15=0
;
; handshake line
; 14=1.... read line 14=0





; TODO hand shake clock for next column scan
; TODO detect each row




; reset 128
; clock 64
; ce 32


.cyclestart:

; reset counter
ld a, 128
out (portbdata),a

; loop leds
ld b,10

.cycle1:
push bc
ld a, 0
out (portbdata),a
call delay250ms

ld a, 64
out (portbdata),a
call delay250ms

ld a, 0
out (portbdata),a
call delay250ms

pop bc
djnz .cycle1


jr .cyclestart









; map matrix key held to char on face of key

;.mtocold:
;
;
;; reset counter
;ld a, 128
;out (portbdata),a
;
;
;; scan keyboard row 1
;ld a, 0
;out (portbdata),a
;;ld a, 64
;;out (portbdata),a
;
;
;	ld a, 128
;	ld hl, keyscan_table
;	call .rowscan
;
;;ld a, 0
;;out (portbdata),a
;ld a, 64
;out (portbdata),a
;
;	ld a, 64
;	ld hl, keyscan_table+key_cols
;	call .rowscan
;
;ld a, 0
;out (portbdata),a
;;ld a, 64
;;out (portbdata),a
;	ld a, 32
;	ld hl, keyscan_table+(key_cols*2)
;	call .rowscan
;
;
;;ld a, 0
;;out (portbdata),a
;ld a, 64
;out (portbdata),a
;
;	ld a, 16
;	ld hl, keyscan_table+(key_cols*3)
;	call .rowscan
;
;
;	; flag if key D is held down and remove from reporting
;	ld bc, .key_map_fd  
;	ld hl, keyscan_table
;	ld de, key_fd
;	call .key_shift_hold
;	cp 255
;	jr z, .cinmap
;	; flag if key C is held down and remove from reporting
;	ld bc, .key_map_fc  
;	ld hl, keyscan_table+key_cols
;	ld de, key_fc
;	call .key_shift_hold
;	cp 255
;	jr z, .cinmap
;	; flag if key B is held down and remove from reporting
;	ld bc, .key_map_fb  
;	ld hl, keyscan_table+(key_cols*2)
;	ld de, key_fb
;	call .key_shift_hold
;	cp 255
;	jr z, .cinmap
;	; flag if key A is held down and remove from reporting
;	ld bc, .key_map_fa  
;	ld hl, keyscan_table+(key_cols*3)
;	ld de, key_fa
;	call .key_shift_hold
;	cp 255
;	jr z, .cinmap
;
;	ld de, .matrix_to_char
;
;
;.cinmap: 
;	if DEBUG_KEY
;            LD   A, kLCD_Line4
;            CALL fLCD_Pos       ;Position cursor to location in A
;		push de
;            LD   DE, keyscan_table
;            CALL fLCD_Str       ;Display string pointed to by DE
;		pop de
;	endif

	; scan key matrix table for any held key

	; de holds either the default matrix or one selected above

;	ld hl, keyscan_table
;	ld b,key_cols*key_rows
;
;.cin1:	ld a,(hl)
;	cp '#'
;	jr z, .cinhit
;	inc hl
;	inc de
;	dec b
;	jr nz, .cin1
;	; no key found held
;	ld a,0
;	ret
;.cinhit: push de
;	pop hl
;	ld a,(hl)
;	ret

; flag a control key is held 
; hl is key pin, de is flag indicator

;.key_shift_hold:
;	push bc
;	ld a, 1
;	ld (cursor_shape),a
;	ld b, 0
;	ld a, (hl)
;	cp '.'
;	jr z, .key_shift1
;	ld b, 255
;	ld a, '+'    ; hide key from later scans
;	ld (hl),a
;	ld a, 2
;	ld (cursor_shape),a
;.key_shift1:
;	; write flag indicator
;	ld a,b
;	ld (de),a
;
;	pop de    ; de now holds the key map ptr
;	ret

	
	











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

matrixold:



; reset counter
ld a, 128
out (portbdata),a
; scan keyboard row 1
ld a, 0
out (portbdata),a
;ld a, 64
;out (portbdata),a
	ld a, 128
	ld hl, keyscan_table_row1
	call .rowscan

;ld a, 0
;out (portbdata),a
ld a, 64
out (portbdata),a
	ld a, 64
	ld hl, keyscan_table_row2
	call .rowscan

ld a, 0
out (portbdata),a
;ld a, 64
;out (portbdata),a
	ld a, 32
	ld hl, keyscan_table_row3
	call .rowscan

;ld a, 0
;out (portbdata),a
ld a, 64
out (portbdata),a
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
;	out (portbdata),a
	in a,(portbdata)
	ld c,a
	; reset flags for the row 
	ld b,KEY_MATRIX_NO_PRESS
	and 1
	jr z, .p1on
	ld b,'#'
.p1on:
	ld (hl), b
	inc hl

	ld b,KEY_MATRIX_NO_PRESS
	ld a,c
	and 2
;	bit 0,a
	jr z, .p2on
	ld b,'#'
.p2on:
	ld (hl), b
	inc hl
;
	ld b,KEY_MATRIX_NO_PRESS
	ld a,c
	and 4
;;	bit 0,a
	jr z, .p3on
	ld b,'#'
.p3on:
	ld (hl), b
	inc hl
;;
	ld b,KEY_MATRIX_NO_PRESS
;;	bit 0,a
	ld a,c
	and 8
	jr z, .p4on
	ld b,'#'
.p4on:
	ld (hl), b
	inc hl

	ld b,KEY_MATRIX_NO_PRESS
;;	bit 0,a
	ld a,c
	and 16
	jr z, .p5on
	ld b,'#'
.p5on:
	ld (hl), b
	inc hl
; zero term
	ld b,0
	ld (hl), b

.rscandone: ret

;addatohl:
;
 ;add   a, l    ; A = A+L
  ;  ld    l, a    ; L = A+L
   ; adc   a, h    ; A = A+L+H+carry
   ; sub   l       ; A = H+carry
   ; ld    h, a    ; H = H+carry

;ret
; eof
