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


;storage_so_bit: 5
;storage_si_bit: 7
;storage_sclk_bit: 6
 

; init storage pio

storage_init:

            LD   A, 11001111b
            OUT  (storage_actl), A  ;Port A = PIO 'control' mode
            LD   A, 00000000b
;            LD   A, SPI_DO      ; only one input line  the rest are outputs
            OUT  (storage_actl),A   ;Port A = all lines are outputs

		; ensure the spi bus is in a default stable state
		call se_stable_spi
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
       res SPI_CE0,a           ; TODO pass the ce bank bit mask
       out (storage_adata),a
       ld (spi_portbyte), a

    ;clock out wren instruction

    ld a, store_wren_ins
    call spi_send_byte 

    ;cs high to enable write latch

       ld a,(spi_portbyte)
       set SPI_CE0,a           ; TODO pass the ce bank bit mask
       out (storage_adata),a
       ld (spi_portbyte), a

	nop
    ;
    ; intial write data
    ;
    ; cs low
    
       ld a,(spi_portbyte)
       res SPI_CE0,a           ; TODO pass the ce bank bit mask
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
       set SPI_CE0,a           ; TODO pass the ce bank bit mask - perhaps have a call that sets it
       out (storage_adata),a
       ld (spi_portbyte), a

    ret

if DEBUG_STORESE

storageput: 

;    ld a,'H'
;    ld hl,0
;    call se_writebyte
;    ld a,'e'
;    ld hl,1
;    call se_writebyte
;    ld a,'l'
;    ld hl,2
;    call se_writebyte
    ld a,0
    ld hl,1
    call se_writebyte
    ld a,'l'
    ld hl,3
    call se_writebyte
;    ld a,'o'
;    ld hl,4
;    call se_writebyte
    ld a,'!'
    ld hl,5
    call se_writebyte
    ret


ret


storageread: ret


endif



