;
; kernel to the forth OS

DS_TYPE_STR: equ 1
DS_TYPE_NUM: equ 2 

FORTH_PARSEV1: equ 0
FORTH_PARSEV2: equ 0
FORTH_PARSEV3: equ 1

FORTH_END_BUFFER: equ 127


user_word_eol: 
	; hl contains the pointer to where to create a linked list item from the end
	; of the user dict to continue on at the system word dict
	
	; poke the stub of the word list linked list to repoint to rom words

	; stub format
	; db   word id
	; dw    link to next word
        ; db char length of token
	; db string + 0 term
	; db exec code.... 

	ld a, 1
	ld (hl), a		; word id
	inc hl

	ld de, sysdict
	ld (hl), e		; next word link ie system dict
	inc hl
	ld (hl), d		; next word link ie system dict
	inc hl	

;	ld (hl), sysdict		; next word link ie system dict
;	inc hl
;	inc hl

;	inc hl
;	inc hl

	ld a, 2			; word length is 0
	ld (hl), a	
	inc hl

	ld a, '~'			; word length is 0
	ld (hl), a	
	inc hl
	ld a, 0			; save empty word
	ld (hl), a

	ret

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
	; set bottom of stack
	ld a,0
	ld (hl),a
	inc hl
	ld (hl),a

	ld hl, cli_data_stack
	ld (cli_data_sp), hl	
	; set bottom of stack
	ld a,0
	ld (hl),a
	inc hl
	ld (hl),a

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
	
if FORTH_PARSEV3



      include "forth_parserv3.asm"
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

.regstate:	db "Reg State",0
.regstatehl:	db "HL:",0
.regstatede:	db "DE:",0
.regstatebc:	db "BC:",0
.regstatea:	db "AF:",0
.regstatedsp:	db "DSP:",0
.regstatersp:	db "RSP:",0

display_dump_at_hl:
	push hl
	push de
	push bc
	push af

	ld (os_cur_ptr),hl	
	call clear_display
	call dumpcont
	call delay1s
	call next_page_prompt


	pop af
	pop bc
	pop de
	pop hl
	ret


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

; pass word in hl
; a has display location
display_word_at:
	push af
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
	pop af
		call str_at_display
	ret

display_reg_state:

	; to restore afterwards

	push de
	push bc
	push hl
	push af

	; for use in here

	push bc
	push de
	push hl
	push af

	call clear_display

	ld de, .regstate
	ld a, display_row_1
	call str_at_display

	; display debug step


	ld de, debug_mark
	ld a, display_row_1+display_cols-1
	call str_at_display

	; display a
	ld de, .regstatea
	ld a, display_row_2
	call str_at_display

	pop af
	ld h,0
	ld l, a
	ld a, display_row_2+3
	call display_word_at


	; display hl


	ld de, .regstatehl
	ld a, display_row_2+10
	call str_at_display

	pop hl
	ld a, display_row_2+13
	call display_word_at

	
	; display de

	ld de, .regstatede
	ld a, display_row_3
	call str_at_display

	pop de
	ld h,d
	ld l, e
	ld a, display_row_3+3
	call display_word_at


	; display bc

	ld de, .regstatebc
	ld a, display_row_3+10
	call str_at_display

	pop bc
	ld h,b
	ld l, c
	ld a, display_row_3+13
	call display_word_at


	; display dsp

	ld de, .regstatedsp
	ld a, display_row_4
	call str_at_display

	
	ld hl,(cli_data_sp)
	ld a, display_row_4+4
	call display_word_at

	; display rsp

	ld de, .regstatersp
	ld a, display_row_4+10
	call str_at_display

	
	ld hl,(cli_ret_sp)
	ld a, display_row_4+14
	call display_word_at

	call update_display

	call delay1s
	call delay1s
	call delay1s


	call next_page_prompt

	; restore 

	pop af
	pop hl
	pop bc
	pop de
	ret
; eof
