; Startup script loading version 1

; If SE storage is available first stage is to use the selected file
; then go through the eeprom list

sprompt1: db "Startup load...",0
sprompt2: db "Run? 1=No *=End #=All",0




forth_startup:
	ld hl, startcmds
	ld a, 0
	ld (os_last_cmd), a    ; tmp var to skip prompts if doing all

.start1:	push hl
	call clear_display
	ld de, sprompt1
        ld a, display_row_1
	call str_at_display
	ld de, sprompt2
        ld a, display_row_2
	call str_at_display
	pop hl
	push hl
	ld e,(hl)
	inc hl
	ld d,(hl)
        ld a, display_row_3
	call str_at_display
	call update_display


	ld a, (os_last_cmd)
	cp 0
	jr z, .startprompt
	call delay250ms
	jr .startdo
	
	

.startprompt:

	ld a,display_row_4 + display_cols - 1
        ld de, endprg
	call str_at_display
	call update_display
	call delay1s
	call cin_wait
			
	cp '*'
	jr z, .startupend1
	cp '#'
	jr nz, .startno
	ld a, 1
	ld (os_last_cmd),a
	jr .startdo
.startno:	cp '1'
	jr z,.startnxt 

	; exec startup line
.startdo:	
	pop hl
	push hl
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl

	push hl

	ld a, 0
	;ld a, FORTH_END_BUFFER
	call strlent
	inc hl   ; include zero term to copy
	ld b,0
	ld c,l
	pop hl
	ld de, scratch
	ldir


	ld hl, scratch
	call forthparse
	call forthexec
	call forthexec_cleanup

	ld a, display_row_4
	ld de, endprog

	call update_display		

	ld a, (os_last_cmd)
	cp 0
	jr nz, .startnxt
	call next_page_prompt
        call clear_display
	call update_display		

	; move onto next startup line?
.startnxt:

	call delay250ms
	pop hl

	inc hl
	inc hl

	push hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	pop hl
	; TODO replace 0 test

	ex de, hl
	call ishlzero
;	ld a,e
;	add d
;	cp 0    ; any left to do?
	ex de, hl
	jp nz, .start1
	jr .startupend

.startupend1: pop hl
.startupend:

	call clear_display
	call update_display
	ret
if STORAGE_SE

sprompt3: db "Loading from start-up file?:",0
sprompt4: db "(Y=Any key/N=No)",0


forth_autoload:

	; load block 0 of store 1
	
	ld a, $fe      ; bit 0 clear
	ld (spi_device), a

	call storage_get_block_0

	ld a, (store_page+STORE_0_AUTOFILE)

	cp 0
	ret z     ; auto start not enabled

	call clear_display

	; set bank

		ld a, (store_page+STORE_0_BANKRUN)
		ld (spi_device), a

	; get file id to load from and get the file name to display

		ld a, (store_page+STORE_0_FILERUN)

		ld l, 0
		ld h, a
		ld de, store_page

		if DEBUG_FORTH_WORDS
			DMARK "ASp"
			CALLMONITOR
		endif
		call storage_read

		if DEBUG_FORTH_WORDS
			DMARK "ASr"
			CALLMONITOR
		endif

		call ishlzero
		ret z             ; file not found

		ld a, display_row_2 + 10
		ld de, store_page+3
		call str_at_display
	
;

	ld a, display_row_1+5
	ld de, sprompt3
	call str_at_display
	ld a, display_row_3+15
	ld de, sprompt4
	call str_at_display

	call update_display

	call cin_wait
	cp 'n'
	ret z
	cp 'N'
	ret z

	call delay1s

	ld a, (store_page+2)
	ld (store_openmaxext), a    ; save count of ext
	ld a, 1 
	ld (store_openext), a    ; save count of ext

.autof: 
	ld l , a
	
	ld a, (store_page)
	ld h, a	
	ld de, store_page
		if DEBUG_FORTH_WORDS
			DMARK "ASl"
			CALLMONITOR
		endif
		call storage_read
	call ishlzero
	ret z
;	jr z, .autoend

		if DEBUG_FORTH_WORDS
			DMARK "ASc"
			CALLMONITOR
		endif
	ld de, store_page+2
	ld a, display_row_4
	call str_at_display

	call update_display
	call delay250ms



	ld hl, store_page+2
	call forthparse
	call forthexec
	call forthexec_cleanup

	
	ld a, (store_openext)
	inc a
	ld (store_openext), a    ; save count of ext

	jr .autof
;.autofdone:
;
;		if DEBUG_FORTH_WORDS
;			DMARK "ASx"
;			CALLMONITOR
;		endif
;;	call clear_display
;	ret



endif
