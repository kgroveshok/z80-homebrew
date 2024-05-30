
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
;

SOUND_LATCH: equ 10000000B
SOUND_DATA: equ 0B
SOUND_CH0:  equ 0B    ; Tone
SOUND_CH1: equ 0100000B        ; Tone
SOUND_CH2: equ 1000000B   ; Tone
SOUND_CH3: equ 1100000B    ; Noise
SOUND_VOL: equ 10000B
SOUND_TONE: equ 0B


sound_init:
	ld a, SOUND_DATA | SOUND_CH0 | SOUND_VOL | 1111B
	call note_send_byte

	ld a, SOUND_DATA | SOUND_CH0 | SOUND_TONE | 0111B
	call note_send_byte
	call delay250ms
	ld a, SOUND_DATA | SOUND_CH0 | SOUND_TONE | 0111B
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

note_send_byte:
	; byte in a

	; we high
	out (Device_B+1), a
	nop 
	nop 
	nop 
	nop 
	; we low
	out (Device_B), a
	nop 
	nop 
	nop 
	nop 
	; we high
	out (Device_B+1), a
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


; eof

