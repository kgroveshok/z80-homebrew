
; persisent storage hardware abstraction layer 


; TODO get block
; TODO save block
; TODO load file
; TODO save file
; TODO get dir
; TODO format/init storage 


; Block 0 on storage is a config state


; TODO move these to hardware driver file

STORE_BLOCK_PHY:   equ 64     ; physical block size on storage   64byte on 256k eeprom
STORE_DEVICE_MAXBLOCKS:  equ  512 ; how many blocks are there on this storage device
; TODO add read phy block and write phy block functions
; TODO add presence check (i.e. read write byte 0 of block 0 for eeprom)

; Abstraction layer 
STORE_BLOCK_LOG:  equ   255     ; Logical block size

STORE_BLOCK_PHY2LOG: equ (STORE_BLOCK_LOG/STORE_BLOCK_PHY)       ; How many physical blocks make up a logical block
STORE_BLOCK_MAX: equ (STORE_BLOCK_PHY*STORE_DEVICE_MAXBLOCKS)/255    ; Max number of logical blocks on the device



; Filesystem layout (Logical layout)
;
; Block 0 - Bank config 
;
;      Byte - 0 bank presence test
;      Byte - 1-2 formated: Byte pattern: 0x80 x27
;      Byte - 3-4 file id counter
;      Byte - 5-20 zero terminated bank label
;
; Block 1 > File storage
;
;      Byte 0-1 file id
;           Byte 2 - File type flags:   bit 0-First block. 1-Forth Word else other data type
;
;           Of first block of file:
;
;           Byte 3-15 - File name
;
;       - end of block data
;


; Read Logical Block
; ------------------
;
; With current bank
; 
; Get block number to read
; Start Block = Logical block required * STORE_BLOCK_PHY2LOG
; Load physical blocks starting at start block into buffer


; Write Logical Block
; -------------------
;
; With current bank
; 
; Get block number to write
; Start Block = Logical block required * STORE_BLOCK_PHY2LOG
; Write physical blocks starting at start block from buffer
 

; Init bank
; ---------
;
; With current bank
;
; Setup block 0 config
;     Set formatted byte pattern
;     Set 0 file id counter
;     Zero out bank label
;     
; For every logical block write 0-1 byte as null


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




;
; Append File
;
;

; Read file block



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



