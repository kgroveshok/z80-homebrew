; Version 2 of the startup 
; 
; Auto load any files in bank 1 that start with a '*'
; If no se storage then revert to using eprom


if STORAGE_SE = 0

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
endif


if STORAGE_SE

;sprompt3: db "Loading from start-up file:",0
sprompt3: db "  Searching...",0
;sprompt4: db "(Any key to stop)",0


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


	; generate a directory of bank 1 and search for flagged files

		if DEBUG_FORTH_WORDS_KEY
			DMARK "DIR"
			CALLMONITOR
		endif

	call storage_get_block_0

	ld hl, store_page     ; get current id count
	ld b, (hl)
	ld c, 0    ; count of files  
		if DEBUG_FORTH_WORDS
			DMARK "DI1"
			CALLMONITOR
		endif

	; check for empty drive

	ld a, 0
	cp b
	jp z, .dirdone

	; for each of the current ids do a search for them and if found push to stack

.diritem:	push bc
		ld hl, STORE_BLOCK_PHY
		ld d, 0		 ; look for extent 0 of block id as this contains file name
		ld e,b

		push de
		push hl
	call clear_display
	ld a, display_row_2 + 10
	ld de, sprompt3
	call str_at_display
	call active
	ex de, hl
	ld a, display_row_2 + 7
	call str_at_display
	call update_display
	pop hl
	pop de

;		if DEBUG_FORTH_WORDS
;			DMARK "DI2"
;			CALLMONITOR
;		endif

		call storage_findnextid

;		if DEBUG_FORTH_WORDS
;			DMARK "DI3"
;			CALLMONITOR
;		endif

		; if found hl will be non zero

		call ishlzero
;		ld a, l
;		add h
;
;		cp 0
		jr z, .dirnotfound

		; increase count

		pop bc	
		inc c
		push bc
		

		; get file header and push the file name

		ld de, store_page
		call storage_read_block

		; push file id to stack
	

		; is this a file we want to run?

		ld hl, store_page+3
		ld a,(hl)
		cp '*'
		jr nz,  .dirnotfound
		


		ld a, (store_page)
		push de
		push hl
		push bc
		call .autorunf
		pop bc
		pop hl
		pop de



	; save this extent

		; push file name
;display file name to run

;		ld hl, store_page+3
;		if DEBUG_FORTH_WORDS
;			DMARK "DI5"
;			CALLMONITOR
;		endif
;
;		
;
;		call forth_push_str
;		if DEBUG_FORTH_WORDS
;			DMARK "DI6"
;			CALLMONITOR
;		endif
.dirnotfound:
		pop bc    
		djnz .diritem
	
.dirdone:	
		if DEBUG_FORTH_WORDS
			DMARK "DI7"
			CALLMONITOR
		endif

		call clear_display
		call update_display

		ret





.autorunf:


	; get file id to load from and get the file name to display

;		ld a, (store_page+STORE_0_FILERUN)

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

		; display file name we are loading

		call clear_display

		ld a, display_row_2 + 10
		ld de, store_page+3
		call str_at_display
	
;

;	ld a, display_row_1+5
;	ld de, sprompt3
;	call str_at_display
;	ld a, display_row_2+7
;	call active
;	ex de, hl
;;	ld de, sprompt4
;	call str_at_display
;
	call update_display

;	call cin_wait
;	cp 'n'
;	ret z
;	cp 'N'
;	ret z

;	call delay1s

	ld a, (store_page+2)
	ld (store_openmaxext), a    ; save count of ext
	ld a, 1 
	ld (store_openext), a    ; save count of ext

.autof:
	; begin to read a line from file

	ld hl, os_cli_cmd
	ld (os_var_array), hl     ; somewhere to hold the line construction pointer
 
.readext:
	ld a, (store_openext)
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

; TODO copy to exec buffer
; check (store_readcont) if 0 then exec, if not then load on the end of the exec buffer until 0

	; copy the record buffer to the cli buffer

	ld de, (os_var_array)
	ld hl, store_page+2
;	ex de, hl
	ld bc, STORE_BLOCK_PHY-2   ; two for the file ids
	ldir
	ld (os_var_array), de
	
	ld a, (store_openext)
	inc a
	ld (store_openext), a    ; save count of ext


; check (store_readcont) if 0 then exec, if not then load on the end of the exec buffer until 0
	
	ld a, (store_readcont)
	cp 0
	jr nz, .readext

;	jr z, .autoend

		if DEBUG_FORTH_WORDS
			DMARK "ASc"
			CALLMONITOR
		endif
	push hl	
	push de
	call active
	ex de, hl
	ld a, display_row_2 + 7
	call str_at_display

	call update_display
	pop de 
	pop hl
;	call delay250ms




.autoexec:


	ld hl, os_cli_cmd
		if DEBUG_FORTH_WORDS
			DMARK "ASx"
			CALLMONITOR
		endif
	call forthparse
	call forthexec
	call forthexec_cleanup



	jp .autof
;.autofdone:
;
;		if DEBUG_FORTH_WORDS
;			DMARK "ASx"
;			CALLMONITOR
;		endif
;;	call clear_display
;	ret



endif
