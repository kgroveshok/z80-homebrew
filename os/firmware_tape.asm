; Tape support

; setup default tape params
tape_init:    
	ld a, Device_A
	ld (tape_port), a
	ld hl, 150
	ld (tape_tm_gap), hl
	ld hl, 70
	ld (tape_tm_high), hl
	ld hl, 20
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
	ld a, 1
	call aDelayInMS
	
	dec hl
	ld a, l
	add h
	cp 0
	jr nz, tape_osc
	
	ret

; output a gap period
tape_gap: 
	ld hl, (tape_tm_gap)
	ld a, l
	call aDelayInMS
	ret

; output a high period

tape_high:
	ld a, (tape_port)
	ld c, a
	ld d, 255
	ld hl, (tape_tm_high)
	call tape_osc
	 ret

; output a low period

tape_low: 

	ld a, (tape_port)
	ld c, a
	ld d, 255
	ld hl, (tape_tm_low)
	call tape_osc
	 ret

; end of save marker

tape_end:
	ld a, 255
	call tape_byte_out
	call tape_gap
	ld a, 255
	call tape_byte_out
	call tape_gap
	ld a, 255
	call tape_byte_out
	call tape_gap
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


	 ret

; output a string

; hl - pointer to string

tape_strz_out: 
	ld a, (hl)
	push hl
	call tape_byte_out

	call tape_gap
	call tape_gap

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

tape_ready_load: 

	ld hl, trr3
	ld de, trr2
	call info_panel
	ret

trr1: db "Start recorder...",0
trr3: db "Start playback...",0
trr2: db "Press any key when ready.",0
trr4: db "Tape operation in progesss...", 0


; Tape Input

; Perform a save to tape

; hl - string to output
; de - file name

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

	; tape pulse training header

	call tape_high
	call tape_gap
	call tape_low
	call tape_gap

	call tape_high
	call tape_gap
	call tape_low
	call tape_gap

	call tape_high
	call tape_gap
	call tape_low
	call tape_gap

	; start of name

	call tape_gap
	call tape_gap
	call tape_gap

	; TODO output file name

	pop hl   ; file name
	call tape_strz_out

	call tape_gap
	call tape_gap
	call tape_gap
	call tape_gap

	pop hl ; string to output
	call tape_strz_out

	call tape_end
	call clear_display
	ret


; TODO on load need to do a clear of all words?

; Listen to the start of a tape header and calculate pulse lengths and confirm can read

tape_calibration:
		call tape_ready_load

	; start a counter for 1s max length of header


	; init sync fields

	ld hl, tape_sync
	ld a, 0
	ld (hl), a
	ld de, tape_sync+1
	ld bc, 10
	ldir

	call tape_detect

	ld d, 0
	ld a, (tape_sync)
	ld e, a
        ld hl, scratch
	call uitoa_16
	ex de, hl
	ld a, 0	
	call  str_at_display
	ld d, 0
	ld a, (tape_sync+1)
	ld e, a
        ld hl, scratch
	call uitoa_16
	ex de,hl
	ld a, 5
	call  str_at_display
	call update_display

	ret

; wait for rising edge and then count pulses until possible gap (ie no pulses detected for 5ms)

tape_detect:
	ld a, 0
	ld hl, (tape_sync)     ; high pulse count
	ld hl, (tape_sync+1)   ; low pulse count


.td1:   in a,(0)
	; TODO add break out
	cp 0
	jr z, .td1

	; rising edge start count
;	ld de, 10000
.td2:
	ld hl, (tape_sync)
		inc (hl)
.td3: 
	ld a, 1
	call aDelayInMS
; wait for next pulse
	in a,(0)
	cp 0
	jr nz, .td4
	ld hl, (tape_sync+1)
	inc (hl)
	ld a,(hl)
	cp 5
	jr .td2

.td4:
	 ; in gap
; wait for rising edge
; on edge 
; count pulse
; count no pulse
; if no pulse for 5ms then must be gap
; save pulse size for each gap found
; once gap count is 6 then exit and report counts

		ret


; eof
