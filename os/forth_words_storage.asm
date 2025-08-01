
; | ## Fixed Storage Words

.RENAME:
 
	CWHEAD .RECORD 38 "RENAME" 6 WORD_FLAG_CODE
; | RENAME ( s id -- ) With the current bank, rename the file id with the new label s  | DONE
; | | Compatible with PicoSPINet 
		if DEBUG_FORTH_WORDS_KEY
			DMARK "REN"
			CALLMONITOR
		endif


		; preserve some internal vars used by other file handing routines

		ld hl, (store_openaddr)
		push hl
		ld a, (store_readcont)
		push af

		FORTH_DSP_VALUEHL

		; move ext and id around for the file header

		ld h, l
		ld l, 0

		push hl    ; id

		FORTH_DSP_POP

		; Locate the file header

		pop hl
		push hl
		ld de, store_page      ; get block zero of file
		if DEBUG_FORTH_WORDS
			DMARK "REr"
			CALLMONITOR
		endif
		call storage_read

	call ishlzero
	jr nz, .rnfound

	; file does not exist so indicate with 255 extents in use

	ld a, 255
	pop hl ; clear dup hl
	jr .skiprneof


.rnfound:
		; file found so rename

		FORTH_DSP_VALUEHL

	push hl
	ld a, 0
	call strlent
	inc hl   ; cover zero term
	ld b,0
	ld c,l
	pop hl
		ld de, store_page + 3
		ldir

		ld de, store_page
		if DEBUG_FORTH_WORDS
			DMARK "RER"
			CALLMONITOR
		endif

		pop hl    ; get orig file id and mangle it for find id
		ld d, l
		ld e, h

		ld hl, 0
		if DEBUG_FORTH_WORDS
			DMARK "REf"
			CALLMONITOR
		endif
		call storage_findnextid
		ld de, store_page
		if DEBUG_FORTH_WORDS
			DMARK "REw"
			CALLMONITOR
		endif
		call storage_write_block

		ld a, 0
.skiprneof:
		; drop file name
		FORTH_DSP_POP

		ld l, a
		ld h, 0
		call forth_push_numhl


		pop af
		ld (store_readcont),a
		pop hl
		ld (store_openaddr), hl
			
	NEXTW
.RECORD:
 
	CWHEAD .BREAD 38 "RECORD" 6 WORD_FLAG_CODE
; | RECORD ( u id -- s ) With the current bank, read record number u from file id and push to stack  | DONE
; | | Compatible with PicoSPINet 

		if DEBUG_FORTH_WORDS_KEY
			DMARK "REC"
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL

		push hl    ; id

		FORTH_DSP_POP

		FORTH_DSP_VALUEHL

		FORTH_DSP_POP

		pop de     ; get file id

		; e = file id
		; l = file extent


		; construct request to access file extent

;		ld a, e
		ld h, e
		
		
		

		; e has id

	ld de, store_page
		if DEBUG_FORTH_WORDS
			DMARK "REr"
			CALLMONITOR
		endif
		call storage_read
	call ishlzero
	jr z, .recnotfound


		if DEBUG_FORTH_WORDS
			DMARK "REe"
			CALLMONITOR
		endif
	call forth_push_str

		NEXTW

.recnotfound:
		if DEBUG_FORTH_WORDS
			DMARK "REf"
			CALLMONITOR
		endif
	ld hl, 255
	call forth_push_numhl
	NEXTW


.BREAD:
 
	CWHEAD .BWRITE 38 "BREAD" 5 WORD_FLAG_CODE
; | BREAD ( u -- u ) Lowlevel storage word. With the current bank, read a block from page id u (1-512) and push to stack  | DONE
; | | Compatible with PicoSPINet 
	
		if DEBUG_FORTH_WORDS_KEY
			DMARK "BRD"
			CALLMONITOR
		endif

	FORTH_DSP_VALUEHL

	FORTH_DSP_POP

	; calc block address

	ex de, hl
	ld a, STORE_BLOCK_PHY
	call Mult16


	ld de, store_page

		if DEBUG_FORTH_WORDS
			DMARK "BR1"
			CALLMONITOR
		endif

	call storage_read_block

	call ishlzero
	jr nz, .brfound

	call forth_push_numhl
	jr .brdone


.brfound:
        ld hl, store_page+2

		if DEBUG_FORTH_WORDS
			DMARK "BR2"
			CALLMONITOR
		endif

	call forth_push_str


.brdone:

		NEXTW
.BWRITE:
	CWHEAD .BUPD 38 "BWRITE" 6 WORD_FLAG_CODE
; | BWRITE ( s u -- ) Lowlevel storage word. With the current bank, write the string s to page id u | DONE
; | | Compatible with PicoSPINet 

		if DEBUG_FORTH_WORDS_KEY
			DMARK "BWR"
			CALLMONITOR
		endif

	FORTH_DSP_VALUEHL

	; calc block address

	ex de, hl
	ld a, STORE_BLOCK_PHY
	call Mult16

	push hl         ; address

	FORTH_DSP_POP

	FORTH_DSP_VALUEHL

	FORTH_DSP_POP

	call storage_clear_page

	; copy string to store page

	push hl     ; save string address

	ld a, 0
	call strlent

	inc hl

	ld c, l
	ld b, 0

	pop hl
	ld de, store_page + 2
		if DEBUG_FORTH_WORDS
			DMARK "BW1"
			CALLMONITOR
		endif
	ldir


	; poke the start of the block with flags to prevent high level file ops hitting the block

	ld hl, $ffff

	ld (store_page), hl	
	
	pop hl    ; get address
	ld de, store_page

		if DEBUG_FORTH_WORDS
			DMARK "BW2"
			CALLMONITOR
		endif

	call storage_write_block

		NEXTW

.BUPD:
	CWHEAD .BYID 38 "BUPD" 4 WORD_FLAG_CODE
; | BUPD ( u -- ) Lowlevel storage word. Write the contents of the current file system storage buffer directly to page id u | DONE
; | | Coupled with the use of the BREAD, BWRITE and STOREPAGE words it is possible to implement a direct
; | | or completely different file system structure.
; | | Compatible with PicoSPINet 

		if DEBUG_FORTH_WORDS_KEY
			DMARK "BUD"
			CALLMONITOR
		endif

	FORTH_DSP_VALUEHL

	; calc block address

	ex de, hl
	ld a, STORE_BLOCK_PHY
	call Mult16

	FORTH_DSP_POP


	ld de, store_page

		if DEBUG_FORTH_WORDS
			DMARK "BUe"
			CALLMONITOR
		endif

	call storage_write_block

		NEXTW

.BYID:
;	CWHEAD .BYNAME 38 "BYID" 4 WORD_FLAG_CODE
;; > BYID ( u -- s ) Get the name of the file in the current BANK using the file ID u > TODO
;
;		
;		if DEBUG_FORTH_WORDS_KEY
;			DMARK "BYID"
;			CALLMONITOR
;		endif
;
;		; get direct address
;
;		FORTH_DSP_VALUEHL
;
;		FORTH_DSP_POP
;
;	; calc block address
;
;	ex de, hl
;	ld a, STORE_BLOCK_PHY
;	call Mult16
;	;	do BREAD with number as param
;	; push the file name	
;	ld de, store_page
;	call storage_read_block
 ;       ld hl, store_page+2
;
;
;		NEXTW
;.BYNAME:
	CWHEAD .DIR 38 "GETID" 5 WORD_FLAG_CODE
; | GETID ( s -- u ) Get the file ID in the current BANK of the file named s | DONE
; | | Compatible with PicoSPINet 

		; get pointer to file name to seek

		FORTH_DSP_VALUEHL


		call storage_getid 

		FORTH_DSP_POP

		call forth_push_numhl

		NEXTW
;
.DIR:
	CWHEAD .SAVE 38 "DIR" 3 WORD_FLAG_CODE
; | DIR ( u -- lab id ... c t ) Using bank number u push directory entries from persistent storage as w with count u  | DONE
; | | Compatible with PicoSPINet 

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
		call forth_push_str
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
		call forth_push_str


	
		NEXTW
.SAVE:
;	CWHEAD .LOAD 39 "SAVE" 4 WORD_FLAG_CODE
;; > SAVE  ( w u -- )    Save user word memory to file name w on bank u > TODO
;		NEXTW
;.LOAD:
;	CWHEAD .BSAVE 40 "LOAD" 4 WORD_FLAG_CODE
;; > LOAD ( u -- )    Load user word memory from file id on current bank > TODO
;; > > The indivdual records being loaded can be both uword word difintions or interactive commands.
;; > > The LOAD command can not be used in any user words or compound lines.
;
;		; store_openext use it. If zero it is EOF
;
;		; read block from current stream id
;		; if the block does not contain zero term keep reading blocks until zero found
;		; push the block to stack
;		; save the block id to stream
;
;
;		FORTH_DSP_VALUEHL
;
;;		push hl
;
;	if DEBUG_STORESE
;		DMARK "LOA"
;		CALLMONITOR
;	endif
;		FORTH_DSP_POP
;
;;		pop hl
;
;		ld h, l
;		ld l, 0
;
;		push hl     ; stack holds current file id and extent to work with
;
;
;		ld de, store_page      ; get block zero of file
;	if DEBUG_STORESE
;		DMARK "LO0"
;		CALLMONITOR
;	endif
;		call storage_read
;
;		ld a, (store_page+2)    ; max extents for this file
;		ld  (store_openmaxext),a   ; get our limit
;
;	if DEBUG_STORESE
;		DMARK "LOE"
;		CALLMONITOR
;	endif
;
;; TODO dont know why max extents are not present
;;		cp 0
;;		jp z, .loadeof     ; dont read past eof
;
;;		ld a, 1   ; start from the head of the file
;
;.loadline:	pop hl
;		inc hl
;		ld  a, (store_openmaxext)   ; get our limit
;	if DEBUG_STORESE
;		DMARK "LOx"
;		CALLMONITOR
;	endif
;		inc a
;		cp l
;		jp z, .loadeof
;		push hl    ; save current extent
;
;		ld de, store_page
;
;	if DEBUG_STORESE
;		DMARK "LO1"
;		CALLMONITOR
;	endif
;		call storage_read
;
;	if DEBUG_STORESE
;		DMARK "LO2"
;		CALLMONITOR
;	endif
;	call ishlzero
;	ld a, l
;	add h
;	cp 0
;	jr z, .loadeof
;
;	; not eof so hl should point to data to exec
;
;	; will need to add the FORTH_END_BUFFER flag
 ;
;	ld hl, store_page+2
;	ld bc, 255
;	ld a, 0
;	cpir
;	if DEBUG_STORESE
;		DMARK "LOt"
;		CALLMONITOR
;	endif
;	dec hl
;	ld a, ' '
;	ld (hl), a
;	inc hl
;	ld (hl), a
;	inc hl
;	ld (hl), a
;	inc hl
;	ld a, FORTH_END_BUFFER
;	ld (hl), a
;
;	; TODO handle more than a single block read
;
;
;	ld hl, store_page+2
;
;	ld (os_tok_ptr), hl
;
;	if DEBUG_STORESE
;		DMARK "LO3"
;		CALLMONITOR
;	endif
;
;	call forthparse
;	call forthexec
;	call forthexec_cleanup
;
;	; go to next extent
;
;	; get next block  or mark as eof
;	jp .loadline
;
;
;
;	       NEXTW
;.loadeof:	ld a, 0
;		ld (store_openext), a
;
;	if DEBUG_STORESE
;		DMARK "LOF"
;		CALLMONITOR
;	endif
;		ret
;		;NEXTW
;.BSAVE:  
;
;	CWHEAD .BLOAD 70 "BSAVE" 5 WORD_FLAG_CODE
;; > BSAVE  ( w u a s -- )    Save binary file to file name w on bank u starting at address a for s bytes > TODO
;		NEXTW
;.BLOAD:
;	CWHEAD .SEO 71 "BLOAD" 5 WORD_FLAG_CODE
;; > BLOAD ( w u a -- )    Load binary file from file name w on bank u into address u > TODO
;		NEXTW
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

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

;		pop hl


		; TODO Get SPI byte

		call se_readbyte

		ld h, 0
		ld l, a
		call forth_push_numhl

		NEXTW

.SFREE:
	CWHEAD .SIZE 83 "FFREE" 5 WORD_FLAG_CODE
; | FFREE ( -- n )  Gets number of free file blocks on current storage bank | DONE
; | | Compatible with PicoSPINet 
		if DEBUG_FORTH_WORDS_KEY
			DMARK "FFR"
			CALLMONITOR
		endif

		call storage_freeblocks

		call forth_push_numhl

	       NEXTW
.SIZE:
	CWHEAD .CREATE 83 "SIZE" 4 WORD_FLAG_CODE
; | SIZE ( u -- n )  Gets number of blocks used by file id u and push to stack | DONE
; | | Compatible with PicoSPINet 
		if DEBUG_FORTH_WORDS_KEY
			DMARK "SIZ"
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL
;		push hl
		FORTH_DSP_POP
;		pop hl
		call storage_file_size

		call forth_push_numhl
 

	       NEXTW

.CREATE:
	CWHEAD .APPEND 84 "CREATE" 6 WORD_FLAG_CODE
; | CREATE ( u -- n )  Creates a file with name u on current storage bank and pushes the file id number to TOS | DONE
; | | e.g. 
; | | TestProgram CREATE
; | | Top of stack will then be the file ID which needs to be used in all file handling words
; | | 
; | | Max file IDs are 255.
; | | 
; | | Compatible with PicoSPINet 
		
		if DEBUG_FORTH_WORDS_KEY
			DMARK "CRT"
			CALLMONITOR
		endif
;		call storage_get_block_0

		; TODO pop hl

		;v5 FORTH_DSP_VALUE
		FORTH_DSP_VALUE

	if DEBUG_STORESE
		DMARK "CR1"
		CALLMONITOR
	endif
;		push hl
;		FORTH_DSP_POP
;		pop hl

;		inc hl   ; move past the type marker

		call storage_create

	if DEBUG_STORESE
		DMARK "CT1"
		CALLMONITOR
	endif
;		push hl
		FORTH_DSP_POP
;		pop hl
		; push file id to stack
		call forth_push_numhl



	       NEXTW

.APPEND:
	CWHEAD .SDEL 85 "APPEND" 6 WORD_FLAG_CODE
; | APPEND ( u n --  )  Appends data u to file id on current storage bank | DONE
; | | e.g.
; | | Test CREATE      -> $01
; | | "A string to add to file" $01 APPEND
; | | 
; | | The maximum file size currently using 32k serial EEPROMS using 64 byte blocks is 15k.
; | | Compatible with PicoSPINet 
		if DEBUG_FORTH_WORDS_KEY
			DMARK "APP"
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL
		push hl 	; save file id

	if DEBUG_STORESE
		DMARK "AP1"
		CALLMONITOR
	endif
		FORTH_DSP_POP

		FORTH_DSP_VALUEHL
		;v5 FORTH_DSP_VALUE
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
		;inc de ; skip var type indicator

		; TODO how to append numerics????

		call storage_append		

	       NEXTW
.SDEL:
	CWHEAD .OPEN 86 "ERA" 4 WORD_FLAG_CODE
; | ERA ( n --  )  Deletes all data for file id n on current storage bank | DONE
; | | Compatible with PicoSPINet 
		FORTH_DSP_VALUEHL
;		push hl 	; save file id

		if DEBUG_FORTH_WORDS_KEY
			DMARK "ERA"
			CALLMONITOR
		endif
	if DEBUG_STORESE
		DMARK "ER1"
		CALLMONITOR
	endif
		FORTH_DSP_POP

;		pop hl

		call storage_erase
	       NEXTW

.OPEN:
	CWHEAD .READ 87 "OPEN" 4 WORD_FLAG_CODE
; | OPEN ( n -- n )  Sets file id to point to first data page for subsequent READs. Pushes the max number of blocks for this file | DONE
; | | e.g.
; | | $01 OPEN $01 DO $01 READ . LOOP
; | |
; | | Will return with 255 blocks if the file does not exist
; | | Compatible with PicoSPINet 

		if DEBUG_FORTH_WORDS_KEY
			DMARK "OPN"
			CALLMONITOR
		endif
		; TODO handle multiple file opens

	       	ld a, 1
		ld (store_openext), a

		; get max extents for this file
	
					
		FORTH_DSP_VALUEHL

		ld h, l
		ld l, 0

		; store file id

		ld a, h
		ld (store_filecache), a

	if DEBUG_STORESE
		DMARK "OPN"
		CALLMONITOR
	endif
;		push hl
		FORTH_DSP_POP     ; TODO for now just get rid of stream id
;		pop hl
			
		ld de, store_page      ; get block zero of file
		call storage_read
	call ishlzero
	jr nz, .opfound

	; file does not exist so indicate with 255 extents in use

	ld a, 255
	jr .skipopeneof


.opfound:


		ld a, (store_page+2)    ; max extents for this file
		ld  (store_openmaxext), a   ; get our limit and push
		
	if DEBUG_STORESE
		DMARK "OPx"
		CALLMONITOR
	endif
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
; | READ ( -- n  )  Reads next page of current file id and push to stack | DONE
; | | e.g.
; | | $01 OPEN $01 DO READ . LOOP
; | |
; | | As this word only reads one 64 byte block in at a time, if the APPEND word has created extra blocks for the excess, this READ
; | | word is unaware so the long string needs to be joined if the string is a full. A single block read might be what you want,
; | | but if not then writing a word to join blocks will be required. The upshot is a full string will be 62 bytes as the first
; | | two bytes contain the file id and extent.
; | | 
; | | Note: There is a flag that enables/disables long block reads called 'store_longread' and a poke of a non-zero value will
; | | enable the code to automatically read futher blocks if full. It is BUGGY so don't use for now.
; | | Compatible with PicoSPINet 

		if DEBUG_FORTH_WORDS_KEY
			DMARK "REA"
			CALLMONITOR
		endif
		; store_openext use it. If zero it is EOF

		; read block from current stream id
		; if the block does not contain zero term keep reading blocks until zero found
		; push the block to stack
		; save the block id to stream


		call .testeof
		ld a, 1
		cp l
		jp z, .ateof


;		FORTH_DSP_VALUEHL

;		push hl

;	if DEBUG_STORESE
;		DMARK "REA"
;		CALLMONITOR
;	endif
;		FORTH_DSP_POP

;		pop hl
	
		ld a, (store_filecache)
		ld h,a

		ld a, (store_openext)
		ld l, a
		
		cp 0
		jp z, .ateof     ; dont read past eof

		call storage_clear_page

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
	jp z, .readeof

	; not eof so hl should point to data to push to stack

	if DEBUG_STORESE
		DMARK "RE3"
		CALLMONITOR
	endif
	call forth_push_str

	if DEBUG_STORESE
		DMARK "RE4"
		CALLMONITOR
	endif
	; get next block  or mark as eof

	ld a, (store_openmaxext)   ; get our limit
	ld c, a	
	ld a, (store_openext)

	if DEBUG_STORESE
		DMARK "RE5"
		CALLMONITOR
	endif
	cp c
	jr z, .readeof     ; at last extent

		inc a
		ld (store_openext), a

	if DEBUG_STORESE
		DMARK "RE6"
		CALLMONITOR
	endif


	       NEXTW
.ateof:
	;	ld hl, .showeof
	;	call forth_push_str
.readeof:	ld a, 0
		ld (store_openext), a

		
	if DEBUG_STORESE
		DMARK "REF"
		CALLMONITOR
	endif
	       NEXTW

;.showeof:   db "eof", 0


.EOF:
	CWHEAD .FORMAT 89 "EOF" 3 WORD_FLAG_CODE
; | EOF ( -- u )  Returns EOF logical state of current open file id | DONE
; | | e.g.
; | | $01 OPEN REPEAT READ EOF $00 IF LOOP
; | | Compatible with PicoSPINet 
		; TODO if current block id for stream is zero then push true else false

		if DEBUG_FORTH_WORDS_KEY
			DMARK "EOF"
			CALLMONITOR
		endif

		; TODO handlue multiple file streams

;		FORTH_iDSP_POP     ; for now just get rid of stream id
		call .testeof
		call forth_push_numhl


	       NEXTW

.testeof:
		ld l, 1
		ld a, (store_openmaxext)
		cp 0
		jr  z, .eofdone   ; empty file
		ld a, (store_openext)
		cp 0
		jr  z, .eofdone
		ld l, 0
.eofdone:	ld h, 0
		ret




.FORMAT:
	CWHEAD .LABEL 89 "FORMAT" 6 WORD_FLAG_CODE
; | FORMAT (  --  )  Formats the current bank selected (NO PROMPT!) | DONE
; | | Compatible with PicoSPINet 
		; TODO if current block id for stream is zero then push true else false
	
	if DEBUG_STORESE
		DMARK "FOR"
		CALLMONITOR
	endif
		; Wipes the bank check flags to cause a reformat on next block 0 read

		ld hl, 1
		ld a, 0
		call se_writebyte

	if DEBUG_STORESE
		DMARK "FO0"
		CALLMONITOR
	endif
		; force bank init

		call storage_get_block_0
		
	       NEXTW
.LABEL:
	CWHEAD .STOREPAGE 89 "LABEL" 5 WORD_FLAG_CODE
; | LABEL ( u --  )  Sets the storage bank label to string on top of stack  | DONE
; | | Compatible with PicoSPINet 
		; TODO test to see if bank is selected
	
		if DEBUG_FORTH_WORDS_KEY
			DMARK "LBL"
			CALLMONITOR
		endif
;	if DEBUG_STORESE
;		DMARK "LBL"
;		CALLMONITOR
;	endif
		FORTH_DSP_VALUEHL
		;v5FORTH_DSP_VALUE
		
;		push hl
		FORTH_DSP_POP
;		pop hl

;v5		inc hl   ; move past the type marker

	if DEBUG_STORESE
		DMARK "LBl"
		CALLMONITOR
	endif
		call storage_label

	       NEXTW
.STOREPAGE:
	CWHEAD .LABELS 89 "STOREPAGE" 9 WORD_FLAG_CODE
; | STOREPAGE ( -- addr )  Pushes the address of the file system record buffer to stack for direct access  | DONE
; | | Compatible with PicoSPINet 
		; TODO test to see if bank is selected
	
		if DEBUG_FORTH_WORDS_KEY
			DMARK "STP"
			CALLMONITOR
		endif
;	if DEBUG_STORESE
;		DMARK "STP"
;		CALLMONITOR
;	endif

	ld hl, store_page
	call forth_push_numhl


	       NEXTW
.LABELS:
	CWHEAD .SCONST1 89 "LABELS" 6 WORD_FLAG_CODE
; | LABELS (  -- b n .... c  )  Pushes each storage bank labels (n) along with id (b) onto the stack giving count (c) of banks  | TO TEST
; | | *NOT* Compatible with PicoSPINet 
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
		call forth_push_str

		
		ld hl, 2
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE1, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_push_str

		
		ld hl, 3
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE2, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_push_str


		ld hl, 4
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE3, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_push_str

		

		ld hl, 5
		call forth_push_numhl
		ld a, SPI_CE_HIGH
		res SPI_CE4, a
		ld (spi_device), a
		call storage_get_block_0
		ld hl, store_page+3
		call forth_push_str

		
		; push fixed count of storage devices (on board) for now

		ld hl, 5
		call forth_push_numhl

		; restore selected device 
	
		pop af
		ld (spi_device), a

	       NEXTW

.SCONST1:
	CWHEAD .SCONST2 89 "FILEID" 6 WORD_FLAG_CODE
; | FILEID (  -- u1  )  Pushes currently open file ID to stack | DONE
; | | Compatible with PicoSPINet 
		ld a, (store_filecache)
		ld h, 0
		ld l, a
		call forth_push_numhl
		NEXTW
.SCONST2:
	CWHEAD .SCONST3 89 "FILEEXT" 7 WORD_FLAG_CODE
; | FILEEXT (  -- u1  )  Pushes the currently read file extent of the file to stack | DONE
; | | Compatible with PicoSPINet 
		ld a, (store_openext)
		ld h, 0
		ld l, a
		call forth_push_numhl
		NEXTW
.SCONST3:
	CWHEAD .SCONST4 89 "FILEMAX" 7 WORD_FLAG_CODE
; | FILEMAXEXT (  -- u1  )  Pushes the maximum file extent of the currenlty open file to stack | DONE
; | | Compatible with PicoSPINet 
		ld a, (store_openmaxext)
		ld h, 0
		ld l, a
		call forth_push_numhl
		NEXTW
.SCONST4:
	CWHEAD .SCONST5 89 "FILEADDR" 8 WORD_FLAG_CODE
; | FILEADDR (  -- u1  )  Pushes the address of the block accessed for the currenlty open file to stack | DONE
; | | Compatible with PicoSPINet 
		ld hl, (store_openaddr)
		call forth_push_numhl
		NEXTW
.SCONST5:
	CWHEAD .SCONST6 89 "FILEPAGE" 8 WORD_FLAG_CODE
; | FILEPAGE (  -- u1  )  Pushes the page id block accessed for the currenlty open file to stack | DONE
; | | Compatible with PicoSPINet 
		ld hl, (store_openaddr)
		push hl
		pop bc
		ld d, 0
		ld e, STORE_BLOCK_PHY
		call Div16
		push bc
		pop hl
		call forth_push_numhl
		NEXTW
.SCONST6:
	CWHEAD .ENDSTORAGE 89 "READCONT" 8 WORD_FLAG_CODE
; | READCONT (  -- u1  )  Pushes the READ continuation flag to stack | DONE
; | | If the most recent READ results in a full buffer load then this flag is set and will indicate that
; | | a further read should, if applicable, be CONCAT to the previous read.
; | | Compatible with PicoSPINet 
		ld a, (store_readcont)
		ld h, 0
		ld l, a
		call forth_push_numhl
		NEXTW
.ENDSTORAGE:
; eof
