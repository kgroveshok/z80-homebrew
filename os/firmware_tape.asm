; Tape support


; encoding
; 
; pulse marks  of stream
; proportial


; setup default tape params
tape_init:    
	ld a, Device_A
	ld (tape_port), a

	ld a, 250
	ld (tape_tm_gap), a

	ld a, 6
	ld (tape_pulse_high), a

	ld a, 2
	ld (tape_pulse_low), a

	ld hl, 50
	ld (tape_tm_high), hl

	ld hl, 50
	ld (tape_tm_low), hl
	ret

; support routinues for tape


; Tape Output

; osciallate the pin for the required duration

tape_osc: 
	; hl has the number of iterations
	; c = port number
	; d = bus data
	
	out (c), d

	dec hl
	call ishlzero
	jr nz, tape_osc
	
	ret

; output a gap period
tape_gap: 
	ld a, (tape_tm_gap)
	call aDelayInMS
	ret

tape_byte_gap:
	call tape_gap
	call tape_gap
	call tape_gap
	call tape_gap
	ret

; output a high period

tape_high:
	ld a, (tape_port)
	ld c, a
	ld d, 255
	ld a, (tape_pulse_high)
	ld b, a
.th:	ld hl, (tape_tm_high)
	call tape_osc
	call tape_gap
	djnz .th
	 ret

; output a low period

tape_low: 

	ld a, (tape_port)
	ld c, a
	ld d, 255
	ld a, (tape_pulse_low)
	ld b, a
.tl:	ld hl, (tape_tm_low)
	call tape_osc
	call tape_gap
	djnz .tl
	 ret

; end of save marker

tape_end:
	ld a, 255
	call tape_byte_out
	call tape_byte_gap

	ld a, 255
	call tape_byte_out
	call tape_byte_gap
	ld a, 255
	call tape_byte_out
	call tape_byte_gap
	 ret

; output an encoded byte

tape_byte_out:
	; a = byte to output
	ld b, 8
	ld c, a
.tbo:   
	push bc
	bit 7, c
	jr z, .tbol
	call tape_high
	jr .tbn
.tbol:
	call tape_low
.tbn:
	call tape_gap
	pop bc
	sla c
	djnz .tbo
	call tape_byte_gap

	 ret

; output a string

; hl - pointer to string

tape_strz_out: 
	ld a, (hl)
	push hl
	call tape_byte_out

;	call tape_gap
;	call tape_gap

	call active
	ex de, hl
	ld a, 0
	call  str_at_display
	call update_display

	pop hl
	ld a, (hl)
	cp 0
	ret z
	inc hl
	jr tape_strz_out

; prompt the user to ready the tape to record

tape_ready_rec: 

	ld hl, trr1
	ld de, trr2
	call info_panel
	ret

tape_ready_play:
tape_ready_load: 

	ld hl, trr3
	ld de, trr2
	call info_panel
	ret

tape_ready_stop: 

	ld hl, trr6
	ld de, trr2
	call info_panel
	ret

trr1: db "Start recorder...",0
trr3: db "Start playback...",0
trr2: db "Press any key when ready.",0
trr4: db "Tape operation in progesss...", 0
trr6: db "Stop tape.", 0


; Tape Input

; Perform a save to tape

; hl - string to output
; de - file name

; TODO Add save progress

tape_save: 

	push hl
	push de

	; prompt to ready tape and press any key

	call tape_ready_rec
	call clear_display

	ld a, 4 
	ld de, trr4
	call  str_at_display
	call update_display

; TODO Notify tape header

	; tape pulse training header

	call tape_high
	call tape_byte_gap
	call tape_low
	call tape_byte_gap

	call tape_high
	call tape_byte_gap
	call tape_low
	call tape_byte_gap

	call tape_high
	call tape_byte_gap
	call tape_low
	call tape_byte_gap

; TODO Notify name save

	; start of name

	call tape_byte_gap
	call tape_byte_gap

	; TODO output file name

	pop hl   ; file name
	call tape_strz_out

	call tape_byte_gap
	call tape_byte_gap

; TODO show progress of number of bytes to save vs byte number

	pop hl ; string to output
	call tape_strz_out
; TODO have a save silient with no progress and one with progress

; TODO notify tape end marker
	call tape_end
	call tape_ready_stop
	call clear_display
	ret


; TODO on load need to do a clear of all words?

; Listen to the start of a tape header and calculate pulse lengths and confirm can read

tape_calibration:
	; start a counter for 1s max length of header



	call tape_ready_load
	call clear_display

	call delay1s
	call delay1s
	call delay1s
	call delay1s
	call delay1s

	; init sync fields
	ld hl, 0
	ld (tape_sync), hl
	ld (tape_sync+2), hl
.tc:


	call cin
	cp 0
	jr nz, .tce

	ld a, 1
	call aDelayInMS

	ld hl, (tape_sync+2)
	inc hl
	ld (tape_sync+2), hl

	call tape_detect

	cp 0
	jr z, .tc

.tc1:
	call scroll_up

	; draw stats line

	call active
	ex de, hl
	ld a, display_row_4
	call  str_at_display

	; inc pulse counter

	ld hl, (tape_sync)
	inc hl
	ld (tape_sync), hl

	ex de, hl

	ld hl, scratch
	call uitoa_16
	ex de, hl
	ld a, display_row_4+4

	call  str_at_display

	; period counter

	ld de, (tape_sync+2)

	ld hl, scratch
	call uitoa_16
	ex de, hl
	ld a, display_row_4+10
	call  str_at_display

	call update_display

	; reset period counter
	ld hl, 0
	ld (tape_sync+2), hl
	jr .tc


.tce:
	call tape_ready_stop
	call clear_display
	ret


.thigh: db "High",0
.tlow: db "Low ",0

tape_test:
	call tape_ready_rec


	call clear_display

	
.tt1:   
	call active
	ex de, hl
	ld a, 0
	call  str_at_display

	ld a, 2
	ld de, .thigh
	call  str_at_display
	call update_display

	call tape_high
	call delay1s
	call delay1s
	

	call active
	ex de, hl
	ld a, 0
	call  str_at_display

	ld a, 2
	ld de, .tlow
	call  str_at_display
	call update_display

	call tape_low
	call delay1s
	call delay1s

	call cin
	cp 0
	jr z, .tt1
	call tape_ready_stop
	call clear_display
	ret

; wait for rising edge and then count pulses until possible gap (ie no pulses detected for 5ms)

tape_detect:
;	ld b, 255
; initial sample

;	ld a, (tape_sync+3)
;	ld c, a
;.td2:
	in a, (0)
	and 1
;	cp c
;	jr nz, .td3
;	djnz .td2
;
;	ld (tape_sync+3), a
;; no change detected
;	ld a, 0
	ret

; change detected
;.td3:   
;	
;	ld (tape_sync+3), a
;	ld a, 1
;	ret


; eof
