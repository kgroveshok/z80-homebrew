
.SIN:
	CWHEAD .SOUT 31 "IN" 2 WORD_FLAG_CODE
;	db 31
;	dw .SOUT
;	db 3
;	db "IN",0       
; |IN ( u1-- u )    Perform z80 IN with u1 being the port number. Push result to TOS | TO TEST
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
;   db 32
;	dw .CLS
;	db 4
;	db "OUT",0      
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
;   db 61
;	dw .SPII
;	db 5
;	db "SPIO",0      
;| SPIO ( u1 u2 -- ) Send byte u1 to SPI device u2 |  WIP

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
;   db 62
;	dw .SCROLL
;	db 5
;	db "SPII",0      
;| SPII ( u1 -- ) Get a byte from SPI device u2 |  WIP

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
	CWHEAD .ENDDEVICE 82 "BANK" 4 WORD_FLAG_CODE
;   db 62
;	dw .SCROLL
;	db 5
;	db "SPII",0      
;| BANK ( u1 -- ) Select Serial EEPROM Bank Device at bank address u1 |  TODO

		; get bank

		FORTH_DSP_VALUEHL     			; TODO skip type check and assume number.... lol

		push hl

		; destroy value TOS

		FORTH_DSP_POP  ; TODO add stock underflow checks and throws 

		; one value on hl get other one back

		pop hl


		; TODO Get SPI byte

;		call se_readbyte


		NEXTW


.ENDDEVICE:
; eof

