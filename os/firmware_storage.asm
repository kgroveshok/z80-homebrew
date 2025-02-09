
; persisent storage hardware abstraction layer 



; Block 0 on storage is a config state



; TODO add read phy block and write phy block functions
; TODO add presence check (i.e. read write byte 0 of block 0 for eeprom)

; Abstraction layer 

; Logocial block size is same size as physical size - using tape concept

;STORE_BLOCK_PHY2LOG: equ (STORE_BLOCK_LOG/STORE_BLOCK_PHY)       ; How many physical blocks make up a logical block
;STORE_BLOCK_MAX: equ (STORE_BLOCK_PHY*STORE_DEVICE_MAXBLOCKS)/255    ; Max number of logical blocks on the device



; Filesystem layout (Logical layout)
;
; Block 0 - Bank config 
;
;      Byte - 0 file id counter
;      Byte - 1-2 formated: Byte pattern: 0x80 x27
;      Byte - 3-20 zero terminated bank label
;
; Block 1 > File storage
;
;      Byte 0 file id    - block 0 file details
;      Byte 1 block id - block 0 is file 
;            Byte 2-15 - File name
;
;       - to end of block data
;


; Read Block
; ----------
;
; With current bank
; 
; Get block number to read
; Load physical blocks starting at start block into buffer

; de points to buffer to use
; hl holds logical block number 

storage_read_block:

	; TODO bank selection

	; for each of the physical blocks read it into the buffer
	ld b, STORE_BLOCK_PHY

	if DEBUG_STORESE
		push de
	endif
	
.rl1:   

	; read physical block at hl into de
        ; increment hl and de to next read position on exit

	push hl
	push de	
	push bc
;	if DEBUG_STORESE
;		push af
;		ld a, 'R'
;		ld (debug_mark),a
;		pop af
;		CALLMONITOR
;	endif
	call se_readbyte
;	if DEBUG_STORESE
;		ld a,(spi_portbyte)
;		ld l, a
;		push af
;		ld a, '1'
;		ld (debug_mark),a
;		pop af
;		CALLMONITOR
;	endif
	pop bc
	pop de
	pop hl
	ld (de),a
	inc hl
	inc de

;	if DEBUG_STORESE
;		push af
;		ld a, 'r'
;		ld (debug_mark),a
;		pop af
;		CALLMONITOR
;	endif

	djnz .rl1

	if DEBUG_STORESE
		DMARK "SRB"
		pop de
;
;		push af
;		ld a, 'R'
;		ld (debug_mark),a
;		pop af
		CALLMONITOR
	endif
	ret	
	

; File Size
; ---------
;
;   hl file id
;
;  returns in hl the number of blocks

storage_file_size:
	ld e, l
	ld d, 0
	ld hl, STORE_BLOCK_PHY
		if DEBUG_FORTH_WORDS
			DMARK "SIZ"
			CALLMONITOR
		endif
	call storage_findnextid

	call ishlzero
;	ld a, l
;	add h
;	cp 0
	ret z			; block not found so EOF

	ld de, store_page
	call storage_read_block

	ld a, (store_page+2)	 ; get extent count
	ld l, a
	ld h, 0
 	ret


; Write Block
; -----------
;
; With current bank
; 
; Get block number to write
; Write physical blocks starting at start block from buffer
 
storage_write_block:
	; TODO bank selection

	; for each of the physical blocks read it into the buffer
	ld b, STORE_BLOCK_PHY

	if DEBUG_STORESE
		DMARK "SWB"

		;push af
		;ld a, 'W'
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif

; might not be working
;	call se_writepage

;	ret
;



.wl1:   

	; read physical block at hl into de
        ; increment hl and de to next read position on exit

	push hl
	push de	
	push bc
	ld a,(de)
	;if DEBUG_STORESE
;		push af
;		ld a, 'W'
;		ld (debug_mark),a
;		pop af
;		CALLMONITOR
;	endif
	call se_writebyte
;	call delay250ms
	nop
	nop
	nop
;	if DEBUG_STORESE
;		push af
;		ld a, 'w'
;		ld (debug_mark),a
;		pop af
;		CALLMONITOR
;	endif
	pop bc
	pop de
	pop hl
	inc hl
	inc de


	djnz .wl1

	if DEBUG_STORESE
		DMARK "SW2"

		;push af
		;ld a, 'W'
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif
	ret	

; Init bank
; ---------
;
; With current bank
;
; Setup block 0 config
;     Set 0 file id counter
;     Set formatted byte pattern
;     Zero out bank label
;     
; For every logical block write 0-1 byte as null

storage_get_block_0:

	; TODO check presence

	; get block 0 config

	ld hl, 0
	ld de, store_page
	call storage_read_block

	if DEBUG_STORESE
		DMARK "SB0"
		ld de, store_page
;		push af
;		ld a, 'i'
;		ld (debug_mark),a
;		pop af
		CALLMONITOR
	endif

	; is this area formatted?

;      Byte - 1-2 formated: Byte pattern: 0x80 x27
	ld hl, (store_page+1)
	ld a,0x80
	cp l
	jr nz, .ininotformatted
	; do a double check
	ld a, 0x27
	cp h
	jr nz, .ininotformatted

	; formatted then

	if DEBUG_STORESE
		DMARK "SB1"
		;push af
		;ld a, 'I'
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif
	ret

.ininotformatted:
	; bank not formatted so poke various bits to make sure

	if DEBUG_STORESE
		DMARK "SB2"
		;push af
		;ld a, 'f'
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif

	call storage_clear_page

	ld hl, store_page
	ld a, 0
	
	ld (hl),a   ; reset file counter

	ld hl, 0x2780     ;      Byte - 1-2 formated: Byte pattern: 0x80 x27
 	ld (store_page+1), hl	

	; set default label

	ld hl, .defaultbanklabl
 	ld de, store_page+3
	ld bc, 15
	ldir

	; Append the current bank id
	ld hl, store_page+3+9
	ld a, (spi_device_id)
	ld (hl), a

	; save default page 0

	ld hl, 0
	ld de, store_page
	if DEBUG_STORESE
		DMARK "SB3"
;		push af
;		ld a, 'F'
;		ld (debug_mark),a
;		pop af
		CALLMONITOR
	endif
	call storage_write_block
	if DEBUG_STORESE
		DMARK "SB4"
;		push af
;		ld a, '>'
;		ld (debug_mark),a
;		pop af
		CALLMONITOR
	endif

	nop
	nop
	nop

	; now set 0 in every page to mark as a free block

	ld b, STORE_DEVICE_MAXBLOCKS/2
	ld hl, STORE_BLOCK_PHY

.setmark1:   	ld a,0
		push hl
		push bc
		call se_writebyte
	ld a, 10
	call aDelayInMS
	inc hl
		call se_writebyte
	ld a, 10
	call aDelayInMS
	dec hl
		pop bc
		pop hl
		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .setmark1

	ld b, STORE_DEVICE_MAXBLOCKS/2
.setmark2:   	ld a,0
		push hl
		push bc
		call se_writebyte
	ld a, 10
	call aDelayInMS
	inc hl
		call se_writebyte
	ld a, 10
	call aDelayInMS
	dec hl
		pop bc
		pop hl
		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .setmark2

		


	ret




.defaultbanklabl:   db "BankLabel_",0



; Label Bank
; ----------
;
; With current bank
; Read block 0
; Set label
; Write block 0

; label str pointer in hl

storage_label:    

	if DEBUG_STORESE
		DMARK "LBL"
		CALLMONITOR
	endif

	push hl

	call storage_get_block_0

	; set default label

	pop hl

 	ld de, store_page+3
	ld bc, 15
	if DEBUG_STORESE
		DMARK "LB3"
		CALLMONITOR
	endif
	ldir
	; save default page 0

	ld hl, 0
	ld de, store_page
	if DEBUG_STORESE
		DMARK "LBW"
		CALLMONITOR
	endif
	call storage_write_block

	ret



; Read Block 0 - Config
; ---------------------
;
; With current bank
; Call presence test
;    If not present format/init bank 
; Read block 0 
; 


; Dir
; ---
;
; With current bank
; Load Block 0 Config
; Get max file id number
; For each logical block
;    Read block read byte 2
;      if first block of file
;         Display file name
;         Display type flags for file
;       

; moving to words as this requires stack control


; Delete File
; -----------
;
; With current bank
;
; Load Block 0 Config
; Get max file id number
; For each logical block
;    Read block file id
;      If first block of file and dont have file id
;         if file to delete
;         Save file id
;         Null file id
;         Write this block back
;      If file id is one saved
;         Null file id
;         Write this block back


.se_done:
	pop hl
	ret

storage_erase:

	; hl contains the file id

	ld e, l
	ld d, 0
	ld hl, STORE_BLOCK_PHY
		if DEBUG_FORTH_WORDS
			DMARK "ERA"
			CALLMONITOR
		endif
	call storage_findnextid
	call ishlzero
	ret z

	push hl

	; TODO check file not found

	ld de, store_page
	call storage_read_block

	call ishlzero
	jp z,.se_done

		if DEBUG_FORTH_WORDS
			DMARK "ER1"
			CALLMONITOR
		endif
	ld a, (store_page)	; get file id
	ld (store_tmpid), a

	ld a, (store_page+2)    ; get count of extends
	ld (store_tmpext), a

	; wipe file header

	pop hl
	ld a, 0
	ld (store_page), a
	ld (store_page+1),a
	ld de, store_page
		if DEBUG_FORTH_WORDS
			DMARK "ER2"
			CALLMONITOR
		endif
	call storage_write_block


	; wipe file extents

	ld a, (store_tmpext)
	ld b, a

.eraext:	 
	push bc

	ld hl, STORE_BLOCK_PHY
	ld a,(store_tmpid)
	ld e, a
	ld d, b	
		if DEBUG_FORTH_WORDS
			DMARK "ER3"
			CALLMONITOR
		endif
	call storage_findnextid
	call ishlzero
	jp z,.se_done

	push hl
	ld de, store_page
	call storage_read_block

	; free block	

	ld a, 0
	ld (store_page), a
	ld (store_page+1),a
	ld de, store_page
	pop hl
		if DEBUG_FORTH_WORDS
			DMARK "ER4"
			CALLMONITOR
		endif
	call storage_write_block

	pop bc
	djnz .eraext

	ret


; Find Free Block
; ---------------
;
; With current bank
; 
; From given starting logical block
;    Read block 
;    If no file id
;         Return block id


; hl starting page number
; hl contains free page number or zero if no pages free
; e contains the file id to locate
; d contains the block number

; TODO change to find file id and use zero for free block

storage_findnextid:

	; now locate first 0 page to mark as a free block

	ld b, STORE_DEVICE_MAXBLOCKS/2
;	ld hl, STORE_BLOCK_PHY

		if DEBUG_FORTH_WORDS
		DMARK "FNI"
			CALLMONITOR
		endif
.ff1:   	
		push hl
		push bc
		push de
		call se_readbyte
		ld e,a
		inc hl
		call se_readbyte
		ld d, a
		pop hl
		push hl
		call cmp16
		jr z, .fffound

		pop de
		pop bc
		pop hl

		; is found?
		;cp e
		;ret z

		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .ff1

	ld b, STORE_DEVICE_MAXBLOCKS/2
.ff2:   	

		push hl
		push bc
		push de
		call se_readbyte
		ld e,a
		inc hl
		call se_readbyte
		ld d, a

		pop hl
		push hl
		call cmp16
		jr z, .fffound

		pop de
		pop bc
		pop hl
		; is found?
		;cp e
		;ret z

		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .ff2


		if DEBUG_FORTH_WORDS
		DMARK "FN-"
		;	push af
		;	ld a, 'n'
		;	ld (debug_mark),a
		;	pop af
			CALLMONITOR
		endif
	; no free marks!
		ld hl, 0
	ret
.fffound:
	

		pop de
		pop bc
		pop hl
		if DEBUG_FORTH_WORDS
		DMARK "FNF"
		;	push af
		;	ld a, 'n'
		;	ld (debug_mark),a
		;	pop af
			CALLMONITOR
		endif
	ret



; Free Space
; ----------
;
; With current bank
;
; Set block count to zero
; Starting with first logical block
;      Find free block 
;      If block id given, increment block count
;
; 


; hl contains count of free blocks

storage_freeblocks:

	; now locate first 0 page to mark as a free block

	ld b, STORE_DEVICE_MAXBLOCKS/2
	ld hl, STORE_BLOCK_PHY
	ld de, 0

.fb1:   	
		push hl
		push bc
		push de
		call se_readbyte
		pop de
		pop bc
		pop hl

		; is free?
		cp 0
		jr nz, .ff1cont
		inc de

.ff1cont:


		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .fb1

	ld b, STORE_DEVICE_MAXBLOCKS/2
.fb2:   	
		push hl
		push bc
		push de
		call se_readbyte
		pop de
		pop bc
		pop hl

		; is free?
		cp 0
		jr nz, .ff2cont
		inc de

.ff2cont:

		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .fb2

	ex de, hl
	ret

; Get File ID
; -----------
;
; With current bank
; 
; Load Block 0 Config
; Get max file id number
; For each logical block
;    Read block file id
;      If first block of file and dont have file id
;         if file get id and exit




; Create File
; -----------
;
; With current bank 
; Load Block 0 Config
; Get max file id number
; Increment file id number
; Save Config
; Find free block
; Set buffer with file name and file id
; Write buffer to free block 


; hl point to file name
; hl returns file id

; file format:
; byte 0 - file id
; byte 1 - extent number
; byte 2-> data

; format for extent number 0:
;
; byte 0 - file id
; byte 1 - extent 0
; byte 2 - extent count
; byte 3 -> file name and meta data


storage_create:
	if DEBUG_STORESE
		DMARK "SCR"
		CALLMONITOR
	endif

	push hl		; save file name pointer

	call storage_get_block_0

	ld a,(store_page)	; get current file id
	inc a
	ld (store_page),a
	
	ld (store_tmpid),a			; save id

	ld hl, 0
	ld de, store_page
	if DEBUG_STORESE
		DMARK "SCw"
		CALLMONITOR
	endif
	call storage_write_block	 ; save update

	if DEBUG_STORESE
		ld de, store_page
		DMARK "SCC"
		CALLMONITOR
	endif
	; 
	
	ld hl, STORE_BLOCK_PHY
	ld de, 0
	call storage_findnextid

	ld (store_tmppageid), hl    ; save page to use 

	; TODO detect 0 = no spare blocks

	; hl now contains the free page to use for the file header page

	if DEBUG_STORESE
	DMARK "SCF"
		CALLMONITOR
	endif

	ld (store_tmppageid), hl
	
	ld a,(store_tmpid)    ; get file id
;	ld a, (store_filecache)			; save to cache

	ld (store_page),a    ; set page id
	ld a, 0			 ; extent 0 is file header
	ld (store_page+1), a   ; set file extent

	ld (store_page+2), a   ; extent count for the file

;	inc hl 		; init block 0 of file
;	inc hl   		; skip file and extent id
 ;       ld a, 0
;	ld (hl),a
;	ld a, (store_filecache+1)  	; save to cache

;	inc hl    ; file name
	
	
	ld de, store_page+3    ; get buffer for term string to use as file name
	if DEBUG_STORESE
		DMARK "SCc"
		CALLMONITOR
	endif
	pop hl    ; get zero term string
	push hl
	ld a, 0
	call strlent
	inc hl   ; cover zero term
	ld b,0
	ld c,l
	pop hl
	;ex de, hl
	if DEBUG_STORESE
		DMARK "SCa"
		;push af
		;ld a, 'a'
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif
	ldir    ; copy zero term string
	if DEBUG_STORESE
		DMARK "SCA"
		CALLMONITOR
	endif

	; write file header page

	ld hl,(store_tmppageid)
	ld de, store_page
	if DEBUG_STORESE
		DMARK "SCb"
		;push af
		;ld a, 'b'
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif
	call storage_write_block

	ld a, (store_tmpid)
	ld l, a
	ld h,0
	if DEBUG_STORESE
		DMARK "SCz"
		CALLMONITOR
	endif
	ret
	


;
; Read File
;
; h - file id to locate
; l - extent to locate
; de - pointer to string to read into
;
; returns hl is 0 if block not found ie end of file or pointer to start of data read

.sr_fail:
	pop de
	ret

storage_read:
	push de

; TODO BUG the above push is it popped before the RET Z?

; TODO how to handle multiple part blocks

	; locate file extent to read

	ld e, h
	ld d, l
	ld hl, STORE_BLOCK_PHY
	if DEBUG_STORESE
		DMARK "SRE"
		CALLMONITOR
	endif
	call storage_findnextid

	if DEBUG_STORESE
		DMARK "SRf"
		CALLMONITOR
	endif
	call ishlzero
;	ld a, l
;	add h
;	cp 0
	jr z,.sr_fail			; block not found so EOF

	; hl contains page number to load
	pop de   ; get storage
	push de
	if DEBUG_STORESE
		DMARK "SRg"
		CALLMONITOR
	endif
	call storage_read_block


; TODO if block has no zeros then need to read next block 


		
	pop hl 		 ; return start of data to show as not EOF
	inc hl   ; past file id
	inc hl   ; past ext
	if DEBUG_STORESE
		DMARK "SRe"
		CALLMONITOR
	endif
		ret



;
; Append File
;
; hl - file id to locate
; de - pointer to (multi block) string to write

.sa_notfound:
	pop de
	ret


storage_append:
	; hl -  file id to append to
	; de - string to append

	push de
	
	if DEBUG_STORESE
		DMARK "AP1"
		CALLMONITOR
	endif

	ld a, l
	ld (store_tmpid), a

	; get file header 

	ld d, 0			 ; file extent to locate - file name details at item 0
	ld a, (store_tmpid)
	ld e, a

		ld hl, STORE_BLOCK_PHY
		call storage_findnextid

	call ishlzero
	jr z, .sa_notfound

	ld (store_tmppageid), hl

	; TODO handle file id not found

	if DEBUG_STORESE
		DMARK "AP2"
		CALLMONITOR
	endif

	; update file extent count

	ld de, store_page

	call storage_read_block

	if DEBUG_STORESE
		DMARK "AP3"
		CALLMONITOR
	endif
;	ld (store_tmppageid), hl

	ld a, (store_page+2)
	inc a
	ld (store_page+2), a
	ld (store_tmpext), a
	
	if DEBUG_STORESE
		DMARK "AP3"
		CALLMONITOR
	endif
	ld hl, (store_tmppageid)
	ld de, store_page
	call storage_write_block

	; find free block

	ld de, 0			 ; file extent to locate

		ld hl, STORE_BLOCK_PHY
		call storage_findnextid
	call ishlzero
	jp z, .sa_notfound

		; TODO handle no space left
		
		ld (store_tmppageid), hl

	if DEBUG_STORESE
		DMARK "AP4"
		CALLMONITOR
	endif
		; init the buffer with zeros so we can id if the buffer is full or not

		push hl
		push bc

		ld hl, store_page
		ld b, STORE_BLOCK_PHY
		ld a, 0
.zeroblock:	ld (hl), a
		inc hl
		djnz .zeroblock

		pop bc
		pop hl

		; construct block

		ld a, (store_tmpid)
		ld (store_page), a   ; file id
		ld a, (store_tmpext)   ; extent for this block
		ld (store_page+1), a

		pop hl    ; get string to write
		ld b, STORE_BLOCK_PHY-2       ; exclude count of file id and extent
		ld de, store_page+2

	if DEBUG_STORESE
		DMARK "AP5"
		CALLMONITOR
	endif



		; fill buffer with data until end of string or full block

.appd:		ld a, (hl)
		ld (de), a
		cp 0
		jr z, .appdone
		inc hl
		inc de
		djnz .appd

.appdone:	push hl		 	; save current source in case we need to go around again
		push af   		; save last byte dumped


	ld hl, (store_tmppageid)
	ld de, store_page
	if DEBUG_STORESE
		DMARK "AP6"
		CALLMONITOR
	endif
		call storage_write_block


	; was that a full block of data written?
	; any more to write out?

	; if yes then set vars and jump to start of function again

		pop af
		pop de

		cp 0		 ; no, string was fully written
		ret z

		; setup vars for next cycle

		ld a, (store_tmpid)
		ld l, a
		ld h, 0

	 	jp storage_append	 ; yes, need to write out some more







if DEBUG_STORECF
storageput:	
		ret
storageread:
		ld hl, store_page
		ld b, 200
		ld a,0
.src:		ld (hl),a
		inc hl
		djnz .src
		

		ld de, 0
		ld bc, 1
		ld hl, store_page
		call cfRead

	call cfGetError
	ld hl,scratch
	call hexout
	ld hl, scratch+2
	ld a, 0
	ld (hl),a
	ld de, scratch
	ld a,display_row_1
	call str_at_display
	call update_display

		ld hl, store_page
		ld (os_cur_ptr),hl

		ret
endif


; Clear out the main buffer store (used to remove junk before writing a new block)

storage_clear_page:
	push hl
	push de
	push bc
	ld hl, store_page
	ld a, 0
	ld (hl), a

	ld de, store_page+1
	ld bc, STORE_BLOCK_PHY

	ldir
	
	pop bc
	pop de
	pop hl
	ret

; eof
