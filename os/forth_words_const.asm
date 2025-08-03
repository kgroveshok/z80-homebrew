
; | ## Constants (i.e. Useful memory addresses that can set or get features)


.SPITIME:
	CWHEAD .VA 99 "SPITIME" 7 WORD_FLAG_CODE
; | SPITIME ( -- u1 )   Pushes address of the SPI pulse counter/delay to stack
;
; | If using BANK devices then leave as is.
; | Only really useful for the CARTDEV where other devices may be too far or slow. In particular
; | the multiplexing of the PicoSPINet device which might not be running fast enough for all of the nodes

		ld hl, spi_clktime 
		call forth_push_numhl

		NEXTW


.VA:
	CWHEAD .SYMBOL 99 "VA" 2 WORD_FLAG_CODE
; | VA ( -- u1 )   Pushes address of block of memory used for v1..5
		ld hl, cli_var_array
		call forth_push_numhl

		NEXTW

.SYMBOL:
	CWHEAD .ENDCONST 99 "SYMBOL" 6 WORD_FLAG_CODE
; | SYMBOL ( u1 -- )  Get the address of a system symbol from a look up table to TOS  | DONE
; |
; | The value is the number reference and the final address is pushed to stack

; | dw sym_table
; | dw nmi_vector
; | dw cli_autodisplay
; | dw cli_data_sp
; | dw cli_data_stack
; | dw cli_loop_sp
; | dw cli_loop_stack
; | dw cli_var_array
; | dw cursor_col
; | dw cursor_ptr
; | ; 10
; | dw cursor_row
; | dw debug_mark
; | dw display_fb0
; | dw display_fb1
; | dw display_fb2
; | dw display_fb3
; | dw display_fb_active
; | dw execscratch
; | dw f_cursor_ptr
; | dw hardware_word
; | ;20
; | dw input_at_cursor
; | dw input_at_pos
; | dw input_cur_flash
; | dw input_cur_onoff
; | dw input_cursor
; | dw input_display_size
; | dw input_len
; | dw input_ptr
; | dw input_size
; | dw input_start
; | ; 30
; | dw input_str
; | dw input_under_cursor
; | dw os_cli_cmd
; | dw os_cur_ptr
; | dw os_current_i
; | dw os_input
; | dw os_last_cmd
; | dw os_last_new_uword
; | dw debug_vector
; | dw os_view_hl
; | ;40
; | dw os_word_scratch
; | dw portbctl
; | dw portbdata
; | dw spi_cartdev
; | dw spi_cartdev2
; | dw spi_clktime
; | dw spi_device
; | dw spi_device_id
; | dw spi_portbyte
; | dw stackstore
; | ; 50
; | if STORAGE_SE
; | dw storage_actl
; | dw storage_adata
; | else
; | dw 0
; | dw 0
; | endif
; | dw storage_append
; | if STORAGE_SE
; | dw storage_bctl
; | else
; | dw 0
; | endif
; | dw store_bank_active
; | dw store_filecache
; | dw store_longread
; | dw store_openaddr
; | dw store_openext
; | dw store_openmaxext
; | ; 60
; | dw store_page
; | dw store_readbuf
; | dw store_readcont
; | dw store_readptr
; | dw store_tmpext
; | dw store_tmpid
; | dw store_tmppageid
; | dw malloc
; | dw free
; | dw cin
; | ; 70
; | dw cin_wait
; | dw forth_push_numhl
; | dw forth_push_str

		if DEBUG_FORTH_WORDS_KEY
			DMARK "SYM"
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL

		ld a, l    


		if DEBUG_FORTH_WORDS
			DMARK "SY1"
			CALLMONITOR
		endif
		
		push af	
		FORTH_DSP_POP
		pop af

		sla a 
	
		
		if DEBUG_FORTH_WORDS
			DMARK "SY"
			CALLMONITOR
		endif

		ld hl, sym_table
		call addatohl
		call loadwordinhl
		call forth_push_numhl


	       NEXTW

sym_table:

; 0
dw sym_table
dw nmi_vector
dw cli_autodisplay
dw cli_data_sp
dw cli_data_stack
dw cli_loop_sp
dw cli_loop_stack
dw cli_var_array
dw cursor_col
dw cursor_ptr
; 10
dw cursor_row
dw debug_mark
dw display_fb0
dw display_fb1
dw display_fb2
dw display_fb3
dw display_fb_active
dw execscratch
dw f_cursor_ptr
dw hardware_word
;20
dw input_at_cursor
dw input_at_pos
dw input_cur_flash
dw input_cur_onoff
dw input_cursor
dw input_display_size
dw input_len
dw input_ptr
dw input_size
dw input_start
; 30
dw input_str
dw input_under_cursor
dw os_cli_cmd
dw os_cur_ptr
dw os_current_i
dw os_input
dw os_last_cmd
dw os_last_new_uword
dw debug_vector
dw os_view_hl
;40
dw os_word_scratch
dw portbctl
dw portbdata
dw spi_cartdev
dw spi_cartdev2
dw spi_clktime
dw spi_device
dw spi_device_id
dw spi_portbyte
dw stackstore
; 50
if STORAGE_SE
dw storage_actl
dw storage_adata
else
dw 0
dw 0
endif
dw storage_append
if STORAGE_SE
dw storage_bctl
else
dw 0
endif
dw store_bank_active
dw store_filecache
dw store_longread
dw store_openaddr
dw store_openext
dw store_openmaxext
; 60
dw store_page
dw store_readbuf
dw store_readcont
dw store_readptr
dw store_tmpext
dw store_tmpid
dw store_tmppageid
dw malloc
dw free
dw cin
; 70
dw cin_wait
dw forth_push_numhl
dw forth_push_str


.ENDCONST:

; eof


