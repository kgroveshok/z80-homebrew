
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
dw cli_autodisplay
dw cli_buffer
dw cli_data_sp
dw cli_data_stack
dw cli_execword
dw cli_loop_sp
dw cli_loop_stack
dw cli_mvdot
dw cli_nextword
dw cli_origptr
dw cli_origtoken
; 11
dw cli_ptr
dw cli_ret_sp
dw cli_ret_stack
dw cli_token
dw cli_var_array
dw cursor_col
dw cursor_ptr
dw cursor_row
dw cursor_shape
dw debug_mark
; 21
dw display_fb0
dw display_fb1
dw display_fb2
dw display_fb3
dw display_fb_active
dw execscratch
dw f_cursor_ptr
dw hardware_word
dw input_at_cursor
dw input_at_pos
; 31
dw input_cur_flash
dw input_cur_onoff
dw input_cursor
dw input_display_size
dw input_len
dw input_ptr
dw input_size
dw input_start
dw input_str
dw input_under_cursor
; 41
dw key_actual_pressed
dw key_fa
dw key_face_held
dw key_fb
dw key_fc
dw key_fd
dw key_held
dw key_held_prev
dw key_init
dw key_repeat_ct
; 51
dw key_rows
dw key_shift
dw key_symbol
dw keyscan_scancol
dw keyscan_table
dw keyscan_table_row1
dw keyscan_table_row2
dw keyscan_table_row3
dw keyscan_table_row4
dw keyscan_table_row5
; 61
dw os_cli_cmd
dw os_cur_ptr
dw os_current_i
dw os_input
dw os_last_cmd
dw os_last_new_uword
;dw os_view_disable
dw debug_vector
dw os_view_hl
dw os_word_scratch
dw portbctl
; 71
dw portbdata
dw spi_cartdev
dw spi_cartdev2
dw spi_clktime
dw spi_device
dw spi_device_id
dw spi_portbyte
dw stackstore
if STORAGE_SE
dw storage_actl
dw storage_adata
else
dw 0
dw 0
endif
; 81
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
dw store_page
dw store_readbuf
; 91
dw store_readcont
dw store_readptr
dw store_tmpext
dw store_tmpid
dw store_tmppageid

.ENDCONST:

; eof


