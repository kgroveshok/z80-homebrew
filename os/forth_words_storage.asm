


.BYID:
	CWHEAD .BYNAME 38 "BYID" 4 WORD_FLAG_CODE
; | BYID ( u -- s )   Get the name of the file in the current BANK using the file ID u | TODO
		NEXTW
.BYNAME:
	CWHEAD .DIR 38 "BYNAME" 6 WORD_FLAG_CODE
; | BYNAME ( s -- u )   Get the file ID in the current BANK of the file named s | TODO
		NEXTW

.DIR:
	CWHEAD .SAVE 38 "DIR" 3 WORD_FLAG_CODE
; | DIR ( u -- lab id ... c t )   Using bank number u push directory entries from persistent storage as w with count u  | DONE

		if DEBUG_FORTH_WORDS
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
	
		ld a, (store_page)
		ld h, 0
		ld l, a
		call forth_push_numhl

		; push extent count to stack 
	
		ld a, (store_page+2)
		ld h, 0
		ld l, a
		call forth_push_numhl

		; push file name

		ld hl, store_page+3
		if DEBUG_FORTH_WORDS
			DMARK "DI5"
			CALLMONITOR
		endif
		call forth_apushstrhl
		if DEBUG_FORTH_WORDS
			DMARK "DI6"
			CALLMONITOR
		endif
.dirnotfound:
		pop bc    
		djnz .diritem
	
.dirdone:	
		if DEBUG_FORTH_WORDS
			DMARK "DI7"
			CALLMONITOR
		endif

		; push a count of the dir items found

		ld h, 0
		ld l, c
		call forth_push_numhl

		; push the bank label

		call storage_get_block_0

	
 		ld hl, store_page+3

		if DEBUG_FORTH_WORDS
			DMARK "DI8"
			CALLMONITOR
		endif
		call forth_apushstrhl
		;call forth_apush


	
		NEXTW
.SAVE:
	CWHEAD .LOAD 39 "SAVE" 4 WORD_FLAG_CODE
; | SAVE  ( w u -- )    Save user word memory to file name w on bank u | TODO
		NEXTW
.LOAD:
	CWHEAD .BSAVE 40 "LOAD" 4 WORD_FLAG_CODE
; | LOAD ( u -- )    Load user word memory from file id on current bank | TO TEST

		; TODO store_openext use it. If zero it is EOF

		; TODO read block from current stream id
		; TODO if the block does not contain zero term keep reading blocks until zero found
		; TODO push the block to stack
		; TODO save the block id to stream


		FORTH_DSP_VALUEHL

		push hl

	if DEBUG_STORESE
		DMARK "LOA"
		CALLMONITOR
	endif
		FORTH_DSP_POP

		pop hl

		ld h, l
		ld l, 0

		push hl     ; stack holds current file id and extent to work with


		ld de, store_page      ; get block zero of file
	if DEBUG_STORESE
		DMARK "LO0"
		CALLMONITOR
	endif
		call storage_read

		ld a, (store_page+2)    ; max extents for this file
		ld  (store_openmaxext),a   ; get our limit

	if DEBUG_STORESE
		DMARK "LOE"
		CALLMONITOR
	endif

; TODO dont know why max extents are not present
;		cp 0
;		jp z, .loadeof     ; dont read past eof

;		ld a, 1   ; start from the head of the file

.loadline:	pop hl
		inc hl
		ld  a, (store_openmaxext)   ; get our limit
	if DEBUG_STORESE
		DMARK "LOx"
		CALLMONITOR
	endif
		cp l
		jp z, .loadeof
		push hl    ; save current extent

		ld de, store_page

	if DEBUG_STORESE
		DMARK "LO1"
		CALLMONITOR
	endif
		call storage_read

	if DEBUG_STORESE
		DMARK "LO2"
		CALLMONITOR
	endif
	call ishlzero
;	ld a, l
;	add h
;	cp 0
	jr z, .loadeof

	; not eof so hl should point to data to exec

	; will need to add the FORTH_END_BUFFER flag
 
	ld hl, store_page+2
	ld bc, 255
	ld a, 0
	cpir
	if DEBUG_STORESE
		DMARK "LOt"
		CALLMONITOR
	endif
	dec hl
	ld a, ' '
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld a, FORTH_END_BUFFER
	ld (hl), a

	; TODO handle more than a single block read


	ld hl, store_page+2

	if DEBUG_STORESE
		DMARK "LO3"
		CALLMONITOR
	endif

	call forthparse
	call forthexec
	call forthexec_cleanup

	; go to next extent

	; get next block  or mark as eof
	jp .loadline



	       NEXTW
.loadeof:	ld a, 0
		ld (store_openext), a

	if DEBUG_STORESE
		DMARK "LOF"
		CALLMONITOR
	endif
		NEXTW
.BSAVE:  

	CWHEAD .BLOAD 70 "BSAVE" 5 WORD_FLAG_CODE
; | BSAVE  ( w u a s -- )    Save binary file to file name w on bank u starting at address a for s bytes | TODO
		NEXTW
.BLOAD:
	CWHEAD .SEO 71 "BLOAD" 5 WORD_FLAG_CODE
; | BLOAD ( w u a -- )    Load binary file from file name w on bank u into address u | TODO
		NEXTW
;;;; counter gap


.SEO:
	CWHEAD .SEI 80 "SEO" 3 WORD_FLAG_CODE
; | SEO ( u1 u2 -- ) Send byte u1 to Serial EEPROM device at address u2 | DONE

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u2 - byte

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u1 - addr

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop de   ; u1 - byte

		pop hl   ; u2 - addr

		; TODO Send SPI byte


		ld a, e
		call se_writebyte

		

		NEXTW

.SEI:
	CWHEAD .SFREE 81 "SEI" 3 WORD_FLAG_CODE
; | SEI ( u2 -- u1 ) Get a byte from Serial EEPROM device at address u2 | DONE

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl


		; TODO Get SPI byte

		call se_readbyte

		ld h, 0
		ld l, a
		call forth_push_numhl

		NEXTW

.SFREE:
	CWHEAD .SIZE 83 "FFREE" 5 WORD_FLAG_CODE
; | FFREE ( -- n )  Gets number of free file blocks on current storage bank | DONE

		call storage_freeblocks

		call forth_push_numhl

	       NEXTW
.SIZE:
	CWHEAD .CREATE 83 "SIZE" 4 WORD_FLAG_CODE
; | SIZE ( u -- n )  Gets number of blocks used by file id u and push to stack | DONE

		FORTH_DSP_VALUEHL
		push hl
		FORTH_DSP_POP
		pop hl
		call storage_file_size

		call forth_push_numhl
 

	       NEXTW

.CREATE:
	CWHEAD .APPEND 84 "CREATE" 6 WORD_FLAG_CODE
; | CREATE ( u -- n )  Creates a file with name u on current storage bank and pushes the file id number to TOS | DONE

		
;		call storage_get_block_0

		; TODO pop hl

		FORTH_DSP_VALUE

	if DEBUG_STORESE
		DMARK "CRT"
		CALLMONITOR
	endif
		push hl
		FORTH_DSP_POP
		pop hl

		inc hl   ; move past the type marker

		call storage_create

	if DEBUG_STORESE
		DMARK "CT1"
		CALLMONITOR
	endif
		; push file id to stack
		call forth_push_numhl



	       NEXTW

.APPEND:
	CWHEAD .SDEL 85 "APPEND" 6 WORD_FLAG_CODE
; | APPEND ( u n --  )  Appends data u to file id on current storage bank | DONE

		; TODO get id

		FORTH_DSP_VALUEHL
		push hl 	; save file id

	if DEBUG_STORESE
		DMARK "APP"
		CALLMONITOR
	endif
		FORTH_DSP_POP

		FORTH_DSP_VALUE
		push hl 	; save ptr to string to save

	if DEBUG_STORESE
		DMARK "AP1"
		CALLMONITOR
	endif
		FORTH_DSP_POP

		pop de
		pop hl
	if DEBUG_STORESE
		DMARK "AP2"
		CALLMONITOR
	endif
		inc de ; skip var type indicator

		; TODO how to append numerics????

		call storage_append		

	       NEXTW
.SDEL:
	CWHEAD .OPEN 86 "ERA" 4 WORD_FLAG_CODE
; | ERA ( n --  )  Deletes all data for file id n on current storage bank | DONE
		; TODO get id
		; TODO find id blocks
		; TODO   set marker to zero
		; TODO   write buffer
		FORTH_DSP_VALUEHL
		push hl 	; save file id

	if DEBUG_STORESE
		DMARK "ERA"
		CALLMONITOR
	endif
		FORTH_DSP_POP

		pop hl

		call storage_erase
	       NEXTW

.OPEN:
	CWHEAD .READ 87 "OPEN" 4 WORD_FLAG_CODE
; | OPEN ( n -- n )  Sets file id to point to first data page for subsequent READs. Pushes the max number of blocks for this file | DONE

		; TODO handle multiple file opens

	       	ld a, 1
		ld (store_openext), a

		; get max extents for this file
	
					
		FORTH_DSP_VALUEHL

		ld h, l
		ld l, 0
			
		ld de, store_page      ; get block zero of file
		call storage_read

		FORTH_DSP_POP     ; TODO for now just get rid of stream id

		ld a, (store_page+2)    ; max extents for this file
		ld  (store_openmaxext), a   ; get our limit and push
		
		cp 0
		jr nz, .skipopeneof
		; have opened an empty file
		
		ld (store_openext), a

.skipopeneof:

		ld l, a
		ld h, 0
		call forth_push_numhl


	       NEXTW
.READ:
	CWHEAD .EOF 88 "READ" 4 WORD_FLAG_CODE
; | READ ( n -- n  )  Reads next page of file id and push to stack | TESTING - Crashes on second read

		; TODO store_openext use it. If zero it is EOF

		; TODO read block from current stream id
		; TODO if the block does not contain zero term keep reading blocks until zero found
		; TODO push the block to stack
		; TODO save the block id to stream


		FORTH_DSP_VALUEHL

		push hl

	if DEBUG_STORESE
		DMARK "REA"
		CALLMONITOR
	endif
		FORTH_DSP_POP

		pop hl
	
		ld h,l

		ld a, (store_openext)
		ld l, a
		
		cp 0
		jr z, .readeof     ; dont read past eof


		ld de, store_page
	if DEBUG_STORESE
		DMARK "RE1"
		CALLMONITOR
	endif
		call storage_read

	if DEBUG_STORESE
		DMARK "RE2"
		CALLMONITOR
	endif
	call ishlzero
;	ld a, l
;	add h
;	cp 0
	jr z, .readeof

	; not eof so hl should point to data to push to stack

	if DEBUG_STORESE
		DMARK "RE3"
		CALLMONITOR
	endif
	call forth_apushstrhl

	; get next block  or mark as eof

	ld a, (store_openmaxext)   ; get our limit
	ld c, a	
	inc c

		ld a, (store_openext)
	cp c
	jr z, .readeof     ; at last extent

		inc a
		ld (store_openext), a



	       NEXTW
.readeof:	ld a, 0
		ld (store_openext), a

	if DEBUG_STORESE
		DMARK "REF"
		CALLMONITOR
	endif
	       NEXTW
.EOF:
	CWHEAD .FORMAT 89 "EOF" 3 WORD_FLAG_CODE
; | EOF ( n -- u )  Returns EOF logical state of file id n - CURRENTLY n IS IGNORED AND ONLY ONE STREAM IS SUPPORTED | DONE
		; TODO if current block id for stream is zero then push true else false


		; TODO handlue multiple file streams

		FORTH_DSP_POP     ; for now just get rid of stream id

		ld l, 1
		ld a, (store_openmaxext)
		cp 0
		jr  z, .eofdone   ; empty file
		ld a, (store_openext)
		cp 0
		jr  z, .eofdone
		ld l, 0
.eofdone:	ld h, 0
		call forth_push_numhl


	       NEXTW

.FORMAT:
	CWHEAD .LABEL 89 "FORMAT" 6 WORD_FLAG_CODE
; | FORMAT (  --  )  Formats the current bank selected (NO PROMPT!) | DONE
		; TODO if current block id for stream is zero then push true else false
	
		; Wipes the bank check flags to cause a reformat on next block 0 read

		ld hl, 1
		ld a, 1
		call se_writebyte

		; force bank init

		call storage_get_block_0
		
	       NEXTW
.LABEL:
	CWHEAD .LABELS 89 "LABEL" 5 WORD_FLAG_CODE
; | LABEL ( u --  )  Sets the storage bank label to string on top of stack  | DONE
		; TODO test to see if bank is selected
	
		FORTH_DSP_VALUE
		
		push hl
		FORTH_DSP_POP
		pop hl

		inc hl   ; move past the type marker

		call storage_label

	       NEXTW
.LABELS:
	CWHEAD .ENDSTORAGE 89 "LABELS" 6 WORD_FLAG_CODE
; | LABELS (  -- b n .... c  )  Pushes each storage bank labels (n) along with id (b) onto the stack giving count (c) of banks  | DONE
		; 

		; save the current device selected to restore afterwards
	
		ld a, (spi_device)
		push af


		; run through each of the banks

		ld hl, 1
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE0, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_apushstrhl

		
		ld hl, 2
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE1, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_apushstrhl

		
		ld hl, 3
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE2, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_apushstrhl


		ld hl, 4
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE3, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_apushstrhl

		

		ld hl, 5
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE4, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_apushstrhl

		
		; push fixed count of storage devices (on board) for now

		ld hl, 5
		call forth_push_numhl

		; restore selected device 
	
		pop af
		ld (spi_device), a

	       NEXTW

.ENDSTORAGE:
; eof
