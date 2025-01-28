; persisent storage hardware abstraction layer 



; Block 0 on storage is a config state


; Abstraction layer 

; Logocial block size is same size as physical size - using tape concept

;STORE_BLOCK_PHY2LOG: equ (STORE_BLOCK_LOG/STORE_BLOCK_PHY)       ; How many physical blocks make up a logical block
;STORE_BLOCK_MAX: equ (STORE_BLOCK_PHY*STORE_DEVICE_MAXBLOCKS)/255    ; Max number of logical blocks on the device



; Filesystem layout (Logical layout)
;
; Block 0 - Bank config 
;
;      Byte 0-1 formated byte pattern: 0x80 x27
;      Byte 2-20 zero terminated bank label
;
; Block 1-33 - Directory table
;
;      Block number is file id
;
;      Byte 0 - Zero is table entry free
;      Byte 1 - Last file block
;      Byte 2-20 - File name/meta data
;
; Block 34 => File storage

;      Byte 0 file id:
;                0 - block is free
;                up to 32 is the file id, 33 > file block counter
;      Byte 1 >= block data
;


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
		DMARK "SRB"
		CALLMONITOR
	endif
.rl1:   

;	if DEBUG_STORESE
;		DMARK "SRb"
;		CALLMONITOR
;	endif
	; read physical block at hl into de
        ; increment hl and de to next read position on exit

;	ld a, 10
;	call aDelayInMS

	push hl
	push de	
	push bc
	call se_readbyte
	pop bc
	pop de
	pop hl
	ld (de),a
	inc hl
	inc de



	djnz .rl1

	ret	
	

; TODO File Size
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

		CALLMONITOR
	endif


.wl1:   

	; read physical block at hl into de
        ; increment hl and de to next read position on exit

	push hl
	push de	
	push bc
	ld a,(de)
	call se_writebyte
	nop
	nop
	nop
	pop bc
	pop de
	pop hl
	inc hl
	inc de


	djnz .wl1

	if DEBUG_STORESE
		DMARK "SW2"

		CALLMONITOR
	endif
	ret	

; Init bank
; ---------
;
; With current bank
;
; Block 0 - Bank config 
;
;      Byte 0-1 formated byte pattern: 0x80 x27
;      Byte 2-20 zero terminated bank label
;
; Block 1-33 - Directory table
;
;      Block number is file id
;
;      Byte 0 - Zero is table entry free
;      Byte 1 - Last file block
;      Byte 2-20 - File name/meta data

storage_get_block_0:

	; TODO check presence

	if DEBUG_STORESE
		DMARK "SB0"
		ld de, store_page
		CALLMONITOR
	endif

	; get block 0 config

	ld hl, 0
	ld de, store_page
	call storage_read_block

	; is this area formatted?
	ld hl, (store_page+STORE_BK0_ISFOR)

	if DEBUG_STORESE
		DMARK "SBr"
		ld de, store_page
		CALLMONITOR
	endif


;      Byte 0-1 formated byte pattern: 0x80 x27
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
		CALLMONITOR
	endif
	ret

.ininotformatted:
	; bank not formatted so poke various bits to make sure

	if DEBUG_STORESE
		DMARK "SBi"
		CALLMONITOR
	endif

	call storage_clear_page

	; init the format label

	ld hl, 0x2780     ;      Byte - 0-1 formated: Byte pattern: 0x80 x27
 	ld (store_page+STORE_BK0_ISFOR), hl	

	if DEBUG_STORESE
		DMARK "SBz"
		CALLMONITOR
	endif
	; set default label

	ld hl, .defaultbanklabl
 	ld de, store_page+STORE_BK0_LABEL
	ld bc, 15
	if DEBUG_STORESE
		DMARK "SBx"
		CALLMONITOR
	endif
	ldir

	; save default page 0

	ld hl, 0
	ld de, store_page
	if DEBUG_STORESE
		DMARK "SB3"
		CALLMONITOR
	endif
	call storage_write_block

	if DEBUG_STORESE
		DMARK "Fbs"
		CALLMONITOR
	endif

	nop
	nop
	nop

	; now set 0 in every directory entry and file block to mark as a free block

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

	; re-enter to get empty file system
		
	jp storage_get_block_0



.defaultbanklabl:   db "DefaultLabel",0



; OK Label Bank
; ----------
;
; With current bank
; Read block 0
; Set label
; Write block 0

; label str pointer in hl

storage_label:    

	if DEBUG_STORESE
		DMARK "SBL"
		CALLMONITOR
	endif

	push hl

	call storage_get_block_0

	; set default label

	pop hl

 	ld de, store_page+STORE_BK0_LABEL
	ld bc, 20       ; TODO actual length
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


; TODO Dir
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


; TODO Delete File
; -----------
;
; With current bank
;
; Zero directory entry in block id
; For each file logical block
;    Read block file id byte
;      If file id is one saved
;         Null file id
;         Write this byte back

storage_erase:

	; hl contains the file id

		if DEBUG_FORTH_WORDS
			DMARK "ERA"
			CALLMONITOR
		endif

	; TODO calc directory entry block number
	; TODO write zero to entry marker
	
	; TODO from start of file data blocks until end of storage
	; TODO get block marker
	; TODO if block marker is file id write zero


	ret


; Calculate the single byte mask for the block id from:
; e contains the file id to locate
; d contains the block number

.calcblockmask: 
		ld a, d
	        add STORE_DATA_START
		add e	
		ret

; TODO TEST Find Free Block
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

	call .calcblockmask

store_findnextrawid:        ; entry point if already got a mask

	ld e, a    ; save the mask to locate

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
		pop de
		push de
		cp e
		jr z, .fffound

		pop de
		pop bc
		pop hl

		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .ff1

	ld b, STORE_DEVICE_MAXBLOCKS/2
.ff2:   	

		push hl
		push bc
		push de
		call se_readbyte
		pop de
		push de
		cp e
		jr z, .fffound

		pop de
		pop bc
		pop hl

		ld a, STORE_BLOCK_PHY
		call addatohl
		djnz .ff2


		if DEBUG_FORTH_WORDS
		DMARK "FN-"
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
			CALLMONITOR
		endif
	ret



; TODO Free Space
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

; TODO sub dir entries

	ret

; TODO Get File ID
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




; OK Create File
; -----------
;
; With current bank 
; Find free dir block
; Set buffer with file name and file id
; Write buffer to free block 


; hl point to file name
; hl returns file id



storage_create:
	if DEBUG_STORESE
		DMARK "SCR"
		CALLMONITOR
	endif

	ld (store_tmp1), hl		; save file name pointer

	call storage_get_block_0

; TODO find spare dir entry space
; TODO if dir is full return HL=0


	ld b, STORE_DIR_START
	ld hl, STORE_BLOCK_PHY

	if DEBUG_STORESE
		DMARK "SCs"
		CALLMONITOR
	endif
.scdirscan:
;	push bc   
	call se_readbyte
	if DEBUG_STORESE
		DMARK "Sf?"
		CALLMONITOR
	endif
	cp STORE_DIR_FREE
	jr z, .dirfree
	ld de, STORE_BLOCK_PHY
	add hl, de	; next block
;	pop bc
	ld a, STORE_DIR_END
	cp b
	jr z, .nodirfree
	inc b
	jr .scdirscan

.nodirfree: 

	if DEBUG_STORESE
		DMARK "SCn"
		CALLMONITOR
	endif
		  ; no spare dir space left so return error
		;pop hl     ; get rid of file name pointer
		 ld hl, 0
		ret

; directory space is spare so create a file entry for it
; hl will have the block number handy so can just prep the file dir entry here

.dirfree:
	if DEBUG_STORESE
		DMARK "SCf"
		CALLMONITOR
	endif

;hl address?  80
;de starting location/  40
;bc dir id   0101


	call storage_clear_page

	ld a, STORE_DIR_FILE       ; TODO could have different file type attributes e.g. plain file, db, config, exec code
	ld (store_page),a    ; mark dir entry as in use
	ld (store_tmp2), bc     ; save the file block id for saving into later
	ld (store_tmp3), hl     ; save the file block address for saving into later
	ld hl,(store_tmp1)     ; get the file name pointer

	ld a, 0
	if DEBUG_STORESE
		DMARK "SCl"
		CALLMONITOR
	endif
	call strlent
	inc hl   ; cover zero term
	ld b,0
	ld c,l
	ld hl,(store_tmp1)     ; get the file name pointer
	ld de, store_page+STORE_DE_FILENAME   ; file name data dest
	;ex de, hl
	if DEBUG_STORESE
		DMARK "SCa"
		CALLMONITOR
	endif
	ldir    ; copy zero term string
	if DEBUG_STORESE
		DMARK "SCA"
		CALLMONITOR
	endif

	; write data ext count for new file which is zero

	ld a, 0
	ld (store_page+STORE_DE_MAXEXT), a

	; write directory entry

;	pop hl    ; get file entry found 
	ld hl, (store_tmp3)     ; save the file block address for saving into later
	ld de, store_page
	if DEBUG_STORESE
		DMARK "SCb"
		CALLMONITOR
	endif
	call storage_write_block

	; return the file id to caller in hl

	ld a, (store_tmp2+1)     ; in b of bc
	ld l, a
	ld h, 0
	if DEBUG_STORESE
		DMARK "SCe"
		CALLMONITOR
	endif
	ret
	


;
; TODO Read File
;
; h - file id to locate
; l - extent to locate
; de - pointer to string to read into
;
; returns hl is 0 if block not found ie end of file or pointer to start of data read
storage_read:
	push de

; TODO BUG the above push is it popped before the RET Z?

; TODO how to handle multiple part blocks

	; locate file extent to read

	ld e, h
	ld d, l
	ld hl, STORE_BLOCK_PHY
	call storage_findnextid

	call ishlzero
;	ld a, l
;	add h
;	cp 0
; TODO is stack push of DE not balanced?

	jr c, .srateof			; block not found so EOF

	; hl contains page number to load
	pop de   ; get storage
;	push de
	call storage_read_block


; TODO if block has no zeros then need to read next block 


		
	pop hl 		 ; return start of data to show as not EOF
	inc hl   ; past file id
	inc hl   ; past ext
		ret

.srateof:  pop de
	ret

;
; TODO TEST Append File
;
; hl - file id to locate
; de - pointer to (multi block) string to write


storage_append:
	; hl -  file id to append to
	; de - string to append

	ld a, l
	ld (store_tmp1), a

	ld (store_tmp2), de
	
	if DEBUG_STORESE
		DMARK "AP1"
		CALLMONITOR
	endif


	; get dir entry for id
	; get current max ext count

	ld a, l 
	;add STORE_DIR_START
 	ld de, STORE_BLOCK_PHY 
	call Mult16       ; hl has the byte location for the start of the dir entry
        inc hl   ; move to the ext count  
	push hl

	if DEBUG_STORESE
		DMARK "APX"
		CALLMONITOR
	endif
	call se_readbyte

	; inc max extent count

	inc a
	ld (store_tmp3), a

	; save current max ext count

	pop hl
	if DEBUG_STORESE
		DMARK "APx"
		CALLMONITOR
	endif
	call se_writebyte

	; find empty file block

	ld a, 0
	call store_findnextrawid

	push hl   ; save new block location
	if DEBUG_STORESE
		DMARK "APb"
		CALLMONITOR
	endif

	; TODO check for no spare blocks

	; with max extent set file data block id

	call storage_clear_page

	ld hl, store_page
	ld a, (store_tmp3)
	ld (hl), a

	if DEBUG_STORESE
		DMARK "APi"
		CALLMONITOR
	endif

	; copy the data to buffer

	ld de, (store_tmp2)
	ex de, hl
	
	push hl ; save string start
	ld a, 0
	call strlent
	inc l    ; zero term
	ld c, l
	ld b, 0
	pop hl
	ldir        ; copy string
	
	; write buffer block

	ld hl, (store_tmp2)
	ld de, store_page

	if DEBUG_STORESE
		DMARK "APe"
		CALLMONITOR
	endif

	call storage_write_block

; TODO include code below to handle writing more than a buffer full

	ret



;
;
;	ld a, l
;
;	; get file header 
;
;	ld d, 0			 ; file extent to locate - file name details at item 0
;	ld a, (store_tmpid)
;	ld e, a
;
;		ld hl, STORE_BLOCK_PHY
;		call storage_findnextid
;
;	ld (store_tmppageid), hl
;
;	; TODO handle file id not found
;
;	if DEBUG_STORESE
;		DMARK "AP2"
;		CALLMONITOR
;	endif
;
;	; update file extent count
;
;	ld de, store_page
;
;	call storage_read_block
;
;	if DEBUG_STORESE
;		DMARK "AP3"
;		CALLMONITOR
;	endif
;;	ld (store_tmppageid), hl
;
;	ld a, (store_page+2)
;	inc a
;	ld (store_page+2), a
;	ld (store_tmpext), a
;	
;	if DEBUG_STORESE
;		DMARK "AP3"
;		CALLMONITOR
;	endif
;	ld hl, (store_tmppageid)
;	ld de, store_page
;	call storage_write_block
;
;	; find free block
;
;	ld de, 0			 ; file extent to locate
;
;		ld hl, STORE_BLOCK_PHY
;		call storage_findnextid
;
;		; TODO handle no space left
;		
;		ld (store_tmppageid), hl
;
;	if DEBUG_STORESE
;		DMARK "AP4"
;		CALLMONITOR
;	endif
;		; init the buffer with zeros so we can id if the buffer is full or not
;
;		push hl
;		push bc
;
;		ld hl, store_page
;		ld b, STORE_BLOCK_PHY
;		ld a, 0
;.zeroblock:	ld (hl), a
;		inc hl
;		djnz .zeroblock
;
;		pop bc
;		pop hl
;
;		; construct block
;
;		ld a, (store_tmpid)
;		ld (store_page), a   ; file id
;		ld a, (store_tmpext)   ; extent for this block
;		ld (store_page+1), a
;
;		pop hl    ; get string to write
;		ld b, STORE_BLOCK_PHY-2       ; exclude count of file id and extent
;		ld de, store_page+2
;
;	if DEBUG_STORESE
;		DMARK "AP5"
;		CALLMONITOR
;	endif
;
;
;
;		; fill buffer with data until end of string or full block
;
;.appd:		ld a, (hl)
;		ld (de), a
;		cp 0
;		jr z, .appdone
;		inc hl
;		inc de
;		djnz .appd
;
;.appdone:	push hl		 	; save current source in case we need to go around again
;		push af   		; save last byte dumped
;
;
;	ld hl, (store_tmppageid)
;	ld de, store_page
;	if DEBUG_STORESE
;		DMARK "AP6"
;		CALLMONITOR
;	endif
;		call storage_write_block
;
;
;	; was that a full block of data written?
;	; any more to write out?
;
;	; if yes then set vars and jump to start of function again
;
;		pop af
;		pop de
;
;		cp 0		 ; no, string was fully written
;		ret z
;
;		; setup vars for next cycle
;
;		ld a, (store_tmpid)
;		ld l, a
;		ld h, 0
;
;	 	jp storage_append	 ; yes, need to write out some more
;
;
;
;
;
;
;
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


; eof
