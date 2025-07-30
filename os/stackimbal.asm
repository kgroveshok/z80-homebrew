; Macro and code to detect stock imbalances

SPPUSH: equ 0

; Add a stack frame which can be checked before return

STACKFRAME: macro onoff frame1 frame2

	if DEBUG_STACK_IMB
		if onoff
			; save current SP
			exx

			ld de, frame1
			ld a, d
			ld hl, curframe
			call hexout
			ld a, e
			ld hl, curframe+2
			call hexout
 
			ld hl, frame1
			push hl
			ld hl, frame2
			push hl
			exx
		endif
		
	endif
endm

STACKFRAMECHK: macro onoff frame1 frame2

		
	if DEBUG_STACK_IMB
		if onoff
			exx
			; check stack frame SP

			ld hl, frame2
			pop de   ; frame2

			call cmp16
			jr nz, .spnosame
			

			ld hl, frame1
			pop de   ; frame1

			call cmp16
			jr z, .spfrsame

			.spnosame: call showsperror

			.spfrsame: nop

			exx
		endif
		
	endif


endm


; for a sub routine, wrap SP collection and comparisons

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

		call showsperror
.spsame:

		pop de

		ret

.sperr:  db "Stack imbalance",0


showsperror:


	push hl
	push af
	push de
	call clear_display
	ld de, .sperr
	ld a,0
;	ld de,os_word_scratch
	call str_at_display
	ld a, display_row_1+17
	ld de, debug_mark
	call str_at_display
	ld a, 0
	ld (curframe+4),a
	ld hl, curframe
	ld de, os_word_scratch
	ld a, display_row_4
	call str_at_display
	call update_display
	;call break_point_state
	call cin_wait

;	ld a, ' '
;	ld (os_view_disable), a
	call bp_on
	pop de	
	pop af
	pop hl
	CALLMONITOR
	ret

endif



; eof
