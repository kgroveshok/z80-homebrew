; Device related words

; | ## Device Words

if SOUND_ENABLE
.NOTE:
	CWHEAD .AFTERSOUND 31 "NOTE" 4 WORD_FLAG_CODE
; | NOTE ( ud uf --  )  Plays a note of frequency uf for the duration of ud millseconds | TODO

	

		NEXTW
.AFTERSOUND:
endif


USE_GPIO: equ 0

if USE_GPIO
.GP1:
	CWHEAD .GP2 31 "IOIN" 4 WORD_FLAG_CODE
; | IOIN ( u1 -- u )    Perform a GPIO read of pin u1 and push result  | 
		NEXTW
.GP2:
	CWHEAD .GP3 31 "IOOUT" 5 WORD_FLAG_CODE
; | IOOUT ( u1 u2 --  )    Perform a GPIO write of pin u1 with pin set to 0 or 1 in u2  | 

		NEXTW

.GP3:
	CWHEAD .GP4 31 "IOBYTE" 5 WORD_FLAG_CODE
; | IOBYTE ( u1 --  )    Perform a GPIO write of byte u1  | 

		NEXTW

.GP4:
	CWHEAD .SIN 31 "IOSET" 5 WORD_FLAG_CODE
; | IOSET ( u1 --  )    Setup GPIO pins for I/O direction. Bit is set for write else read pin  | 

		NEXTW
.SIN:


endif


	CWHEAD .SOUT 31 "IN" 2 WORD_FLAG_CODE
; | IN ( u1 -- u )    Perform Z80 IN with u1 being the port number. Push result to TOS | TO TEST
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

		call forth_push_numhl
		NEXTW
.SOUT:
	CWHEAD .SPIO 32 "OUT" 3 WORD_FLAG_CODE
; | OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | DONE

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
	CWHEAD .SPIOb 61 "SPICEH" 6 WORD_FLAG_CODE
; | SPICEH ( -- ) Set SPI CE high for the currently selected device |  DONE

		call spi_ce_high
    NEXTW


.SPIOb:

	CWHEAD .SPII 61 "SPIO" 4 WORD_FLAG_CODE
; | SPIO ( u1 -- ) Send byte u1 to SPI  |  DONE

		; get port


		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

;		push hl    ; u1 

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

;		pop hl   ; u2 - addr

		; TODO Send SPI byte

		ld a, l
		call spi_send_byte

		NEXTW

.SPII:
	CWHEAD .SESEL 62 "SPII" 5 WORD_FLAG_CODE
; | SPII ( -- u1 ) Get a byte from SPI  | DONE

		; TODO Get SPI byte

		call spi_read_byte

		ld h, 0
		ld l, a
		call forth_push_numhl

		NEXTW



.SESEL:
	CWHEAD .CARTDEV 82 "BANK" 4 WORD_FLAG_CODE
; | BANK ( u1 -- ) Select Serial EEPROM Bank Device at bank address u1 1-5 (disables CARTDEV). Set to zero to disable storage. | DONE

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

		ld a, l

		if DEBUG_FORTH_WORDS
			DMARK "BNK"
			CALLMONITOR
		endif

		; active low

		cp 0
		jr z, .bset
		cp 1
		jr nz, .b2
		res 0, c
.b2:		cp 2
		jr nz, .b3
		res 1, c
.b3:		cp 3
		jr nz, .b4
		res 2, c
.b4:		cp 4
		jr nz, .b5
		res 3, c
.b5:		cp 5
		jr nz, .bset
		res 4, c

.bset:
		ld a, c
		ld (spi_device),a
		if DEBUG_FORTH_WORDS
			DMARK "BN2"
			CALLMONITOR
		endif

		NEXTW

.CARTDEV:
	CWHEAD .ENDDEVICE 82 "CARTDEV" 7 WORD_FLAG_CODE
; | CARTDEV ( u1 -- ) Select cart device 1-8 (Disables BANK). Set to zero to disable devices. |  DONE

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
		cp 0
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
		NEXTW
endif

.ENDDEVICE:
; eof

