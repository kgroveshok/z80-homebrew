; my spi protocol (used by storage)


; TODO store port id for spi device ie dev c
; TODO store pin for SO
; TODO store pin for SI
; TODO store pin for SCLK

;
; TODO low level send byte in c on spi. contents on A are hold current bit pattern for pio port
; TODO might need to swap and c and then or c onto a

spi_send_byte:
	; swap a and c
        ld b,a
	ld a,c
	ld c,b	        
	 
	; clock out	each bit of the byte msb first

	ld b, 8
.ssb1:
	; clear so bit 
	res storage_so_bit, c
	rla
	; if bit 7 is set then carry is set
	jr nc, .ssb2
	set storage_so_bit,c
	res storage_sclk_bit,c
.ssb2:  ; output bit to ensure it is stable
	ld d,a
	ld c,a
	out (storage_adata),a
	nop
	; clock the bit high
	set storage_sclk_bit,a
	out (storage_adata),a
	nop
	; then low
	res storage_sclk_bit,a
	out (storage_adata),a
	nop
	ld a,d
	djnz .ssb1

	; restore a
	ld a,c
	ret

; TODO low level get byte into A on spi

spi_get_byte: ret

