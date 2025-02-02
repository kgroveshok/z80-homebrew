; Macro and code to detect stock imbalances

; for a call, wrap SP collection and comparisons

; Usage:
;
; SAVESP ON/OFF 0-STACK_IMB_STORE/4
; CHECKSP ON/OFF 0-STACK_IMB_STORE/4

SAVESP: macro onoff storeword

	if DEBUG_STACK_IMB
		if onoff
			; save current SP

			ld (store_sp+(storeword*4)), sp

		endif
		
	endif

endm

CHECKSP: macro onoff storeword

	if DEBUG_STACK_IMB
		if onoff

			; save SP after last save
	
			ld (store_sp+(storeword*4)+2), sp

			push hl
			ld hl, store_sp+(storeword*4)
			call check_stack_sp 
			pop hl


		endif
		
	endif

endm

if DEBUG_STACK_IMB

check_stack_sp:
		push de

		ld e, (hl)
		inc hl
		ld d, (hl)
		inc hl

		push de


		ld e, (hl)
		inc hl
		ld d, (hl)
		inc hl

		pop hl


		; check to see if the same

		call cmp16
		jr z, .spsame

		; not same


	push de
	push af
	push hl
	call clear_display
	ld de, .sperr
	ld a,0
;	ld de,os_word_scratch
	call str_at_display
	ld a, display_row_1+17
	ld de, debug_mark
	call str_at_display
	call update_display
	;call break_point_state
	call cin_wait

	ld a, ' '
	ld (os_view_disable), a
	pop hl
	pop af
	pop de	
	CALLMONITOR

.spsame:

		pop de

		ret

.sperr:  db "Stack imbalance",0

endif



; eof
