
org 0000h

loop:
;ld a, 0ffh
;ld (30h),a
nop
;out(40h),a
;nop
;ld (40h),a
;nop
ld hl,(data)
inc hl
ld (data),hl
jp loop
nop
data: 
	db 0Ah
	db 01h


