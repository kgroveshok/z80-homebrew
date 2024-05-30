; Device related words

if SOUND_ENABLE
.NOTE:
	CWHEAD .SIN 31 "NOTE" 4 WORD_FLAG_CODE
; | NOTE ( ud uf --  )  Plays a note of frequency uf for the duration of ud millseconds |

	

		NEXTW
endif
.SIN:
	CWHEAD .SOUT 31 "IN" 2 WORD_FLAG_CODE
; | IN ( u1-- u )    Perform z80 IN with u1 being the port number. Push result to TOS | TO TEST
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
;| OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | TO TEST

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl

		pop bc

		out (c), l

		NEXTW


.SPIO:
	CWHEAD .SPII 61 "SPIO" 4 WORD_FLAG_CODE
; | SPIO ( u1 u2 -- ) Send byte u1 to SPI device u2 |  WIP

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u2 - byte

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; get byte to send

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl    ; u1 - addr

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop de   ; u1 - byte

		pop hl   ; u2 - addr

		; TODO Send SPI byte


		ld a, e
		call se_writebyte

		

		NEXTW

.SPII:
	CWHEAD .SESEL 62 "SPII" 5 WORD_FLAG_CODE
; | SPII ( u1 -- ) Get a byte from SPI device u2 | WIP

		; get port

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl


		; TODO Get SPI byte

		call se_readbyte

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

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl


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

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl

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


.ENDDEVICE:
; eof

