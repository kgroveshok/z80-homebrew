; Test address decoding
org 0000h
di
ld c,3
;loop:
; First test is to test if the low and high memory bank selection is working by making sure the 
; memory bank LED goes out due to being enabled
;
;
; low memory bank selection (ROM)

ld hl,(data)

; high memory bank selection (RAM)

ld hl, (0f000h)
ld hl, (0a0e0h)
inc hl
ld (0a0e0h), hl


; Now to test the other half of the address decoder which is related to IOIRQ devices

ld a, 0ffh

; Device A
out (001h), a

; Device B SIO
out (040h), a

; Device C
out (080h), a

; Device D
out (0C0h), a

; Check that the devices do not trigger when using RAM/ROM over those same address ranges

ld a, (080h)
ld a, (040h)
ld a, (0c0h)

dec c
;#jr z,loop

halt 
;jp loop
db 03h
db 02h
db 01h

data: 
	db 0Ah
	db 01h


