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
storage_adata: edu 080h    ; device c port a - onboard storage
storage_actl: edu 082h     ; device c port a
storage_bdata: edu 081h    ; device c port b - ext storage cart
storage_bctl: edu 083h     ; device c port b


storage_so_bit: 5
storage_si_bit: 7
storage_sclk_bit: 6
 

; init storage pio


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




if DEBUG_STORE

storageput: 

; initi write mode
;
;CS low

res 0,a
out(storage_adata),a

;clock out wren instruction

ld c, store_wren_ins
call spi_send_byte

;cs high to enable write latch

set 0,a
out(storage_adata)
;
; intial write data
;
; cs low

res 0,a
out(storage_adata)

; clock out write instruction

ld c, store_write_ins
call spi_send_byte

; clock out address (depending on address size)

ld c, 0
call spi_send_byte

; clock out byte(s) for page

ld c, 1
call spi_send_byte
ld c, 2
call spi_send_byte
ld c, 3
call spi_send_byte

; cs high to write

set 0,a
out(storage_adata)

; 




ret


storageread: ret


endif



