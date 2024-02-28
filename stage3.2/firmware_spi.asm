; my spi protocol (used by storage)

; SPI pins

SPI_DI: equ 0       ; chip pin 5 - port a0   pin 15
SPI_DO: equ 1      ; chip pin 2 - port a1   pin 14
SPI_SCLK: equ 2      ; chip pin 6 - port a2  - pin 13

; chip pin 3, 7 and 4 gnd
; chip pin 8 +5


SPI_CE0: equ 3      ; chip pin 1 - port a3 - pin 12
SPI_CE1: equ 4
SPI_CE2: equ 5
SPI_CE3: equ 6
SPI_CE4: equ 7






; TODO store port id for spi device ie dev c
; TODO store pin for SO
; TODO store pin for SI
; TODO store pin for SCLK

;

; ensure that spi bus is in a stable state with default pins 

se_stable_spi:  

	 ; set DO high, CE high , SCLK low
	ld a, SPI_DO | SPI_CE0
	 out (storage_adata),a
	ld (spi_portbyte),a

	ret

; byte to send in a

spi_send_byte:
	; save byte to send for bit mask shift out
        ld c,a
	ld a,(spi_portbyte)
	 
	; clock out	each bit of the byte msb first

	ld b, 8
.ssb1:
	; clear so bit 
	res SPI_DO, a
	rl c
	; if bit 7 is set then carry is set
	jr nc, .ssb2
	set SPI_DO,a
.ssb2:  ; output bit to ensure it is stable
	out (storage_adata),a
	nop
	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	djnz .ssb1

	ld (spi_portbyte),a
	ret

; TODO low level get byte into A on spi

spi_get_byte: ret








