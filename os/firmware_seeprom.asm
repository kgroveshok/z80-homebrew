;
; persisent storage interface via microchip serial eeprom

; port a pio 2
; pa 7 - si
; pa 6 - sclk 
; pa 5 - so
; pa 4 - cs
; pa 3 - cs
; pa 2 - cs
; pa 1 - cs
; pa 0 - cs
;
; TODO get block
; TODO save block
; TODO load file
; TODO save file
; TODO get dir 

; 
storage_adata: equ Device_C    ; device c port a - onboard storage
storage_actl: equ Device_C+2     ; device c port a
storage_bdata: equ Device_C+1    ; device c port b - ext storage cart
storage_bctl: equ Device_C+3     ; device c port b


; TODO move these to hardware driver file

STORE_BLOCK_PHY:   equ 64    ; physical block size on storage   64byte on 256k eeprom
STORE_DEVICE_MAXBLOCKS:  equ  512 ; how many blocks are there on this storage device
; storage bank file system format
;
; first page of bank:
; 	addr 0 - status check
;       addr 1 - write protect flag
;       addr 2 - zero if all data is held on this device. >0 - next device number (not used right now)
;       addr 3 - last file id (to save on scanning for spare file id). or could have bit mask of file ids in use???? 
;         TODO see if scanning whole of for available next file id is fast enough
;	addr 4 > zero term string of bank label
;
;       
; 
; first page of any file:
;      byte 0 - file id 
;      byte 1-17 - fixed file name 
;      byte 18-end of page - extra meta data tba (date? description? keywords?)
;
; other pages of any file:
;      byte 0 - file id
;      byte 1> - file data
;
; TODO depending on how long it takes to load a file in if scanning the whole bank for the file id, could speed it up by having last file page flag??? high bit? that would max 127 files
; 
; TODO need a bank format which places a 0 in each of the first byte of every page and updates the meta in page 0


;storage_so_bit: 5
;storage_si_bit: 7
;storage_sclk_bit: 6
 

; init storage pio

storage_init:

            LD   A, 11001111b
            OUT  (storage_actl), A  ;Port A = PIO 'control' mode
            LD   A, 00000000b
	set SPI_DO,a
;            LD   A, SPI_DO      ; only one input line  the rest are outputs
            OUT  (storage_actl),A   ;Port A = all lines are outputs

            LD   A, 11001111b
            OUT  (storage_bctl), A  ;Port A = PIO 'control' mode
            LD   A, 00000000b
            OUT  (storage_bctl),A   ;Port A = all lines are outputs

	; set all external spi devices off
	ld a, 0
	ld (spi_device), a
	ld (spi_cartdev), a

		; ensure the spi bus is in a default stable state
		call se_stable_spi

; TODO scan spi bus and gather which storage banks are present

; populate store_bank_active 
; for each ce line activate and attempt to write first byte of bank and read back
; if zero is returned then bank is empty
;  
;

		; init file extent cache to save on slow reads

;	ld hl, store_filecache
;	ld de, 0
;	ld hl,(de)	


    ret

store_read_ins: equ 000000011b   ; Read data from memory array beginning at selected address
store_write_ins: equ 000000010b  ;  Write data to memory array beginning at selected address
store_wren_ins: equ 000000110b   ;  Set the write enable latch (enable write operations)

; INSTRUCTION SET
; READ 0000 0011 Read data from memory array beginning at selected address
; WRITE 0000 0010 Write data to memory array beginning at selected address
; WREN 0000 0110 Set the write enable latch (enable write operations)
; WRDI 0000 0100 Reset the write enable latch (disable write operations)
; RDSR 0000 0101 Read STATUS register
; WRSR 0000 0001 Write STATUS register
; PE 0100 0010 Page Erase – erase one page in memory array
; SE 1101 1000 Sector Erase – erase one sector in memory array
; CE 1100 0111 Chip Erase – erase all sectors in memory array
; RDID 1010 1011 Release from Deep power-down and read electronic signature

; TODO send byte steam for page without setting the address for every single byte
; TODO read byte 

; byte in a
; address in hl 
se_writebyte:
       
    ;   ld c, a
        push af
        push hl

    ; initi write mode
    ;
    ;CS low

       ld a,(spi_portbyte)
	call spi_ce_low
       ;res SPI_CE0,a           ; TODO pass the ce bank bit mask
       out (storage_adata),a
       ld (spi_portbyte), a

    ;clock out wren instruction

    ld a, store_wren_ins
    call spi_send_byte 

    ;cs high to enable write latch

       ld a,(spi_portbyte)
	call spi_ce_high
;       set SPI_CE0,a           ; TODO pass the ce bank bit mask
       out (storage_adata),a
       ld (spi_portbyte), a

	nop
    ;
    ; intial write data
    ;
    ; cs low
    
       ld a,(spi_portbyte)
	call spi_ce_low
       ;res SPI_CE0,a           ; TODO pass the ce bank bit mask
       out (storage_adata),a
       ld (spi_portbyte), a

    ; clock out write instruction
    
    ld a, store_write_ins 
    call spi_send_byte 

    ; clock out address (depending on address size)
    
    pop hl
    ld a,h    ; address out msb first
    call spi_send_byte 
    ld a,l
    call spi_send_byte 

    ; clock out byte(s) for page

    pop af
    call spi_send_byte 

    ; end write with ce high
       ld a,(spi_portbyte)
;       set SPI_CE0,a           ; TODO pass the ce bank bit mask - perhaps have a call that sets it
	call spi_ce_high
       out (storage_adata),a
       ld (spi_portbyte), a

	; pause for internal write cycle
	ld a, 10
	call aDelayInMS
    ret

; buffer to write in de
; address in hl 
se_writepage:
       
    ;   ld c, a
	push de
        push hl

    ; initi write mode
    ;
    ;CS low

       ld a,(spi_portbyte)
	call spi_ce_low
       ;res SPI_CE0,a           ; TODO pass the ce bank bit mask
       out (storage_adata),a
       ld (spi_portbyte), a

    ;clock out wren instruction

    ld a, store_wren_ins
    call spi_send_byte 

    ;cs high to enable write latch

       ld a,(spi_portbyte)
	call spi_ce_high
       ;set SPI_CE0,a           ; TODO pass the ce bank bit mask
       out (storage_adata),a
       ld (spi_portbyte), a

	nop
    ;
    ; intial write data
    ;
    ; cs low
    
       ld a,(spi_portbyte)
       ;res SPI_CE0,a           ; TODO pass the ce bank bit mask
	call spi_ce_low
       out (storage_adata),a
       ld (spi_portbyte), a

    ; clock out write instruction
    
    ld a, store_write_ins 
    call spi_send_byte 

    ; clock out address (depending on address size)
    
    pop hl
    ld a,h    ; address out msb first
    call spi_send_byte 
    ld a,l
    call spi_send_byte 

    ; clock out byte(s) for page

	pop hl
	ld b, STORE_BLOCK_PHY
.bytewrite:

	ld a,(hl)
    push hl
	push bc
    call spi_send_byte 
	pop bc
	pop hl

    ; end write with ce high
       ld a,(spi_portbyte)
	call spi_ce_high
;       set SPI_CE0,a           ; TODO pass the ce bank bit mask - perhaps have a call that sets it
       out (storage_adata),a
       ld (spi_portbyte), a

	inc hl
	djnz .bytewrite

	; pause for internal write cycle
	ld a, 100
	call aDelayInMS
    ret
; returns byte in a
; address in hl 
se_readbyte:
       
    ;   ld c, a
        push hl

    ; initi write mode
    ;
    ;CS low

       ld a,(spi_portbyte)
	call spi_ce_low
       ;res SPI_CE0,a           ; TODO pass the ce bank bit mask
       out (storage_adata),a
       ld (spi_portbyte), a

    ;clock out wren instruction

    ld a, store_read_ins
    call spi_send_byte 


    ; clock out address (depending on address size)
    
    pop hl
    ld a,h    ; address out msb first
    call spi_send_byte 
    ld a,l
    call spi_send_byte 

    ; clock in byte(s) for page

    call spi_read_byte 
	push af

    ; end write with ce high
       ld a,(spi_portbyte)
;       set SPI_CE0,a           ; TODO pass the ce bank bit mask - perhaps have a call that sets it
	call spi_ce_high
       out (storage_adata),a
       ld (spi_portbyte), a

	pop af

    ret

if DEBUG_STORESE

storageput: 

; get address (so long as it is in first page due to reload otherwise use prom programmer to see if)

	ld hl,scratch+2
	call get_word_hl

	; stuff it here for the moment as it will be overwritten later anyway

	ld (os_cur_ptr),hl	


; get pointer to start of string

	ld hl, scratch+7

; loop writing char of string to eeprom

.writestr:	ld a,(hl)
		cp 0
		jr z, .wsdone		; done writing
		push hl
		ld hl,(os_cur_ptr)
		call se_writebyte

		ld hl,(os_cur_ptr)	 ; save next eeprom address
		inc hl
		ld (os_cur_ptr),hl

		; restore string pointer and get next char

		pop hl
		inc hl
		jr .writestr



.wsdone:


; when done load first page into a buffer 

		ld hl,08000h		; start in ram
		ld (os_cur_ptr),hl
		ld hl, 0		 ; start of page
		ld (scratch+40),hl	; hang on to it

		ld b, 128		; actually get more then one page
.wsload:	push bc
		ld hl,(scratch+40)
		push hl
		call se_readbyte

		; a now as the byte

		ld hl,(os_cur_ptr)
		ld (hl),a
		; inc next buffer area
		inc hl
		ld (os_cur_ptr),hl

		; get eeprom position, inc and save for next round
		pop hl		
		inc hl
		ld (scratch+40),hl
		pop bc
		djnz .wsload

; set 'd' pointer to start of buffer

		ld hl,08000h
		ld (os_cur_ptr),hl


ret


storageread: ret






endif



