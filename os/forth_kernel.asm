;
; kernel to the forth OS

DS_TYPE_STR: equ 1
DS_TYPE_NUM: equ 2 

FORTH_PARSEV1: equ 0
FORTH_PARSEV2: equ 1

FORTH_END_BUFFER: equ 127



; increase data stack pointer and save hl to it
	
FORTH_DSP_NEXT: macro
	push hl
	push de
	ex de,hl
	ld hl,(cli_data_sp)
	inc hl
	inc hl
	ld (cli_data_sp),hl
	ld (hl), e
	inc hl
	ld (hl), d
	pop de
	pop hl
	endm
	
; increase ret stack pointer and save hl to it
	
FORTH_RSP_NEXT: macro
	push hl
	push de
	ex de,hl
	ld hl,(cli_ret_sp)
	inc hl
	inc hl
	ld (cli_ret_sp),hl
	ld (hl), e
	inc hl
	ld (hl), d
	pop de
	pop hl
	endm

; get current ret stack pointer and save to hl 
	
FORTH_RSP_TOS: macro
	push de
	ld hl,(cli_ret_sp)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	pop de
	endm


forth_init:
;	call update_display
;	call delay1s
;	ld a,'.'
;	call fill_display
;	call update_display
;	call delay1s
;
;            ld a, display_row_1
;	ld de, .bootforth
;	call str_at_display
;	call update_display
;
;	call delay1s
;	call delay1s

	; init stack pointers  - * these stacks go upwards * 
	ld hl, cli_ret_stack
	ld (cli_ret_sp), hl	

	ld hl, cli_data_stack
	ld (cli_data_sp), hl	

	call clear_display

	ld a,0
	ld (f_cursor_ptr), a

	; set start of word list in start of ram - for use when creating user words

	ld hl, baseusermem		
	call user_word_eol
	
		call display_data_sp
		call next_page_prompt


	ret

.bootforth: db " Forth Kernel Init ",0

; TODO push to stack

; 

if FORTH_PARSEV2


	include "forth_parserv2.asm"

endif


; parse cli version 1

if FORTH_PARSEV1



      include "forth_parserv1.asm"
endif
	

;;;;;;;;;;;;;; Debug code


if DEBUG_FORTH_PARSE
.nowordfound: db "No match",0
.compword:	db "Comparing word ",0
.nextwordat:	db "Next word at",0
.charmatch:	db "Char match",0
endif
if DEBUG_FORTH_JP
.foundword:	db "Word match. Exec..",0
endif
;if DEBUG_FORTH_PUSH
.enddict:	db "Dict end. Push.",0
.push_str:	db "Pushing string",0
.push_num:	db "Pushing number",0
.data_sp:	db "SP:",0
.wordinhl:	db "Word in HL:",0
;endif
;if DEBUG_FORTH_MALLOC
.push_malloc:	db "Malloc address",0
;endif



; display malloc address and current data stack pointer 

;if DEBUG_FORTH_PUSH
display_data_sp:

	push af
	push hl
	push hl
push hl
	call clear_display
pop hl
	ld a,h
	ld hl, os_word_scratch
	call hexout
	pop hl
	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
		ld a, display_row_2
		call str_at_display
	ld de, .wordinhl
	ld a, display_row_1

		call str_at_display
	ld de, debug_mark
	ld a, display_row_1+18

		call str_at_display

	; display current data stack pointer
	ld de,.data_sp
		ld a, display_row_2 + 8
		call str_at_display

	ld hl,(cli_data_sp)
	push hl
	ld a,h
	ld hl, os_word_scratch
	call hexout
	pop hl
	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
		ld a, display_row_2 + 11
		call str_at_display

	call update_display
	call delay1s
	call delay1s
	pop hl
	pop af
	ret

display_data_malloc:

	push af
	push hl
	push hl
push hl
	call clear_display
pop hl
	ld a,h
	ld hl, os_word_scratch
	call hexout
	pop hl
	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
		ld a, display_row_2
		call str_at_display
	ld de, .push_malloc
	ld a, display_row_1

		call str_at_display

	; display current data stack pointer
	ld de,.data_sp
		ld a, display_row_2 + 8
		call str_at_display

	ld hl,(cli_data_sp)
	push hl
	ld a,h
	ld hl, os_word_scratch
	call hexout
	pop hl
	ld a,l
	ld hl, os_word_scratch+2
	call hexout
	ld hl, os_word_scratch+4
	ld a,0
	ld (hl),a
	ld de,os_word_scratch
		ld a, display_row_2 + 11
		call str_at_display

	call update_display
	call delay1s
	call delay1s
	pop hl
	pop af
	ret
;endif
; eof
