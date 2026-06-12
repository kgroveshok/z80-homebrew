; Device related words

; | ## Device Words

if SOUND_ENABLE
.NOTE:
	CWHEAD .NOTEEND 31 "NB" 2 WORD_FLAG_CODE
; | NB ( u --  )  Sends a note byte to sound card  TODO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "NBE"
			CALLMONITOR
		endif

		
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		ld a, l
		call note_byte	

		NEXTW
.NOTEEND:
endif

;if BASE_KEV
;.BUZZ:
;
;	CWHEAD .BUZZE 31 "BUZZ" 4 WORD_FLAG_CODE
;;  BUZZ ( dur freq -- )   Sound buzzer for duration dur with osc freq of freq ms  DONE
;
;		if DEBUG_FORTH_WORDS_KEY
;			DMARK "BUZ"
;			CALLMONITOR
;		endif
;
;		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
;		push hl
;		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
;
;		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
;		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
;
;		pop bc
;		ld b, c
;		call sound_buzzer
;
;		NEXTW
;.BUZZE:
;endif


if TAPE_SUPPORT

.GP2:

	CWHEAD .GPI 31 "SETTAPE" 7 WORD_FLAG_CODE
; | SETTAPE ( port gap samples hpulse lpulse high low -- )   Set parameters for tape support | DONE
; | | port - Device address port; default is Device A on 00h
; | | samples - How many sample cycles to count pulses
; | | gap - Gap period counter; default is 250
; | | hpulse - Count of pulses for 1; default is 6
; | | lpulse - Count of pulses for 0; default is 2
; | | high - High bit period counter; default is 150
; | | low - Low bit period counter; default is 50

		if DEBUG_FORTH_WORDS_KEY
			DMARK "TSE"
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		ld (tape_tm_low), hl
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		ld (tape_tm_high), hl
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		ld a, l
		ld (tape_pulse_low), a
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		ld a, l
		ld (tape_pulse_high), a
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 


		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		ld (tape_samples), hl
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		ld a, l
		ld (tape_tm_gap), a
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		ld a, l
		ld (tape_port), a
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 
		NEXTW


.GPI:
	CWHEAD .GPS 31 "SAVES" 5 WORD_FLAG_CODE
; | SAVES ( s1 ... sn c n -- )    Save a count of c strings using file name of n to tape | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "SAS"
			CALLMONITOR
		endif

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		push hl    ; file name
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		push hl    ; count
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol
		  ; top string
		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		pop bc    ; count
		pop de    ; file name

; TODO handle more than one string
		call tape_save
				
		NEXTW


.GPS:
	CWHEAD .TLOAD 31 "SAVE" 7 WORD_FLAG_CODE
; | SAVE ( n -- )    Save all uuser words to tape with given name n | TO DO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "SAV"
			CALLMONITOR
		endif

		NEXTW

.TLOAD:
	CWHEAD .TCAL 31 "LOAD" 4 WORD_FLAG_CODE
; | LOAD ( n -- )    Load file n from tape and exec | TO DO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "LOD"
			CALLMONITOR
		endif

		NEXTW

.TCAL:
	CWHEAD .TTEST 31 "TAPECAL" 7 WORD_FLAG_CODE
; | TAPECAL (  -- )    Listen to a tape header and report on bit detection pulses | TO DO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "TCA"
			CALLMONITOR
		endif

		call tape_calibration

		NEXTW

.TTEST:
	CWHEAD .TAPEEND 31 "TAPETEST" 8 WORD_FLAG_CODE
; | TAPETEST (  -- )    Record a repeating stripe pattern of 0 and 1 for testing record and playback via TAPECAL | TO DO
		if DEBUG_FORTH_WORDS_KEY
			DMARK "TTS"
			CALLMONITOR
		endif

		call tape_test

		NEXTW

.TAPEEND:
endif


	CWHEAD .SOUT 31 "IN" 2 WORD_FLAG_CODE
; | IN ( u1 -- u )    Perform Z80 IN with u1 being the port number. Push result to TOS | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "IN."
			CALLMONITOR
		endif
		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop bc

		; do the sub
;		ex de, hl

		in l,(c)

		; save it

		ld h,0

		; TODO push value back onto stack for another op etc

		;call forth_push_numhl

		FORTH_PUSH_VALUEHL
		NEXTW
.SOUT:
	CWHEAD .SPIO 32 "OUT" 3 WORD_FLAG_CODE
; | OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "OUT"
			CALLMONITOR
		endif

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

;		pop hl

		pop bc

		if DEBUG_FORTH_WORDS
			DMARK "OUT"
			CALLMONITOR
		endif

		out (c), l

		NEXTW


.SPIO:

if STORAGE_SE
	CWHEAD .SPICEH 61 "SPICEL" 6 WORD_FLAG_CODE
; | SPICEL ( -- ) Set SPI CE low for the currently selected device |  DONE

		call spi_ce_low
    NEXTW

.SPICEH:
	CWHEAD .SPIBOb 61 "SPICEH" 6 WORD_FLAG_CODE
; | SPICEH ( -- ) Set SPI CE high for the currently selected device |  DONE

		call spi_ce_high
    NEXTW

.SPIBOb:

	CWHEAD .SPII 61 "SPIO" 4 WORD_FLAG_CODE
; | SPIO ( u1 -- ) Send byte u1 to SPI  |  DONE

		if DEBUG_FORTH_WORDS_KEY
			DMARK "SPo"
			CALLMONITOR
		endif
		; get port


		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl    ; u1 

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

;		pop hl   ; u2 - addr

		; TODO Send SPI byte

;		push hl
;		call spi_ce_low
;		pop hl
		ld a, l
		call spi_send_byte
;		call spi_ce_high

		NEXTW

.SPII:
	CWHEAD .SESEL 62 "SPII" 5 WORD_FLAG_CODE
; | SPII ( -- u1 ) Get a byte from SPI  | DONE
		if DEBUG_FORTH_WORDS_KEY
			DMARK "SPi"
			CALLMONITOR
		endif

		; TODO Get SPI byte

		call spi_read_byte

		if DEBUG_FORTH_WORDS
			DMARK "Si2"
			CALLMONITOR
		endif
		ld h, 0
		ld l, a
		if DEBUG_FORTH_WORDS
			DMARK "Si3"
			CALLMONITOR
		endif
		;call forth_push_numhl
		FORTH_PUSH_VALUEHL

		NEXTW



.SESEL:
	CWHEAD .SESELS 82 "BANK?" 5 WORD_FLAG_CODE
; | BANK? ( -- u ) Reports on the serial EEPROM Bank Device at bank address u1 1-5.  | DONE
; | | Zero is disabled storage.
		if DEBUG_FORTH_WORDS_KEY
			DMARK "BN?"
			CALLMONITOR
		endif
		ld a, (spi_device_id)
		sub '0'
		ld h, 0
		ld l, a
		FORTH_PUSH_VALUEHL
		;call forth_push_numhl
		NEXTW
.SESELS:
	CWHEAD .CARTDEV 82 "BANK" 4 WORD_FLAG_CODE
; | BANK ( u1 -- ) Select Serial EEPROM Bank Device at bank address u1 1-5 (disables CARTDEV).  | DONE
; | | Set to zero to disable storage.
		if DEBUG_FORTH_WORDS_KEY
			DMARK "BNK"
			CALLMONITOR
		endif

		ld a, 255
		ld (spi_cartdev), a

		; get bank

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

;		pop hl


		ld c, SPI_CE_HIGH
		ld b, '0'    ; human readable bank number

		ld a, l

		if DEBUG_FORTH_WORDS
			DMARK "BNK"
			CALLMONITOR
		endif

		; active low

;		cp 0
		or a
		jr z, .bset
		cp 1
		jr nz, .b2
		res 0, c
		ld b, '1'    ; human readable bank number
.b2:		cp 2
		jr nz, .b3
		res 1, c
		ld b, '2'    ; human readable bank number
.b3:		cp 3
		jr nz, .b4
		res 2, c
		ld b, '3'    ; human readable bank number
.b4:		cp 4
		jr nz, .b5
		res 3, c
		ld b, '4'    ; human readable bank number
.b5:		cp 5
		jr nz, .bset
		res 4, c
		ld b, '5'    ; human readable bank number

.bset:
		ld a, c
		ld (spi_device),a
		ld a, b
		ld (spi_device_id),a
		if DEBUG_FORTH_WORDS
			DMARK "BN2"
			CALLMONITOR
		endif

		; set default SPI clk pulse time as disabled for BANK use

		ld a, 0
		ld (spi_clktime), a

		NEXTW

.CARTDEV:
	CWHEAD .ENDDEVICE 82 "CARTDEV" 7 WORD_FLAG_CODE
; | CARTDEV ( u1 -- ) Select cart device 1-8 (Disables BANK). | DONE
; | | Set to zero to disable devices.
		if DEBUG_FORTH_WORDS_KEY
			DMARK "CDV"
			CALLMONITOR
		endif

		; disable se storage bank selection

		ld a, SPI_CE_HIGH		; ce high
		ld (spi_device), a

		; get bank

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

;		pop hl

		; active low

		ld c, 255

		ld a, l
		if DEBUG_FORTH_WORDS
			DMARK "CDV"
			CALLMONITOR
		endif
;		cp 0
		or a
		jr z, .cset
		cp 1
		jr nz, .c2
		res 0, c
.c2:		cp 2
		jr nz, .c3
		res 1, c
.c3:		cp 3
		jr nz, .c4
		res 2, c
.c4:		cp 4
		jr nz, .c5
		res 3, c
.c5:		cp 5
		jr nz, .c6
		res 4, c
.c6:		cp 6
		jr nz, .c7
		res 5, c
.c7:		cp 7
		jr nz, .c8
		res 6, c
.c8:		cp 8
		jr nz, .cset
		res 7, c
.cset:		ld a, c
		ld (spi_cartdev),a

		if DEBUG_FORTH_WORDS
			DMARK "CD2"
			CALLMONITOR
		endif

		; set default SPI clk pulse time as 10ms for CARTDEV use

		ld a, $0a
		ld (spi_clktime), a
		NEXTW
endif

.ENDDEVICE:
; eof

