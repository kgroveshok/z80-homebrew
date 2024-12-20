;
; kernel to the forth OS

DS_TYPE_STR: equ 1     ; string type
DS_TYPE_INUM: equ 2     ; $ 16 bit int usually a hex address
;DS_TYPE_FNUM: equ 3      ; 24/32 bit floating point  do string conversion instead of a new type

FORTH_PARSEV1: equ 0
FORTH_PARSEV2: equ 0
FORTH_PARSEV3: equ 0
FORTH_PARSEV4: equ 0
FORTH_PARSEV5: equ 1

if FORTH_PARSEV5
	FORTH_END_BUFFER: equ 0
else
	FORTH_END_BUFFER: equ 127
endif

FORTH_TRUE: equ 1
FORTH_FALSE: equ 0



FORTH_CHK_DSP_UNDER: macro
	push hl
	push de
	ld hl,(cli_data_sp)
	ld de, cli_data_stack
	call cmp16
	jp c, fault_dsp_under
	pop de
	pop hl
	endm


FORTH_CHK_RSP_UNDER: macro
	push hl
	push de
	ld hl,(cli_ret_sp)
	ld de, cli_ret_stack
	call cmp16
	jp c, fault_rsp_under
	pop de
	pop hl
	endm

FORTH_CHK_LOOP_UNDER: macro
	push hl
	push de
	ld hl,(cli_loop_sp)
	ld de, cli_loop_stack
	call cmp16
	jp c, fault_loop_under
	pop de
	pop hl
	endm

FORTH_ERR_TOS_NOTSTR: macro
	; TOSO might need more for checks when used
	push af
	ld a,(hl)
	cp DS_TYPE_STR
	jp nz, type_faultn  
	pop af
	endm

FORTH_ERR_TOS_NOTNUM: macro
	push af
	ld a,(hl)
	cp DS_TYPE_INUM
	jp nz, type_faultn  
	pop af
	endm

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

	ld a, WORD_SYS_ROOT     ; root word
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
	call macro_forth_dsp_next
	endm


macro_forth_dsp_next:
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
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
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	ret
	
; increase ret stack pointer and save hl to it
	
FORTH_RSP_NEXT: macro
	call macro_forth_rsp_next
	endm

macro_forth_rsp_next:
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
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
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
	endif
	ret

; get current ret stack pointer and save to hl 
	
FORTH_RSP_TOS: macro
	call macro_forth_rsp_tos
	endm

macro_forth_rsp_tos:
	push de
	ld hl,(cli_ret_sp)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
		if DEBUG_FORTH_WORDS
			DMARK "RST"
			CALLMONITOR
		endif
	pop de
	ret

; pop ret stack pointer
	
FORTH_RSP_POP: macro
	call macro_forth_rsp_pop
	endm


macro_forth_rsp_pop:
	if DEBUG_FORTH_STACK_GUARD
		DMARK "RPP"
		call check_stacks
		FORTH_CHK_RSP_UNDER
	endif
	push hl
	ld hl,(cli_ret_sp)


	if FORTH_ENABLE_FREE

		; get pointer

		push de
		push hl

		ld e, (hl)
		inc hl
		ld d, (hl)

		ex de, hl
		call free

		pop hl
		pop de


	endif


	dec hl
	dec hl
	ld (cli_ret_sp), hl
	; TODO do stack underflow checks
	pop hl
	if DEBUG_FORTH_STACK_GUARD
		call check_stacks
		FORTH_CHK_RSP_UNDER
	endif
	ret

forthexec_cleanup:
	FORTH_RSP_POP
	ret

forth_call_hl:
	; taking hl
	push hl
	ret

; this is called to reset Forth system but keep existing uwords etc

forth_warmstart:
	; setup stack over/under flow checks
	if DEBUG_FORTH_STACK_GUARD
		call chk_stk_init
	endif

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

	ld hl, cli_loop_stack
	ld (cli_loop_sp), hl	
	; set bottom of stack
	ld a,0
	ld (hl),a
	inc hl
	ld (hl),a

	; init extent of current open file

	ld a, 0
	ld (store_openext), a

	ret


; this is called to setup the whole Forth system

forth_init:

	; setup stack over/under flow checks

;	if DEBUG_FORTH_STACK_GUARD
;		call chk_stk_init
;	endif

	; enable auto display updates (slow.....)

	ld a, 1
	ld (cli_autodisplay), a



	; show start up screen

	call clear_display

	ld a,0
	ld (f_cursor_ptr), a

	; set start of word list in start of ram - for use when creating user words

	ld hl, baseusermem		
	ld (os_last_new_uword), hl
	call user_word_eol
	
;		call display_data_sp
;		call next_page_prompt




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
	include "forth_wordsv3.asm"
endif

if FORTH_PARSEV4



      include "forth_parserv4.asm"
	include "forth_wordsv4.asm"
endif

if FORTH_PARSEV5



      include "forth_parserv5.asm"
	include "forth_wordsv4.asm"
endif
;;;;;;;;;;;;;; Debug code


;if DEBUG_FORTH_PARSE
.nowordfound: db "No match",0
.compword:	db "Comparing word ",0
.nextwordat:	db "Next word at",0
.charmatch:	db "Char match",0
;endif
if DEBUG_FORTH_JP
.foundword:	db "Word match. Exec..",0
endif
;if DEBUG_FORTH_PUSH
.enddict:	db "Dict end. Push.",0
.push_str:	db "Pushing string",0
.push_num:	db "Pushing number",0
.data_sp:	db "SP:",0
.wordinhl:	db "Word in HL (2/0):",0
.wordinde:	db "Word in DE (3/0):",0
.wordinbc:	db "Word in BC (4/0):",0
;endif
;if DEBUG_FORTH_MALLOC
.push_malloc:	db "Malloc address",0
;endif



; display malloc address and current data stack pointer 

malloc_error:
	push de
	push af
	push hl
	call clear_display
	ld de, .mallocerr
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
	ret

.mallocerr: 	db "Malloc Error",0
;if DEBUG_FORTH_PUSH
display_data_sp:
	push af

	; see if disabled

	ld a, (os_view_disable)
	cp '*'
	jr z, .skipdsp

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
	ld a, display_row_1+17

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
.skipdsp:
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


startcmds:
;	dw test11
;	dw test12
;	dw test13
;	dw test14
;	dw test15
;	dw test16
;	dw test17
;	dw ifthtest1
;	dw ifthtest2
;	dw ifthtest3
;	dw mmtest1
;	dw mmtest2
;	dw mmtest3
;	dw mmtest4
;	dw mmtest5
;	dw mmtest6
;	dw iftest1
;	dw iftest2
;	dw iftest3
;	dw looptest1
;	dw looptest2
;	dw test1
;	dw test2
;	dw test3
;	dw test4
;	dw game2r
;	dw game2b1
;	dw game2b2
	dw game2b

	dw game1
	dw game1a
	dw game1b
	dw game1c
	dw game1d
	dw game1s
	dw game1t
	dw game1f
	dw game1z

	dw test5
	dw test6
	dw test7
	dw test8
	dw test9
	dw test10
	
	dw start1
	dw start2
	dw start3
	db 0, 0	

test1:		db ": aa 1 2 3 ;  ", 0, 0, 0, FORTH_END_BUFFER
test2:     	db "111 aa 888 999  ",0, 0, 0, FORTH_END_BUFFER
test3:     	db ": bb 77 ;  ",0, 0, 0, FORTH_END_BUFFER
test4:     	db "$02 $01 do i . loop bb  ",0, 0, 0, FORTH_END_BUFFER
test5:     	db ": hline $13 $00 do i $01 at 1 . i $04 at 1 . loop ;   ",0, 0, 0, FORTH_END_BUFFER
test6:     	db ": vline $04 $01 do $00 i at 1 . $13 i at 1 . loop ;   ",0, 0, 0, FORTH_END_BUFFER
test7:     	db ": box hline vline ;  ",0, 0, 0, FORTH_END_BUFFER
test8:     	db ": world cls box $03 $03 at Hello-World! . ;  ",0, 0, 0, FORTH_END_BUFFER
test9:     	db ": sw $01 adsp world ;  ",0, 0, 0, FORTH_END_BUFFER
test10:     	db ": fw $00 adsp world draw $05 pause ;  ",0, 0, 0, FORTH_END_BUFFER
test11:     	db "hello create . ",0, 0, 0, FORTH_END_BUFFER
test12:     	db "hello2 create . ",0, 0, 0, FORTH_END_BUFFER
test13:     	db "some-text-1 $01 append ",0, 0, 0, FORTH_END_BUFFER
test14:     	db "some-text-2 $01 append ",0, 0, 0, FORTH_END_BUFFER
test15:     	db "some-text-3 $01 append ",0, 0, 0, FORTH_END_BUFFER
test16:     	db "some-text-4 $01 append ",0, 0, 0, FORTH_END_BUFFER
test17:     	db "some-text-in2-1 $02 append ",0, 0, 0, FORTH_END_BUFFER

mmtest1:     	db "cls $0001 $0008 MIN . $0002 pause  ",0, 0, 0, FORTH_END_BUFFER
mmtest2:     	db "cls $0101 $0008 MIN . $0002 pause  ",0, 0, 0, FORTH_END_BUFFER
mmtest3:     	db "cls $0001 $0008 MAX . $0002 pause  ",0, 0, 0, FORTH_END_BUFFER
mmtest4:     	db "cls $0101 $0008 MAX . $0002 pause  ",0, 0, 0, FORTH_END_BUFFER
mmtest5:     	db "cls $0001 $0001 MIN . $0002 pause  ",0, 0, 0, FORTH_END_BUFFER
mmtest6:     	db "cls $0001 $0001 MAX . $0002 pause  ",0, 0, 0, FORTH_END_BUFFER

iftest1:     	db "$0001 IF  ",0, 0, 0, FORTH_END_BUFFER
iftest2:     	db "$0000 IF  ",0, 0, 0, FORTH_END_BUFFER
iftest3:     	db "$0002 $0003 - IF  ",0, 0, 0, FORTH_END_BUFFER
looptest1:     	db "$0003 $0001 do i . loop 8  ",0, 0, 0, FORTH_END_BUFFER
looptest2:     	db "$0003 $0001 do i . $0001 pause loop 8  ",0, 0, 0, FORTH_END_BUFFER

ifthtest1:     	db "$0001 IF is-true . $0005 pause THEN next-word . $0005 pause  ",0, 0, 0, FORTH_END_BUFFER
ifthtest2:     	db "$0000 IF is-true . $0005 pause THEN next-word . $0005 pause  ",0, 0, 0, FORTH_END_BUFFER
ifthtest3:     	db "$0002 $0003 - IF is-true . $0005 pause THEN next-word . $0005 pause  ",0, 0, 0, FORTH_END_BUFFER

start1:     	db ": bpon $0000 bp ;  ",0, 0, 0, FORTH_END_BUFFER
start2:     	db ": bpoff $0001 bp ;  ",0, 0, 0, FORTH_END_BUFFER
;start3:         db ": dirlist dir cls drop dup $00 > if $01 do .> BL .> .> BL .> .> loop then nop ;  ",0, 0, 0, FORTH_END_BUFFER
start3:         db ": dirlist dir cls drop dup $00 > if $01 do $08 i at . $01 i at . $04 i at . loop then nop ;  ",0, 0, 0, FORTH_END_BUFFER

; a small guess the number game

game1:          db ": gsn rnd8 v1! ;  ",0, 0, 0, FORTH_END_BUFFER
game1a:          db ": gs $00 $00 at Enter-a-number .- $00 $02 at between-1-and-255 .- ;  ",0, 0, 0, FORTH_END_BUFFER

game1b:          db ": gcb v2@ v1@ < if $00 $00 at Too-low! .- $01 then ;  ",0, 0, 0, FORTH_END_BUFFER
game1c:          db ": gcc v2@ v1@ > if $00 $00 at Too-high! .- $01 then ;  ",0, 0, 0, FORTH_END_BUFFER
game1d:          db ": gcd v2@ v1@ = if $00 $00 at Yes! .- $00 then ;  ",0, 0, 0, FORTH_END_BUFFER
game1s:          db ": gck gcb gcc gcd ;  ",0, 0, 0, FORTH_END_BUFFER
game1t:          db ": sc v3@ $01 + v3! ;  ",0, 0, 0, FORTH_END_BUFFER
game1f:          db ": fsc v3@ cls $01 $01 at You-Took .- $02 $03 at . ;  ",0, 0, 0, FORTH_END_BUFFER
game1z:         db ": ga $00 v3! gsn repeat cls gs $00 $03 at accept str2num v2! cls gck $02 pause sc until fsc nop ;  ",0, 0, 0, FORTH_END_BUFFER


;game2r:          db ": m2r rnd8 v1! ;  ",0, 0, 0, FORTH_END_BUFFER
;game2b1:          db ": m2b1 $1f $00 do i v2@ at rnd8 $30 < if A . then loop nop ;  ",0, 0, 0, FORTH_END_BUFFER
;game2b2:          db ": m2b cls $04 $01 do i v2! m2b1 loop ;  ",0, 0, 0, FORTH_END_BUFFER

; minesweeper/star war finding game

game2b:          db ": mb cls $04 $01 do i v2! $10 $01 do i v2@ at rnd8 $30 < if A . then loop loop ;  ",0, 0, 0, FORTH_END_BUFFER

sprompt1: db "Startup load...",0
sprompt2: db "Run? 1=No *=End #=All",0

forth_startup:
	ld hl, startcmds
	ld a, 0
	ld (os_last_cmd), a    ; tmp var to skip prompts if doing all

.start1:	push hl
	call clear_display
	ld de, sprompt1
        ld a, display_row_1
	call str_at_display
	ld de, sprompt2
        ld a, display_row_2
	call str_at_display
	pop hl
	push hl
	ld e,(hl)
	inc hl
	ld d,(hl)
        ld a, display_row_3
	call str_at_display
	call update_display


	ld a, (os_last_cmd)
	cp 0
	jr z, .startprompt
	call delay250ms
	jr .startdo
	
	

.startprompt:

	ld a,display_row_4 + display_cols - 1
        ld de, endprg
	call str_at_display
	call update_display
	call delay1s
	call cin_wait
			
	cp '*'
	jr z, .startupend1
	cp '#'
	jr nz, .startno
	ld a, 1
	ld (os_last_cmd),a
	jr .startdo
.startno:	cp '1'
	jr z,.startnxt 

	; exec startup line
.startdo:	
	pop hl
	push hl
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl

	push hl

	ld a, FORTH_END_BUFFER
	call strlent

	ld b,0
	ld c,l
	pop hl
	ld de, scratch
	ldir


	ld hl, scratch
	call forthparse
	call forthexec
	call forthexec_cleanup

	ld a, display_row_4
	ld de, endprog

	call update_display		

	ld a, (os_last_cmd)
	cp 0
	jr nz, .startnxt
	call next_page_prompt
        call clear_display
	call update_display		

	; move onto next startup line?
.startnxt:

	call delay250ms
	pop hl

	inc hl
	inc hl

	push hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	pop hl
	; TODO replace 0 test

	ex de, hl
	call ishlzero
;	ld a,e
;	add d
;	cp 0    ; any left to do?
	ex de, hl
	jp nz, .start1
	jr .startupend

.startupend1: pop hl
.startupend:

	call clear_display
	call update_display
	ret


; stack over and underflow checks

; init the words to detect the under/overflow

chk_stk_init:
	; a vague random number to check so we dont get any "lucky" hits
	ld a, 45
	ld l, a
	nop
	ld a, 23
	ld h, a

	ld (chk_word), hl     ; the word we need to check against

;	ld (chk_stund), hl	; stack points....
	ld (chk_stovr), hl
	ld (chk_ret_und), hl
	ld (chk_ret_ovr), hl
	ld (chk_loop_ovr), hl
	ld (chk_data_ovr), hl
	ret
	
check_stacks:
	; check all stack words

	push hl
	push de

;	ld de,(chk_word)
;	ld hl, (chk_stund)	; stack points....
;	if DEBUG_STK_FAULT
;		DMARK "FAa"
;		CALLMONITOR
;	endif
;	call cmp16
;	jp z, .chk_faulta
;
;	ld de, sfaultsu
;	jp .chk_fault

.chk_faulta: ld hl, (chk_stovr)
	ld de,(chk_word)
	if DEBUG_STK_FAULT
		DMARK "FAb"
		CALLMONITOR
	endif
	call cmp16
	jr z, .chk_fault1
	ld de, sfaultso
	jp .chk_fault
.chk_fault1: 
	ld hl, (chk_ret_und)
	ld de,(chk_word)
	if DEBUG_STK_FAULT
		DMARK "FAU"
		CALLMONITOR
	endif
	call cmp16
	jp z, .chk_fault2
	ld de, sfaultru
	jp .chk_fault
.chk_fault2: 
	ld hl, (chk_ret_ovr)
	ld de,(chk_word)
	if DEBUG_STK_FAULT
		DMARK "FA1"
		CALLMONITOR
	endif
	call cmp16
	jp z, .chk_fault3
	ld de, sfaultro
	jp .chk_fault
.chk_fault3: 
	ld hl, (chk_loop_ovr)
	ld de,(chk_word)
	if DEBUG_STK_FAULT
		DMARK "FA2"
		CALLMONITOR
	endif
	call cmp16
	jp z, .chk_fault4
	ld de, sfaultlo
	jp .chk_fault
.chk_fault4: 
	ld hl, (chk_data_ovr)
	ld de,(chk_word)
	if DEBUG_STK_FAULT
		DMARK "FA3"
		CALLMONITOR
	endif
	call cmp16
	jp z, .chk_fault5
	ld de, sfaultdo
	jp .chk_fault


.chk_fault5: 
	pop de
	pop hl

	ret

.chk_fault: 	call clear_display
		ld a, display_row_2
		call str_at_display
		   ld de, .stackfault
		ld a, display_row_1
		call str_at_display
		    ld de, debug_mark
		ld a, display_row_1+17
		call str_at_display
		call update_display

	; prompt before entering montior for investigating issue

	ld a, display_row_4
	ld de, endprog

	call update_display		

	call next_page_prompt

	pop de
	pop hl
		call monitor
		jp warmstart
		;jp 0
		;halt



.stackfault: 	db "Stack fault:",0

sfaultsu: 	db	"Stack under flow",0
sfaultso: 	db	"Stack over flow",0
sfaultru:	db "RTS underflow",0
sfaultro:	db "RTS overflow/LS underflow", 0
sfaultlo:	db "LS overflow/DTS underflow", 0
sfaultdo:	db "DTS overflow", 0


fault_dsp_under:
	ld de, .dsp_under
	jp .show_fault

fault_rsp_under:
	ld de, .rsp_under
	jp .show_fault
fault_loop_under:
	ld de, .loop_under
	jp .show_fault

.dsp_under: db "DSP Underflow",0
.rsp_under: db "RSP Underflow",0
.loop_under: db "LOOP Underflow",0


type_faultn: 	push de
		push hl
		call clear_display
		   ld de, .typefaultn
		ld a, display_row_1
		call str_at_display
		    ld de, debug_mark
		ld a, display_row_1+17
		call str_at_display
		call update_display

	; prompt before entering montior for investigating issue

	ld a, display_row_4
	ld de, endprog

	call update_display		

	call next_page_prompt

		push hl
		push de
		call monitor
		jp warmstart
		halt


.typefaultn: db "NUM Type Expected TOS!",0

type_faults: 	push de
		push hl
		call clear_display
		   ld de, .typefaults
		ld a, display_row_1
		call str_at_display
		    ld de, debug_mark
		ld a, display_row_1+17
		call str_at_display
		call update_display

	; prompt before entering montior for investigating issue

	ld a, display_row_4
	ld de, endprog

	call update_display		

	call next_page_prompt

		pop hl
		pop de
		call monitor
		jp warmstart


.typefaults: db "STR Type Expected TOS!",0

.show_fault: 	
		push de
		call clear_display
		pop de
		ld a, display_row_1
		call str_at_display
		    ld de, debug_mark
		ld a, display_row_1+17
		call str_at_display
		call update_display

	; prompt before entering montior for investigating issue

	ld a, display_row_4
	ld de, endprog

	call update_display		

	call next_page_prompt

		pop hl
		pop de
		call monitor
		jp warmstart
		halt
; eof
