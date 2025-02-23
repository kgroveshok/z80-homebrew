;
; kernel to the forth OS

DS_TYPE_STR: equ 1     ; string type
DS_TYPE_INUM: equ 2     ; $ 16 bit unsigned int usually a hex address
DS_TYPE_SNUM: equ 3     ; $ 16 bit signed int 
;DS_TYPE_FNUM: equ 3      ; 24/32 bit floating point  do string conversion instead of a new type

FORTH_PARSEV1: equ 0
FORTH_PARSEV2: equ 0
FORTH_PARSEV3: equ 0
FORTH_PARSEV4: equ 0
FORTH_PARSEV5: equ 1

;if FORTH_PARSEV5
;	FORTH_END_BUFFER: equ 0
;else
FORTH_END_BUFFER: equ 127
;endif

FORTH_TRUE: equ 1
FORTH_FALSE: equ 0

if FORTH_PARSEV4
include "forth_stackops.asm"
endif

if FORTH_PARSEV5
include "forth_stackopsv5.asm"
endif

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


; Cold Start - this is called to setup the whole Forth system

forth_init:

	; setup stack over/under flow checks

;	if DEBUG_FORTH_STACK_GUARD
;		call chk_stk_init
;	endif

	; enable auto display updates (slow.....)

	ld a, 1
	ld (cli_autodisplay), a

	; if storage is in use disable long reads for now
	ld a, 0
	ld (store_longread), a


	; show start up screen

	call clear_display

	ld a,0
	ld (f_cursor_ptr), a

	; set start of word list in start of ram - for use when creating user words

	ld hl, baseram
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

include "forth_autostart.asm"

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

	ld a, 0
	;ld a, FORTH_END_BUFFER
	call strlent
	inc hl   ; include zero term to copy
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
; do a dump to cli and not warmstart so we preserve all of the uwords. 
; TODO Make optional fault restart to cli or warm boot?
		;jp warmstart
		jp cli
		halt

; handle the auto run of code from files in storage


if STORAGE_SE

sprompt3: db "Loading from start-up file?:",0
sprompt4: db "(Y=Any key/N=No)",0


forth_autoload:

	; load block 0 of store 1
	
	ld a, $fe      ; bit 0 clear
	ld (spi_device), a

	call storage_get_block_0

	ld a, (store_page+STORE_0_AUTOFILE)

	cp 0
	ret z     ; auto start not enabled

	call clear_display

	; set bank

		ld a, (store_page+STORE_0_BANKRUN)
		ld (spi_device), a

	; get file id to load from and get the file name to display

		ld a, (store_page+STORE_0_FILERUN)

		ld l, 0
		ld h, a
		ld de, store_page

		if DEBUG_FORTH_WORDS
			DMARK "ASp"
			CALLMONITOR
		endif
		call storage_read

		if DEBUG_FORTH_WORDS
			DMARK "ASr"
			CALLMONITOR
		endif

		call ishlzero
		ret z             ; file not found

		ld a, display_row_2 + 10
		ld de, store_page+3
		call str_at_display
	
;

	ld a, display_row_1+5
	ld de, sprompt3
	call str_at_display
	ld a, display_row_3+15
	ld de, sprompt4
	call str_at_display

	call update_display

	call cin_wait
	cp 'n'
	ret z
	cp 'N'
	ret z

	call delay1s

	ld a, (store_page+2)
	ld (store_openmaxext), a    ; save count of ext
	ld a, 1 
	ld (store_openext), a    ; save count of ext

.autof: 
	ld l , a
	
	ld a, (store_page)
	ld h, a	
	ld de, store_page
		if DEBUG_FORTH_WORDS
			DMARK "ASl"
			CALLMONITOR
		endif
		call storage_read
	call ishlzero
	ret z
;	jr z, .autoend

		if DEBUG_FORTH_WORDS
			DMARK "ASc"
			CALLMONITOR
		endif
	ld de, store_page+2
	ld a, display_row_4
	call str_at_display

	call update_display
	call delay250ms



	ld hl, store_page+2
	call forthparse
	call forthexec
	call forthexec_cleanup

	
	ld a, (store_openext)
	inc a
	ld (store_openext), a    ; save count of ext

	jr .autof
;.autofdone:
;
;		if DEBUG_FORTH_WORDS
;			DMARK "ASx"
;			CALLMONITOR
;		endif
;;	call clear_display
;	ret



endif


; eof
