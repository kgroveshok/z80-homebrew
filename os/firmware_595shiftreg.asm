; common code for handling a 595 shift reg out on whatever output port

; port in c
; byte in a


shift_bit_data: equ 0
shift_bit_clk: equ 1
shift_bit_latch: equ 2


; shift out a byte to the sound chip

; A contains byte to send

shift_byte:

	ld b, 8   ; 8 bits to shift

.nb1:	ld d, 0    ; our work byte to send to the device with flags

	; set data bit state

	bit 7, a
	; high bit is set
	jr z, .nb2
	set shift_bit_data, d

	; set latches state 
.nb2:	set shift_bit_clk, d
	res shift_bit_latch, d    ; latch is inverted
	out (c), d
	
	; clock the bit out
	res shift_bit_clk, d
	out (c), d

	; shift a left one bit and repeat
	rla

	djnz .nb1

	; latch
	set shift_bit_latch, d
	out (c), d
		

	; set 
	ret
