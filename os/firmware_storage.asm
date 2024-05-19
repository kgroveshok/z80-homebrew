
; persisent storage hardware abstraction layer 


; TODO get block
; TODO save block
; TODO load file
; TODO save file
; TODO get dir
; TODO format/init storage 


; TODO Redo and treat like a tape drive rather than having random access





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
		pop de

		push af
		ld a, 'R'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
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

		push af
		ld a, 'W'
		ld (debug_mark),a
		pop af
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

		push af
		ld a, 'W'
		ld (debug_mark),a
		pop af
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
		ld de, store_page
		push af
		ld a, 'i'
		ld (debug_mark),a
		pop af
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
		push af
		ld a, 'I'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
	ret

.ininotformatted:
	; bank not formatted so poke various bits to make sure

	if DEBUG_STORESE
		push af
		ld a, 'f'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif

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

	; save default page 0

	ld hl, 0
	ld de, store_page
	if DEBUG_STORESE
		push af
		ld a, 'F'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
	call storage_write_block
	if DEBUG_STORESE
		push af
		ld a, '>'
		ld (debug_mark),a
		pop af
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
		pop bc
		pop hl
		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .setmark2

		


	ret




.defaultbanklabl:   db "BankLabel",0



; Label Bank
; ----------
;
; With current bank
; Read block 0
; Set label
; Write block 0


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
			push af
			ld a, 'F'
			ld (debug_mark),a
			pop af
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
			push af
			ld a, 'n'
			ld (debug_mark),a
			pop af
			CALLMONITOR
		endif
	; no free marks!
		ld hl, 0
	ret
.fffound:
	

		pop de
		pop bc
		pop hl
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

storage_create:
	if DEBUG_STORESE
		push af
		ld a, 'c'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
	push hl
	call storage_get_block_0

	ld a,(store_page)	; get current file id
	inc a
	ld (store_page),a
	
	ld (store_tmpid),a			; save id

	ld hl, 0
	ld de, store_page
	if DEBUG_STORESE
		ld de, store_page
		push af
		ld a, 'w'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
	call storage_write_block	 ; save update

	if DEBUG_STORESE
		ld de, store_page
		push af
		ld a, 'C'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
	; 
	
	ld hl, STORE_BLOCK_PHY
	ld de, 0
	call storage_findnextid

	; hl now contains the free page to use for the file header page

	ld (store_tmppageid), hl
	
	ld a,(store_tmpid)    ; get file id
	ld a, (store_filecache)			; save to cache

	ld (store_page),a    ; set page id

	inc hl 		; init block 0 of file
        ld a, 0
	ld (hl),a
	ld a, (store_filecache+1)  	; save to cache

	inc hl    ; file name
	
	
	ld de, store_page+1    ; get buffer for term string to use as file name
	if DEBUG_STORESE
		push af
		ld a, 'c'
		ld (debug_mark),a
		pop af
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
		push af
		ld a, 'a'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
	ldir    ; copy zero term string
	if DEBUG_STORESE
		push af
		ld a, 'A'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif

	; write file header page

	ld hl,(store_tmppageid)
	ld de, store_page
	if DEBUG_STORESE
		push af
		ld a, 'b'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
	call storage_write_block

	ld a, (store_tmpid)
	ld l, a
	ld h,0
	if DEBUG_STORESE
		push af
		ld a, 'z'
		ld (debug_mark),a
		pop af
		CALLMONITOR
	endif
	ret
	


;
; Append File
;
;

; Read file block


; EOF file id






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



