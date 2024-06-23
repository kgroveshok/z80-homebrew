; Device support for AY38910 sound chip

; Set to use cart extension port instead of Z80 bus
SOUND_CARTEXT: equ 1


sound_init:


; TODO not working switch to using the cartext
; TODO BC1 pin?
; TODO BDIR pin?
; TODO reset pin?
; TODO move data bus to shift reg


;# TODO needs the reset. Tie to Z80 reset line


;# // Enable only the Tone Generator on Channel A
	ld h, 7
	ld l,  %00111110
	call sound_ay_register
;#write_register(7, 0b00111110)
;#  
;#  // Set the amplitude (volume) to maximum on Channel A
;#write_register(8, 0b00001111)
	ld h, 8
	ld l, %00001111
	call sound_ay_register

	ld b, 10
.soundtst:
;#while True:
;#
;#    #  // Change the Tone Period for Channel A every 500ms
;#

;#    write_register(0, 223)
	ld h, 0
	ld l, 223
	call sound_ay_register
;#    write_register(1, 1)
	ld h, 1
	ld l, 1
	call sound_ay_register
;#
;#    #delay(500);
	call delay500ms
;#      
;#    write_register(0, 170)
	ld h, 0
	ld l, 170
	call sound_ay_register
;#    write_register(1, 1)
	ld h, 1
	ld l, 1
	call sound_ay_register
;#
;#    time.sleep(.5)
;#    #delay(500);
	call delay500ms
;#      
;#    write_register(0, 123)
	ld h, 0
	ld l, 123
	call sound_ay_register
;#    write_register(1, 1)
	ld h, 1
	ld l, 1
	call sound_ay_register
;#
;#    time.sleep(.5)
;#    #delay(500);
	call delay500ms
;#      
;#    write_register(0, 102)
	ld h, 0
	ld l, 102
	call sound_ay_register
;#    write_register(1, 1)
	ld h, 1
	ld l, 1
	call sound_ay_register
;#
;#    time.sleep(.5)
;#    #delay(500);
	call delay500ms
;#      
;#    write_register(0, 63)
	ld h, 0
	ld l, 63
	call sound_ay_register
;#    write_register(1, 1)
	ld h, 1
	ld l, 1
	call sound_ay_register
;#
;#    time.sleep(.5)
;#    #delay(500);
	call delay500ms
;#      
;#    write_register(0, 28)
	ld h, 0
	ld l, 28
	call sound_ay_register
;#    write_register(1, 1)
	ld h, 1
	ld l, 1
	call sound_ay_register
;#
;#    time.sleep(.5)
;#    #delay(500);
	call delay500ms
;#      
;#    write_register(0, 253)
	ld h, 0
	ld l, 253
	call sound_ay_register
;#    write_register(1, 0)
	ld h, 1
	ld l, 0
	call sound_ay_register
;#
;#    time.sleep(.5)
;#    #delay(500);
	call delay500ms
	;djnz .soundtst

	ret


; Play a note
; h = note
; l = duration
; a = channel
note: 
	ret



;# test coding of AY sound chip for porting to Z80

;# data bus
;# gpio  pin    z80
;# 0     1     d0
;# 1    2    d1
;# 2   4 d2
;# 3   5  d3
;# 4   6  d4
;# 5   7 d5
;# 6  9 d6
;# 7  10 d7
;#

;#CE
;# a8          25     +5V
;# a9  18 24        24       Dev A

;# bc1   17   22      29     A0
;# bc2         28            +5V
;# bdir  16  21      27      A1
;#    
;#


sound_ay_inactive:
;	#    BC1_PIN.low()
;	#    BDIR_PIN.low()
	
;	#ld a, 0
	out (SOUND_DEVICE), a
	ret


sound_ay_latch:
;#    BC1_PIN.high()
;#    BDIR_PIN.high()
;	#ld a, 0
	out (SOUND_DEVICE+3), a
	ret 

sound_ay_write:
;#    BC1_PIN.low()
;#    BDIR_PIN.high()
;	#ld a, 0
	out (SOUND_DEVICE+2), a
	ret 

;# h = reg
;# l = data
sound_ay_register:
 	ld a, h	
	call sound_ay_latch
;#    writeByte(reg)
	call sound_ay_inactive
	ld a, l
	call sound_ay_write
;#    writeByte(value)
	call sound_ay_inactive
	ret

;#
;#
;#while True:
;#
;#    #  // Change the Tone Period for Channel A every 500ms
;#
;#    write_register(0, 223)
;#    write_register(1, 1)
;#
;#    #delay(500);
;#      
;#    write_register(0, 170)
;#    write_register(1, 1)
;#
;#    time.sleep(.5)
;#    #delay(500);
;#      
;#    write_register(0, 123)
;#    write_register(1, 1)
;#
;#    time.sleep(.5)
;#    #delay(500);
;#      
;#    write_register(0, 102)
;#    write_register(1, 1)
;#
;#    time.sleep(.5)
;#    #delay(500);
;#      
;#    write_register(0, 63)
;#    write_register(1, 1)
;#
;#    time.sleep(.5)
;#    #delay(500);
;#      
;#    write_register(0, 28)
;#    write_register(1, 1)
;#
;#    time.sleep(.5)
;#    #delay(500);
;#      
;#    write_register(0, 253)
;#    write_register(1, 0)
;#
;#    time.sleep(.5)
;#    #delay(500);







; eof


