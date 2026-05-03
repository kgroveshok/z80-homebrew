; Tape support


; encoding
; 
; pulse marks  of stream
; proportial

DEBUG_TAPE: equ 1


; setup default tape params
tape_init:    
	ld a, Device_A
	ld (tape_port), a

	ld a, 250
	ld (tape_tm_gap), a

	ld a, 200
	ld (tape_tm_freq), a

	ld hl, 50
	ld (tape_tm_high), hl

	ld hl, 10
	ld (tape_tm_low), hl
	ret

; support routinues for tape


; Tape Output

; osciallate the pin for the required duration

tape_osc: 
	; hl has the number of iterations
	; c = port number
	; d = bus data
	
;	ld a, (tape_tm_freq)
;	ld b, a
;.to:
	out (c), d
	
;	cp 0
;	jr z, .fski
;	ld a, 1
;	call aDelayInMS

	; do a brief pause
;	push bc
;.flo:	
;    and     255  	; 7
;    dec     bc      	; 6
;    ld      a,c     	; 4
;    or      b     	; 4
;	djnz .flo
;	pop bc

	dec hl
	call ishlzero
	jr nz, tape_osc
	
	ret

; output a gap period
tape_gap: 
	ld a, (tape_tm_gap)
	call aDelayInMS

if DEBUG_TAPE
	call delay1s 
	call delay1s 
	call delay1s 
	call delay1s 
	call delay1s 
	call delay1s 
endif
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
	call tape_ready_stop
	call clear_display
	ret


; TODO on load need to do a clear of all words?

; Listen to the start of a tape header and calculate pulse lengths and confirm can read

tape_calibration:
		call tape_ready_load

	; start a counter for 1s max length of header


	; init sync fields
;	ld hl, tape_sync
;	ld a, 0
;	ld (hl), a
;	ld de, tape_sync+1
;	ld bc, 10
;	ldir

	call clear_display

	ld hl, 0
.tc:

	push hl
	call active
	ex de, hl
	ld a, display_row_4
	call  str_at_display
	call update_display
	call cin
	cp 0
	jr z, .tce
	pop hl


	call tape_detect

	cp 0
	jr z, .tc

.tc1:
	push hl
	inc hl
	push hl
	ex de, hl

	ld hl, scratch
	call uitoa_16
	ex de, hl
	ld a, display_row_4+4
	call  str_at_display
	call update_display
	pop hl
	jr .tc


.tce:
	call tape_ready_stop
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
	call tape_gap
	

	call active
	ex de, hl
	ld a, 0
	call  str_at_display
	ld a, 2
	ld de, .tlow
	call  str_at_display
	call update_display

	call tape_low
	call tape_gap

	call cin
	cp 0
	jr z, .tt1
	call tape_ready_stop
	ret

; wait for rising edge and then count pulses until possible gap (ie no pulses detected for 5ms)

tape_detect:
	ld b, 255
; initial sample
	in a, (0)
	ld c, a

.td2:
	in a, (0)
	cp c
	jr nz, .td3
	djnz .td2

; no change detected
	ld a, 0
	ret

; change detected
.td3:   ld a, 1
	ret


; eof
