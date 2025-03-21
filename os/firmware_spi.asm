; my spi protocol (used by storage)

; SPI pins

SPI_DI: equ 7       ; chip pin 5 - port a7   pin pin 7
SPI_DO: equ 6      ; chip pin 2 - port a6   pin 8
SPI_SCLK: equ 5      ; chip pin 6 - port a5  - pin 9

; chip pin 3 (WP), 7 (HOLD) and 8 (VCC) +5v
; chip pin 4 gnd


SPI_CE0: equ 0      ; chip pin 1 - port a3 - pin 15
SPI_CE1: equ 1      ;    port a1 pin 14 
SPI_CE2: equ 2      ;    port a2 pin pin 13
SPI_CE3: equ 3      ; port    a3 pin pin 12
SPI_CE4: equ 4      ; port a4     pin 10

; active low AND masks

;SPI_CE0_MASK: equ    255-1
;SPI_CE1_MASK: equ   255-2
;SPI_CE2_MASK: equ   255-4
;SPI_CE3_MASK: equ   255-8
;SPI_CE4_MASK: equ   255-16
SPI_CE_HIGH:  equ 255



;  Perform SCLK wait pulse

spi_clk:
	push af
	ld a, (spi_clktime)
	cp 0
	jr z, .scskip
	call aDelayInMS
.scskip:
	pop af
	ret



; TODO store port id for spi device ie dev c
; TODO store pin for SO
; TODO store pin for SI
; TODO store pin for SCLK

;

; ensure that spi bus is in a stable state with default pins 

se_stable_spi:  

	 ; set DI high, CE high , SCLK low
	;ld a, SPI_DI | SPI_CE0
	ld a, SPI_DI 
	call spi_ce_high
	 out (storage_adata),a
	ld (spi_portbyte),a

	if DEBUG_SPI
		push hl
		ld l, a
		DMARK "SPI"
		CALLMONITOR
		pop hl
	endif
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
	res SPI_DI, a
	rl c
	; if bit 7 is set then carry is set
	jr nc, .ssb2
	set SPI_DI,a
.ssb2:  ; output bit to ensure it is stable
	out (storage_adata),a
	nop
	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk
	djnz .ssb1

	ld (spi_portbyte),a
	ret

; TODO low level get byte into A on spi

spi_read_byte: 

	; save byte to send for bit mask shift out
    ld c,0
	ld a,(spi_portbyte)
	 
	; clock out	each bit of the byte msb first


	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk

    ; read DO 

    set 7,c
	in a,(storage_adata)
    bit SPI_DO,a
    jr nz, .b7
    res 7,c
.b7:
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk
    

	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk

    ; read DO 

    set 6,c
	in a,(storage_adata)
    bit SPI_DO,a
    jr nz, .b6
    res 6,c
.b6:
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk

	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk


    ; read DO 

    set 5,c
	in a,(storage_adata)
    bit SPI_DO,a
    jr nz, .b5
    res 5,c
.b5:
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk
	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk

    ; read DO 

    set 4,c
	in a,(storage_adata)
    bit SPI_DO,a
    jr nz, .b4
    res 4,c
.b4:
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk
	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk

    ; read DO 

    set 3,c
	in a,(storage_adata)
    bit SPI_DO,a
    jr nz, .b3
    res 3,c
.b3:
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk
	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk

    ; read DO 

    set 2,c
	in a,(storage_adata)
    bit SPI_DO,a
    jr nz, .b2
    res 2,c
.b2:
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk
	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk

    ; read DO 

    set 1,c
	in a,(storage_adata)
    bit SPI_DO,a
    jr nz, .b1
    res 1,c
.b1:
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk
	; clock bit high
	set SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk

    ; read DO 

    set 0,c
	in a,(storage_adata)
    bit SPI_DO,a
    jr nz, .b0
    res 0,c
.b0:
	; then low
	res SPI_SCLK,a
	out (storage_adata),a
	nop
	call spi_clk


	ld (spi_portbyte),a

    ; return byte
    ld a,c


	ret



spi_ce_high:

	if DEBUG_SPI_HARD_CE0
       set SPI_CE0,a           ; TODO pass the ce bank bit mask
		ret

	endif


	push af

	; send direct ce to port b
	ld a, 255
	out (storage_bdata), a

	pop af

	; for port a that shares with spi lines AND the mask
 
	if DEBUG_SPI
		push hl
		ld h, a
	endif
;	ld c, SPI_CE_HIGH
;	and c
	set SPI_CE0, a
	set SPI_CE1, a
	set SPI_CE2, a
	set SPI_CE3, a
	set SPI_CE4, a

	if DEBUG_SPI
		ld l, a
		DMARK "CEh"
		CALLMONITOR
		pop hl
	endif
	ret


spi_ce_low:

	if DEBUG_SPI_HARD_CE0
       res SPI_CE0,a           ; TODO pass the ce bank bit mask
		ret

	endif

	push bc
	push af

	; send direct ce to port b
	ld a, (spi_cartdev)
	out (storage_bdata), a



	; for port a that shares with spi lines AND the mask

	ld a, (spi_device) 
	ld c, a

	pop af

	; detect CEx

	if DEBUG_SPI
		push hl
		ld h, a
	endif

	bit SPI_CE0, c
	jr nz, .cel1
	res SPI_CE0, a
	jr .celn
.cel1:
	bit SPI_CE1, c
	jr nz, .cel2
	res SPI_CE1, a
	jr .celn
.cel2:
	bit SPI_CE2, c
	jr nz, .cel3
	res SPI_CE2, a
	jr .celn
.cel3:
	bit SPI_CE3, c
	jr nz, .cel4
	res SPI_CE3, a
	jr .celn
.cel4:
	bit SPI_CE4, c
	jr nz, .celn
	res SPI_CE4, a
.celn:



;	add c

	if DEBUG_SPI
		ld l, a
		DMARK "CEl"
		CALLMONITOR
		pop hl
	endif
	pop bc
	ret



; eof





