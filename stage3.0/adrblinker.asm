; Test that ROM is working by running a lot of nothing but then cause the high RAM
; chip selector to blink to indicate the CPU is running through the code loop.
; 
; Add in some op codes that I can try and id on the bus with the scope too

; Make sure of course that the clock is SLOWWWWW 

org 0000h

highmem:  equ   0a000h

ld c,5
loop:
	di
	nop
	nop
	nop
	nop
	; high memory bank selection (RAM)
	ld hl, (highmem)
	nop
	nop
	ld hl, (highmem)
	nop
	inc hl
	nop
	ld (highmem), hl
	dec c
	jr nz,loop
	halt

