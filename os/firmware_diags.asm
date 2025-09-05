; Hardware diags menu


config:

	ld a, 0
	ld hl, .configmn
	call menu

	cp 0
	ret z

;	cp 1
;	call z, .savetostore

	cp 1
if STARTUP_V1
	call z, .selautoload
endif

if STARTUP_V2
	call z, .enautoload
endif
	cp 2
	call z, .disautoload
;	cp 3
;	call z, .selbank
	cp 3
	call z, .debug_tog
	cp 4
	call z, .bpsgo
	cp 5
	call z, hardware_diags
if STARTUP_V2
	cp 6
	call z, create_startup
endif
	jr config

.configmn:
;	dw prom_c3
	dw prom_c2
	dw prom_c2a
;	dw prom_c2b
;	dw prom_c4
	dw prom_m4
	dw prom_m4b
	dw prom_c1
if STARTUP_V2
	dw prom_c9
endif
	dw 0
	

if STARTUP_V2
.enautoload:
	if STORAGE_SE
	ld a, $fe      ; bit 0 clear
	ld (spi_device), a

	call storage_get_block_0

	ld a, 1
	ld (store_page+STORE_0_AUTOFILE), a

		ld hl, 0
		ld de, store_page
	call storage_write_block	 ; save update
	else

	ld hl, prom_notav
	ld de, prom_empty
	call info_panel
	endif


	ret
endif

.disautoload:
	if STORAGE_SE
	ld a, $fe      ; bit 0 clear
	ld (spi_device), a

	call storage_get_block_0

	ld a, 0
	ld (store_page+STORE_0_AUTOFILE), a

		ld hl, 0
		ld de, store_page
	call storage_write_block	 ; save update
	else

	ld hl, prom_notav
	ld de, prom_empty
	call info_panel
	endif


	ret

if STARTUP_V1

; Select auto start

.selautoload:

	
	if STORAGE_SE

		call config_dir
	        ld hl, scratch
		ld a, 0
		call menu

		cp 0
		ret z

		dec a


		; locate menu option

		ld hl, scratch
		call table_lookup

		if DEBUG_FORTH_WORDS
			DMARK "ALl"
			CALLMONITOR
		endif
		; with the pointer to the menu it, the byte following the zero term is the file id

		ld a, 0
		ld bc, 50   ; max of bytes to look at
		cpir 

		if DEBUG_FORTH_WORDS
			DMARK "ALb"
			CALLMONITOR
		endif
		;inc hl

		ld a, (hl)   ; file id
		
	        ; save bank and file ids

		push af

; TODO need to save to block 0 on bank 1	

		call storage_get_block_0

		if DEBUG_FORTH_WORDS
			DMARK "AL0"
			CALLMONITOR
		endif
		pop af

		ld (store_page+STORE_0_FILERUN),a
		
		; save bank id

		ld a,(spi_device)
		ld (store_page+STORE_0_BANKRUN),a

		; enable auto run of store file

		ld a, 1
		ld (store_page+STORE_0_AUTOFILE),a

		; save buffer

		ld hl, 0
		ld de, store_page
		if DEBUG_FORTH_WORDS
			DMARK "ALw"
			CALLMONITOR
		endif
	call storage_write_block	 ; save update
 



		ld hl, scratch
		call config_fdir

	else

	ld hl, prom_notav
	ld de, prom_empty
	call info_panel

	endif
	ret
endif


; Select storage bank

.selbank:

;	if STORAGE_SE
;	else

	ld hl, prom_notav
	ld de, prom_empty
	call info_panel
;	endif
	
	ret

if STORAGE_SE

.config_ldir:  
	; Load storage bank labels into menu array

	


	ret


endif


; Save user words to storage

.savetostore:

;	if STORAGE_SE
;
;		call config_dir
;	        ld hl, scratch
;		ld a, 0
;		call menu
;		
;		ld hl, scratch
;		call config_fdir
;
;	else

	ld hl, prom_notav
	ld de, prom_empty
	call info_panel

;	endif

	ret

if STARTUP_V2

create_startup:

	ld a, 0
	ld hl, .crstart
	call menu

	cp 0
	ret z

	cp 1
	call z, .genlsword
	cp 2
	call z, .genedword

	cp 3
	call z, .gendemword

	cp 4
	call z, .genutlword
	cp 5
	call z, .genspiword
	cp 6
	call z, .genkeyword
	cp 7
	call z, .gensoundword
	cp 8
	call z, .genhwword
	jr create_startup

.genhwword:
	ld hl, crs_hw
	ld de, .hwworddef
	call .genfile
	ret
.gensoundword:
	ld hl, crs_sound
	ld de, .soundworddef
	call .genfile
	ret
.genlsword:
	ld hl, crs_s1
	ld de, .lsworddef
	call .genfile
	ret

.genedword:
	ld de, .edworddef
	ld hl, crs_s2
	call .genfile
	ret

.gendemword:
	ld de, .demoworddef
	ld hl, crs_s3
	call .genfile
	ret

.genutlword:
	ld hl, crs_s4
	ld de, .utilwordef
	call .genfile
	ret
.genspiword:
	ld hl, crs_s5
	ld de, .spiworddef
	call .genfile
	ret
.genkeyword:
	ld hl, crs_s6
	ld de, .keyworddef
	call .genfile
	ret

; hl - points to file name
; de - points to strings to add to file

.genfile:
	push hl
	push de

	call clear_display
	ld a, display_row_1
	ld de, .genfiletxt
	call str_at_display
	call update_display

	pop de
	pop hl


	push de
	call storage_create
	; id in hl
	pop de   ; table of strings to add

.genloop:

	push hl ; save id for next time around
	push de ; save de for next time around

	ex de, hl
	call loadwordinhl
	ex de, hl

	; need hl to be the id
	; need de to be the string ptr
	
	call storage_append

	pop de
	pop hl

	inc de
	inc de

	ld a,(de)
	cp 0
	jr nz, .genloop
	inc de
	ld a, (de)
	dec de
	cp 0
	jr nz, .genloop	

	ret

.genfiletxt:  db "Creating file...",0

.hwworddef:
	dw test5
	dw test6
	dw test7
	dw test8
	dw test9
	dw test10
	dw 0

.soundworddef:
	dw sound1
	dw sound2
	dw sound3
	dw sound4
	dw sound5
	dw sound6
	dw sound7
	dw sound8
	dw sound9
	dw 0

.utilwordef:
	dw strncpy
	dw type
	dw tuck
	dw clrstack
	dw longread
	dw start1
	dw start2
; duplicated
;	dw start3b
;	dw start3c
	dw list
	dw 0

.lsworddef:
	dw start3b
	dw 0

.edworddef:
	dw edit1
	dw edit2
	dw edit3
	dw 0

.demoworddef:
	dw game1
	dw game1a
	dw game1b
	dw game1c
	dw game1d
	dw game1s
	dw game1t
	dw game1f
	dw game1z
	dw game1zz
	dw ssv2
	dw ssv3
	dw ssv4
	dw ssv5
	dw ssv1
	dw ssv1cpm	
;	dw game2b
;	dw game2bf
;	dw game2mba
;	dw game2mbas	
;	dw game2mbht
;	dw game2mbms
;	dw game2mb
;	dw game3w
;	dw game3p
;	dw game3sc
;	dw game3vsi
;	dw game3vs
	dw 0


.spiworddef:

    dw spi1
    dw spi2
    dw spi2b
    dw spi3
    dw spi4
    dw spi5
;    dw spi6
;    dw spi7

;    dw spi8
;    dw spi9
;    dw spi10
    dw 0

.keyworddef:

	dw keyup
	dw keydown
	dw keyleft
	dw keyright
	dw 	keyf1
	dw keyf2
	dw keyf3
	dw keyf4
	dw keyf5
	dw keyf6
	dw keyf7
	dw keyf8
	dw keyf9
	dw keyf10
	dw keyf11
	dw keyf12
	dw keytab
	dw keycr
	dw keyhome
	dw keyend
	dw keybs
	dw 0

.crstart:
	dw crs_s1
	dw crs_s2
	dw crs_s3
	dw crs_s4
	dw crs_s5
	dw crs_s6
	dw crs_sound
	dw crs_hw
	dw 0

endif


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
	
;	ld a, (os_view_disable)
;	cp '*'
	ld a,(debug_vector)
	cp $C9   ; RET
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
.dtog0: 
	;ld a, 0
	call bp_on
	jr .debug_tog
.dtogset: 
	; ld (os_view_disable), a
	call bp_off
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
	;ld a, 1
	;ld (hardware_diag), a
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

; Update the break point vector so that the user can hook a new routine

bp_on:
	ld a, $c3    ; JP
	ld (debug_vector), a
	ld hl, break_point_state
	ld (debug_vector+1), hl
	ret

bp_off:
	ld a, $c9    ; RET
	ld (debug_vector), a
	ret


break_point_state:
;	push af
;
;	; see if disabled
;
;	ld a, (os_view_disable)
;	cp '*'
;	jr nz, .bpsgo
;	pop af
;	ret

.bpsgo:
;	pop af
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
	call z, bp_off
;	jr nz, .bps1b
;	ld (os_view_disable),a
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


