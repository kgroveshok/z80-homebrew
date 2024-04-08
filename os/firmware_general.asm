
; https://plutiedev.com/z80-add-8bit-to-16bit

addatohl:
    add   a, l    ; A = A+L
    ld    l, a    ; L = A+L
    adc   a, h    ; A = A+L+H+carry
    sub   l       ; A = H+carry
    ld    h, a    ; H = H+carry
ret

addatode:
    add   a, e    ; A = A+L
    ld    e, a    ; L = A+L
    adc   a, d    ; A = A+L+H+carry
    sub   e       ; A = H+carry
    ld    d, a    ; H = H+carry
ret


addatobc:
    add   a, c    ; A = A+L
    ld    c, a    ; L = A+L
    adc   a, b    ; A = A+L+H+carry
    sub   c       ; A = H+carry
    ld    b, a    ; H = H+carry
ret

subafromhl:
   ; If A=0 do nothing
    ; Otherwise flip A's sign. Since
    ; the upper byte becomes -1, also
    ; substract 1 from H.
    neg
    jp    z, Skip
    dec   h
    
    ; Now add the low byte as usual
    ; Two's complement takes care of
    ; ensuring the result is correct
    add   a, l
    ld    l, a
    adc   a, h
    sub   l
    ld    h, a
Skip:
	ret


; Delay loops



aDelayInMS:
	push bc
	ld b,a
msdelay:
	push bc
	

	ld bc,041h
	call delayloop
	pop bc
	dec b
	jr nz,msdelay
	pop bc
	ret


delay250ms:
	;push de
	ld bc, 04000h
	jp delayloop
delay500ms:
	;push de
	ld bc, 08000h
	jp delayloop
delay1s:
	;push bc
   ; Clobbers A, d and e
    ld      bc,0      ; # 0ffffh = approx 1s
delayloop:
    bit     0,a    	; 8
    bit     0,a    	; 8
    bit     0,a    	; 8
    and     255  	; 7
    dec     bc      	; 6
    ld      a,c     	; 4
    or      b     	; 4
    jp      nz,delayloop   	; 10, total = 55 states/iteration
    ; 65536 iterations * 55 states = 3604480 states = 2.00248 seconds
	;pop de
	ret



; eof
