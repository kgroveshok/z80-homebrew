; Hardware diags menu


hd_menu1:   db "Diags:  1: Key Matrix   5: Sound",0
hd_menu2:   db "        2: Editor",0  
hd_menu3:   db "        3: Storage",0
hd_menu4:   db "0=quit  4: Debug",0
hd_don:     db "ON",0
hd_doff:     db "OFF",0



hardware_diags:      

.diagmenu:
	call clear_display
	ld a, display_row_1
	ld de, hd_menu1
	call str_at_display

	ld a, display_row_2
	ld de, hd_menu2
	call str_at_display

	ld a, display_row_3
	ld de, hd_menu3
	call str_at_display

	ld a,  display_row_4
	ld de, hd_menu4
	call str_at_display

	; display debug state

	ld de, hd_don
	ld a, (os_view_disable)
	cp 0
	jr z, .distog
	ld de, hd_doff
.distog: ld a, display_row_4+17
	call str_at_display

	call update_display

	call cin_wait



	cp '4'
	jr nz, .diagn1

	; debug toggle

	ld a, (os_view_disable)
	ld b, '*'
	cp 0
	jr z, .debtog
	ld b, 0
.debtog:	
	ld a,b
	ld (os_view_disable),a

.diagn1: cp '0'
	 ret z

;	cp '1'
;       jp z, matrix	
;   TODO keyboard matrix test

	cp '2'
	jp z, .diagedit
 
	jp .diagmenu


	ret

; debug editor

.diagedit:

        call clear_display
	call update_display
	ld a, 1
	ld (hardware_diag), a
.diloop:
	ld a, display_row_1
	ld c, 0
	ld d, 255    ; TODO fix input_str to actually take note of max string input length
	ld e, 40

	ld hl, scratch	
	call input_str

	ld a, display_row_2
	ld de, scratch
	call str_at_display
	call update_display

	jp .diloop


; eof

