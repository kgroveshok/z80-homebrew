; Hardware diags menu


config:

	ld a, 0
	ld hl, .configmn
	call menu

	cp 0
	ret z

	cp 1
	call z, .savetostore

	cp 3
	call z, .selbank
	cp 5
	call z, .debug_tog
	cp 6
	call z, hardware_diags

	jr config

.configmn:
	dw .c3
	dw .c2
	dw .c2b
	dw .c4
	dw .m4
	dw .c1
	dw 0
	

.c3: db "Add User Dictionary To File",0
.c2: db "Select Autoload File",0
.c2b: db "Select Storage Bank",0
.c4: db "Settings",0
.m4:   db "Debug & Breakpoints On/Off",0
.c1: db "Hardware Diags",0

; Select storage bank

.selbank:

	if STORAGE_SE
	endif
	
	ret

if STORAGE_SE

.config_ldir:  
	; Load storage bank labels into menu array

	


	ret


endif


; Save user words to storage

.savetostore:

	if STORAGE_SE

		call config_dir
	        ld hl, scratch
		ld a, 0
		call menu
		
		ld hl, scratch
		call config_fdir


	endif

	ret



if STORAGE_SE

config_fdir:
	; using the scratch dir go through and release the memory allocated for each string
	
	ld hl, scratch
.cfdir:	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl

	ex de, hl
	call ishlzero
	ret z     ; return on null pointer
	call free
	ex de, hl
	jr .cfdir


	ret


config_dir:

	; for the config menus that need to build a directory of storage call this routine
	; it will construct a menu in scratch to pass to menu

	; open storage device

	; execute DIR to build a list of files and their ids into scratch in menu format
	; once the menu has finished then will need to call config_fdir to release the strings
	
	; c = number items

	
	call storage_get_block_0

	ld hl, store_page     ; get current id count
	ld b, (hl)
	ld c, 0    ; count of files  


	ld hl, scratch
	ld (store_tmp2), hl    ; location to poke strings

	; check for empty drive

	ld a, 0
	cp b
	jp z, .dirdone

	
		if DEBUG_FORTH_WORDS
			DMARK "Cdc"
			CALLMONITOR
		endif


.diritem:	
	push bc
	; for each of the current ids do a search for them and if found push to stack

		ld hl, STORE_BLOCK_PHY
		ld d, 0		 ; look for extent 0 of block id as this contains file name
		ld e,b

		call storage_findnextid


		; if found hl will be non zero

		call ishlzero
		jr z, .dirnotfound

		; increase count

		pop bc	
		inc c
		push bc
		

		; get file header and push the file name

		ld de, store_page
		call storage_read_block

		; push file id to stack
	
		ld a, (store_page)
		ld h, 0
		ld l, a

		;call forth_push_numhl
		; TODO store id

		push hl

		; push extent count to stack 
	
		ld hl, store_page+3

		; get file name length

		call strlenz  

		inc hl   ; cover zero term
		inc hl  ; stick the id at the end of the area

		push hl
		pop bc    ; move length to bc

		call malloc

		; TODO save malloc area to scratch

		ex de, hl
		ld hl, (store_tmp2)
		ld (hl), e
		inc hl
		ld (hl), d
		inc hl
		ld (store_tmp2), hl

		

		;pop hl   ; get source
;		ex de, hl    ; swap aronund	

		ld hl, store_page+3
		if DEBUG_FORTH_WORDS
			DMARK "CFd"
			CALLMONITOR
		endif
		ldir

		; de is past string, move back one and store id
		
		dec de

		; store file id

		pop hl
		ex de,hl
		ld (hl), e

		if DEBUG_FORTH_WORDS
			DMARK "Cdi"
			CALLMONITOR
		endif
		
.dirnotfound:
		pop bc    
		djnz .diritem
	
.dirdone:	

		ld a, 0
		ld hl, (store_tmp2)
		ld (hl), a
		inc hl
		ld (hl), a
		inc hl
		; push a count of the dir items found

;		ld h, 0
;		ld l, c

	ret

endif


; Settings
; Run 



;hd_menu1:   db "Diags:  1: Key Matrix   5: Sound",0
;;hd_menu2:   db "        2: Editor",0  
;hd_menu2:   db "        2: Editor       6: Menu",0  
;hd_menu3:   db "        3: Storage",0
;hd_menu4:   db "0=quit  4: Debug",0
;hd_don:     db "ON",0
;hd_doff:     db "OFF",0
;
;
;
;hardware_diags_old:      
;
;.diagmenu:
;	call clear_display
;	ld a, display_row_1
;	ld de, hd_menu1
;	call str_at_display
;
;	ld a, display_row_2
;	ld de, hd_menu2
;	call str_at_display
;
;	ld a, display_row_3
;	ld de, hd_menu3
;	call str_at_display
;
;	ld a,  display_row_4
;	ld de, hd_menu4
;	call str_at_display
;
;	; display debug state
;
;	ld de, hd_don
;	ld a, (os_view_disable)
;	cp 0
;	jr z, .distog
;	ld de, hd_doff
;.distog: ld a, display_row_4+17
;	call str_at_display
;
;	call update_display
;
;	call cin_wait
;
;
;
;	cp '4'
;	jr nz, .diagn1
;
;	; debug toggle
;
;	ld a, (os_view_disable)
;	ld b, '*'
;	cp 0
;	jr z, .debtog
;	ld b, 0
;.debtog:	
;	ld a,b
;	ld (os_view_disable),a
;
;.diagn1: cp '0'
;	 ret z
;
;;	cp '1'
;;       jp z, matrix	
;;   TODO keyboard matrix test
;
;	cp '2'
;	jp z, .diagedit
;
;;	cp '6'
;;	jp z, .menutest
;;if ENABLE_BASIC
;;	cp '6'
;;	jp z, basic
;;endif
 ;
;	jp .diagmenu
;
;
;	ret


.debug_tog:
	ld hl, .menudebug
	
	ld a, (os_view_disable)
	cp '*'
	jr nz,.tdon 
	ld a, 1
	jr .tog1
.tdon: ld a, 0

.tog1:
	call menu
	cp 0
	ret z
	cp 1    ; disable debug
	jr z, .dtog0
	ld a, '*'
	jr .dtogset
.dtog0: ld a, 0
.dtogset:  ld (os_view_disable), a
	jp .debug_tog


hardware_diags:      

.diagm:
	ld hl, .menuitems
	ld a, 0
	call menu

         cp 0
	 ret z

	cp 2
	jp z, .diagedit

;	cp '6'
;	jp z, .menutest
;if ENABLE_BASIC
;	cp '6'
;	jp z, basic
;endif
 
	jp .diagm

	
.menuitems:   	dw .m1
		dw .m2
		dw .m3
		dw .m5
		dw .m5a
		dw .m5b
		dw 0

.menudebug:
		dw .m6
		dw .m7
		dw 0

.m1:   db "Key Matrix",0
.m2:   db "Editor",0
.m3:   db "Storage",0
.m5:   db "Sound",0
.m5a:  db "RAM Test",0
.m5b:  db "LCD Test",0

.m6:   db "Debug ON",0
.m7:   db "Debug OFF",0

; debug editor

.diagedit:

	ld hl, scratch
;	ld bc, 250
;	ldir
	; TODO ldir is not working strcpy may not get all the terms on the input line????
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a

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


; pass word in hl
; a has display location
display_word_at:
	push af
	push hl
	ld a,h
	ld hl, os_word_scratch
	call hexout
	pop hl
	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
	pop af
		call str_at_display
	ret

display_ptr_state:

	; to restore afterwards

	push de
	push bc
	push hl
	push af

	; for use in here

;	push bc
;	push de
;	push hl
;	push af

	call clear_display

	ld de, .ptrstate
	ld a, display_row_1
	call str_at_display

	; display debug step


	ld de, debug_mark
	ld a, display_row_1+display_cols-2
	call str_at_display

	; display a
	ld de, .ptrcliptr
	ld a, display_row_2
	call str_at_display

	pop af
	ld hl,(cli_ptr)
	ld a, display_row_2+8
	call display_word_at


	; display hl


	ld de, .ptrclioptr
	ld a, display_row_2+10
	call str_at_display
;
;	pop hl
	ld a, display_row_2+13
	ld hl,(cli_origptr)
	call display_word_at
;
;	
;	; display de

;	ld de, .regstatede
;	ld a, display_row_3
;	call str_at_display

;	pop de
;	ld h,d
;	ld l, e
;	ld a, display_row_3+3
;	call display_word_at


	; display bc

;	ld de, .regstatebc
;	ld a, display_row_3+10
;	call str_at_display

;	pop bc
;	ld h,b
;	ld l, c
;	ld a, display_row_3+13
;	call display_word_at


	; display dsp

;	ld de, .regstatedsp
;	ld a, display_row_4
;	call str_at_display

	
;	ld hl,(cli_data_sp)
;	ld a, display_row_4+4
;	call display_word_at

	; display rsp

	ld de, .regstatersp
	ld a, display_row_4+10
	call str_at_display

	
	ld hl,(cli_ret_sp)
	ld a, display_row_4+14
	call display_word_at

	call update_display

	call delay1s
	call delay1s
	call delay1s


	call next_page_prompt

	; restore 

	pop af
	pop hl
	pop bc
	pop de
	ret

break_point_state:
	push af

	; see if disabled

	ld a, (os_view_disable)
	cp '*'
	jr nz, .bpsgo
	pop af
	ret

.bpsgo:
	pop af
	push af
	ld (os_view_hl), hl
	ld (os_view_de), de
	ld (os_view_bc), bc
	push hl
	ld l, a
	ld h, 0
	ld (os_view_af),hl

		ld hl, display_fb0
		ld (display_fb_active), hl
	pop hl	

	ld a, '1'
.bps1:  cp '*'
	jr nz, .bps1b
	ld (os_view_disable),a
.bps1b:  cp '1'
	jr nz, .bps2

	; display reg

	

	ld a, (os_view_af)
	ld hl, (os_view_hl)
	ld de, (os_view_de)
	ld bc, (os_view_bc)
	call display_reg_state
	jp .bpschk

.bps2:  cp '2'
	jr nz, .bps3
	
	; display hl
	ld hl, (os_view_hl)
	call display_dump_at_hl

	jr .bpschk

.bps3:  cp '3'
	jr nz, .bps4

        ; display de
	ld hl, (os_view_de)
	call display_dump_at_hl

	jr .bpschk
.bps4:  cp '4'
	jr nz, .bps5

        ; display bc
	ld hl, (os_view_bc)
	call display_dump_at_hl

	jr .bpschk
.bps5:  cp '5'
        jr nz, .bps7

	; display cur ptr
	ld hl, (cli_ptr)
	call display_dump_at_hl

	jr .bpschk
.bps7:  cp '6'
	jr nz, .bps8b
	
	; display cur orig ptr
	ld hl, (cli_origptr)
	call display_dump_at_hl
	jr .bpschk
.bps8b:  cp '7'
	jr nz, .bps9
	
	; display dsp
	ld hl, (cli_data_sp)
	call display_dump_at_hl

	jr .bpschk
.bps9:  cp '9'
	jr nz, .bps8c
	
	; display SP
;	ld hl, sp
	call display_dump_at_hl

	jr .bpschk
.bps8c:  cp '8'
	jr nz, .bps8d
	
	; display rsp
	ld hl, (cli_ret_sp)
	call display_dump_at_hl

	jr .bpschk
.bps8d:  cp '#'     ; access monitor sub system
	jr nz, .bps8
	call monitor

	jr .bpschk
.bps8:  cp '0'
	jr nz, .bpschk

		ld hl, display_fb1
		ld (display_fb_active), hl
		call update_display

	;ld a, (os_view_af)
	ld hl, (os_view_hl)
	ld de, (os_view_de)
	ld bc, (os_view_bc)
	pop af
	ret

.bpschk:  
	call delay1s
ld a,display_row_4 + display_cols - 1
        ld de, endprg
	call str_at_display
	call update_display
	call cin_wait

	jp .bps1


display_reg_state:

	; to restore afterwards

	push de
	push bc
	push hl
	push af

	; for use in here

	push bc
	push de
	push hl
	push af

	call clear_display

	ld de, .regstate
	ld a, display_row_1
	call str_at_display

	; display debug step


	ld de, debug_mark
	ld a, display_row_1+display_cols-3
	call str_at_display

	; display a
	ld de, .regstatea
	ld a, display_row_2
	call str_at_display

	pop hl
;	ld h,0
;	ld l, a
	ld a, display_row_2+3
	call display_word_at


	; display hl


	ld de, .regstatehl
	ld a, display_row_2+10
	call str_at_display

	pop hl
	ld a, display_row_2+13
	call display_word_at

	
	; display de

	ld de, .regstatede
	ld a, display_row_3
	call str_at_display

	pop hl
;	ld h,d
;	ld l, e
	ld a, display_row_3+3
	call display_word_at


	; display bc

	ld de, .regstatebc
	ld a, display_row_3+10
	call str_at_display

	pop hl
;	ld h,b
;	ld l, c
	ld a, display_row_3+13
	call display_word_at


	; display dsp

	ld de, .regstatedsp
	ld a, display_row_4
	call str_at_display

	
	ld hl,(cli_data_sp)
	ld a, display_row_4+4
	call display_word_at

	; display rsp

	ld de, .regstatersp
	ld a, display_row_4+10
	call str_at_display

	
	ld hl,(cli_ret_sp)
	ld a, display_row_4+14
	call display_word_at

	call update_display

;	call delay1s
;	call delay1s
;	call delay1s


;	call next_page_prompt

	; restore 

	pop af
	pop hl
	pop bc
	pop de
	ret

.wordincurptr:  db "Word in cur_ptr (5)",0
.wordincuroptr:  db "Word in cur_optr (6)",0
.ptrstate:	db "Ptr State",0
.ptrcliptr:     db "cli_ptr",0
.ptrclioptr:     db "cli_o_ptr",0
.regstate:	db "Reg State (1/0)",0
.regstatehl:	db "HL:",0
.regstatede:	db "DE:",0
.regstatebc:	db "BC:",0
.regstatea:	db "A :",0
.regstatedsp:	db "DSP:",0
.regstatersp:	db "RSP:",0

display_dump_at_hl:
	push hl
	push de
	push bc
	push af

	ld (os_cur_ptr),hl	
	call clear_display
	call dumpcont
;	call delay1s
;	call next_page_prompt


	pop af
	pop bc
	pop de
	pop hl
	ret

;if ENABLE_BASIC
;	include "nascombasic.asm"
;	basic:
;	include "forth/FORTH.ASM"
;endif

; eof


