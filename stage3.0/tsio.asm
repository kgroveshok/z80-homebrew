
org 0000h
di
loop:
;ld hl,(data)
;inc hl
;ld (data),hl
;ld hl, (0f000h)
;inc hl
;ld (0f000h),hl
nop
ld a, 0ffh
; Device A
out (001h), a
; Device B SIO
out (040h), a
; Device C
out (080h), a
; Device D
out (0C0h), a
;#ld a, (080h)
;#ld a, (040h)
;#ld a, (0c0h)
halt
;jp loop
db 03h
db 02h
db 01h

data: 
	db 0Ah
	db 01h


