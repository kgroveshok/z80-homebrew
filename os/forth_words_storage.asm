

.DIR:
	CWHEAD .SAVE 38 "DIR" 3 WORD_FLAG_CODE
;
;   db 38                     ;
;	dw .SAVE
;	db 4
;	db "DIR",0               
; |DIR ( u -- lab id ... c t )   Using bank number u push directory entries from persistent storage as w with count u  | DONE

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

		ld a, l
		add h

		cp 0
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
			;push af
			;ld a, '-'
			;ld (debug_mark),a
			;pop af
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
			;push af
			DMARK "DI8"
			;ld a, '='
			;ld (debug_mark),a
			;pop af
			CALLMONITOR
		endif
		call forth_apushstrhl
		;call forth_apush


	
		NEXTW
.SAVE:
	CWHEAD .LOAD 39 "SAVE" 4 WORD_FLAG_CODE
;   db 39
;	dw .LOAD
;	db 5
;	db "SAVE",0              
; |SAVE  ( w u -- )    Save user word memory to file name w on bank u
		NEXTW
.LOAD:
	CWHEAD .BSAVE 40 "LOAD" 4 WORD_FLAG_CODE
;   db 40
;	dw .DAT
;	db 5
;	db "LOAD",0               
;| LOAD ( w u -- )    Load user word memory from file name w on bank u
		NEXTW
.BSAVE:  

	CWHEAD .BLOAD 70 "BSAVE" 5 WORD_FLAG_CODE
; db 70
;	dw .BLOAD
;	db 6
;	db "BSAVE",0              ; |BSAVE  ( w u a s -- )    Save binary file to file name w on bank u starting at address a for s bytes
		NEXTW
.BLOAD:
	CWHEAD .SEO 71 "BLOAD" 5 WORD_FLAG_CODE
;   db 71
;	dw .V0
;	db 6
;	db "BLOAD",0               
;| BLOAD ( w u a -- )    Load binary file from file name w on bank u into address u
		NEXTW
;;;; counter gap


.SEO:
	CWHEAD .SEI 80 "SEO" 3 WORD_FLAG_CODE
;   db 61
;	dw .SPII
;	db 5
;	db "SPIO",0      
;| SEO ( u1 u2 -- ) Send byte u1 to Serial EEPROM device at address u2 |  DONE

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
;   db 62
;	dw .SCROLL
;	db 5
;	db "SPII",0      
;| SEI ( u2 -- u1 ) Get a byte from Serial EEPROM device at address u2 |  DONE

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
	CWHEAD .CREATE 83 "SFREE" 5 WORD_FLAG_CODE
;| SFREE ( -- n )  Gets number of blocks free on current storage bank | DONE

		call storage_freeblocks

		call forth_push_numhl

	       NEXTW

.CREATE:
	CWHEAD .APPEND 84 "CREATE" 6 WORD_FLAG_CODE
;| CREATE ( u -- n )  Creates a file with name u on current storage bank and pushes the file id number to TOS | DONE

		
;		call storage_get_block_0

		; TODO pop hl

		FORTH_DSP_VALUE

	if DEBUG_STORESE
;		push af
		DMARK "CRT"
;		ld (debug_mark),a
;		pop af
		CALLMONITOR
	endif
		push hl
		FORTH_DSP_POP
		pop hl

		inc hl   ; move past the type marker

		call storage_create

	if DEBUG_STORESE
		DMARK "CT1"
		;push af
		;ld a, '='
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif
		; push file id to stack
		call forth_push_numhl



	       NEXTW

.APPEND:
	CWHEAD .SDEL 85 "APPEND" 6 WORD_FLAG_CODE
;| APPEND ( u n --  )  Appends data u to file id on current storage bank |

		; TODO get id

		FORTH_DSP_VALUEHL
		push hl 	; save file id

	if DEBUG_STORESE
		DMARK "APP"
		;push af
		;ld a, '='
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif
		FORTH_DSP_POP

		FORTH_DSP_VALUE
		push hl 	; save ptr to string to save

	if DEBUG_STORESE
		DMARK "AP1"
		;push af
		;ld a, '='
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif
		FORTH_DSP_POP

		pop de
		pop hl
	if DEBUG_STORESE
		DMARK "AP2"
		;push af
		;ld a, '='
		;ld (debug_mark),a
		;pop af
		CALLMONITOR
	endif
		inc de ; skip var type indicator

		; TODO how to append numerics????

		call storage_append		

	       NEXTW
.SDEL:
	CWHEAD .OPEN 86 "ERA" 4 WORD_FLAG_CODE
;| ERA ( n --  )  Deletes all data for file id n on current storage bank | DONE
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
;| OPEN ( n --  )  Sets file id to point to first data page for subsequent READs - CURRENTLY n IS IGNORED AND ONLY ONE STREAM IS SUPPORTED | DONE

		; TODO handle multiple file opens
		FORTH_DSP_POP     ; for now just get rid of stream id

	       	ld a, 1
		ld (store_openext), a
			

	       NEXTW
.READ:
	CWHEAD .EOF 88 "READ" 4 WORD_FLAG_CODE
;| READ ( n -- n  )  Reads next page of file id and push to stack |

		; TODO store_openext use it. If zero it is EOF

		; TODO read block from current stream id
		; TODO if the block does not contain zero term keep reading blocks until zero found
		; TODO push the block to stack
		; TODO save the block id to stream

	       NEXTW
.EOF:
	CWHEAD .FORMAT 89 "EOF" 3 WORD_FLAG_CODE
;| EOF ( n -- u )  Returns EOF logical state of file id n - CURRENTLY n IS IGNORED AND ONLY ONE STREAM IS SUPPORTED | DONE
		; TODO if current block id for stream is zero then push true else false


		; TODO handlue multiple file streams

		FORTH_DSP_POP     ; for now just get rid of stream id

		ld l, 1
		ld a, (store_openext)
		cp 0
		jr  z, .eofdone
		ld l, 0
.eofdone:	ld h, 0
		call forth_push_numhl


	       NEXTW

.FORMAT:
	CWHEAD .ENDSTORAGE 89 "FORMAT" 6 WORD_FLAG_CODE
;| FORMAT (  --  )  Formats the current bank selected (NO PROMPT!) |
		; TODO if current block id for stream is zero then push true else false
	
		; Wipes the bank check flags to cause a reformat on next block 0 read

		ld hl, 1
		ld a, 1
		call se_writebyte

		; force bank init

		call storage_get_block_0
		
	       NEXTW

.ENDSTORAGE:
; eof