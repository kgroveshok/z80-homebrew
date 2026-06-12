
; Device support for SN76489AN sound chip

; https://arduinoplusplus.wordpress.com/2019/10/05/making-noise-with-a-sn76489-digital-sound-generator-part-1/
; http://danceswithferrets.org/geekblog/?p=93
; https://www.smspower.org/Development/SN76489

; D0 [ 3]
; D1 [ 2]
; D2 [ 1]
; D3 [15]
; D4 [13]
; D5 [12]
; D6 [11]
; D7 [10]
; /WE [ 5]
; CLK [14]
; /OE [ 6]
; AUDIO [ 7]
; GND 8
; +5 16
;

; Write sequence:
; CE low
; Data bus
; WE low then high
; 32 clock cycles / 8ns write time at 4mhz
;
; https://github.com/jblang/SN76489
; Shows that the clock needs to be enabled when required. Noticed that with the clock connected it interupted the bus
; Tried:
;
; CE/OE -> Both pins of NAND -> To one pin of second NAND and second pin to full clock -> CLK on chip
;
; Connected WE to OR too
; 
; That enabled the clock when required
; However still random bus corruption. Need further investigation


SOUND_LATCH: equ 10000000B
SOUND_DATA: equ 0B
SOUND_CH0:  equ 0B    ; Tone
SOUND_CH1: equ 0100000B        ; Tone
SOUND_CH2: equ 1000000B   ; Tone
SOUND_CH3: equ 1100000B    ; Noise
SOUND_VOL: equ 10000B
SOUND_TONE: equ 0B


sound_init: ret


sound_bit_data: equ 0
sound_bit_clk: equ 1
sound_bit_latch: equ 2
sound_bit_sound: equ 3


; shift out a byte to the sound chip

; A contains byte to send

note_byte:

	ld c, 	SOUND_DEVICE
	ld b, 8   ; 8 bits to shift

.nb1:	ld d, 0    ; our work byte to send to the device with flags

	; set data bit state

	bit 7, a
	; high bit is set
	jr z, .nb2
	set sound_bit_data, d

	; set latches state high
.nb2:	set sound_bit_clk, d
	set sound_bit_latch, d
	out (c), d
	
	; clock the bit out
	res sound_bit_clk, d
	out (c), d
	set sound_bit_clk, d
	out (c), d

	; shift a left one bit and repeat
	rla

	djnz .nb1

	; latch
	set sound_bit_latch, d
	out (c), d
	res sound_bit_latch, d
	out (c), d
	set sound_bit_latch, d
	out (c), d
		

	; set 
	ret


oldsound_init:
	ld a, SOUND_DATA | SOUND_CH0 | SOUND_VOL | 1111B
	call note_send_byte
	ld a, SOUND_DATA | SOUND_CH0 | SOUND_TONE | 0111B
	call note_send_byte
	call delay250ms
	ld a, SOUND_DATA | SOUND_CH0 | SOUND_TONE | 0101B
	call note_send_byte
	call delay250ms
	ret

; Play a note
; h = note
; l = duration
; a = channel


;  frequ = clock / ( 2 x reg valu x 32 ) 

note:

	ret

oldnote_byte: 
	ld c, SOUND_DEVICE
	ld a, l
	out (c), a	

	ret

note_send_byte: ret
oldnote_send_byte:
	; byte in a

	; we high
	out (SOUND_DEVICE), a
;	ld a, 1
;	call aDelayInMS
	nop 
	nop 
	nop 
	nop 
	; we low
	out (SOUND_DEVICE), a
;	ld a, 1
;	call aDelayInMS
	nop 
	nop 
	nop 
	nop 
	; we high
	out (SOUND_DEVICE), a
;	ld a, 1
;	call aDelayInMS
	nop 
	nop 
	nop 
	nop 


	ret

;void SilenceAllChannels()
;{
;  SendByte(0x9f);
;  SendByte(0xbf);
;  SendByte(0xdf);
;  SendByte(0xff);
;}

oldnote_silence:
	ld c, SOUND_DEVICE
	ld a, 0x9f
	out (c), a

	ld a, 0xbf
	out (c), a

	ld a, 0xdf
	out (c), a

	ld a, 0xff
	out (c), a
	ret
; eof

