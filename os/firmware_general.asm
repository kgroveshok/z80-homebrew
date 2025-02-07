
; word look up

; in
; a is the index
; hl is pointer start of array
;
; returns
; hl to the word
;

table_lookup: 
		push de
		ex de, hl

		ld l, a
		ld h, 0
		add hl, hl
		add hl, de
		ld a, (hl)
		inc hl
		ld h,(hl)
		ld l, a

		pop de
		ret

; Delay loops



aDelayInMS:
	push bc
	ld b,a
msdelay:
	push bc
	

	ld bc,041h
	call delayloop
	pop bc
	dec b
	jr nz,msdelay

;if CPU_CLOCK_8MHZ
;msdelay8:
;	push bc
;	
;
;	ld bc,041h
;	call delayloop
;	pop bc
;	dec b
;	jr nz,msdelay8
;endif


	pop bc
	ret


delay250ms:
	;push de
	ld bc, 04000h
	jp delayloop
delay500ms:
	;push de
	ld bc, 08000h
	jp delayloop
delay1s:
	;push bc
   ; Clobbers A, d and e
    ld      bc,0      ; # 0ffffh = approx 1s
delayloop:
    push bc

if BASE_CPM
	ld bc, CPM_DELAY_TUNE
.cpmloop:
	push bc

endif



delayloopi:
;	push bc
;.dl:
    bit     0,a    	; 8
    bit     0,a    	; 8
    bit     0,a    	; 8
    and     255  	; 7
    dec     bc      	; 6
    ld      a,c     	; 4
    or      b     	; 4
    jp      nz,delayloopi   	; 10, total = 55 states/iteration
    ; 65536 iterations * 55 states = 3604480 states = 2.00248 seconds
	;pop de
;pop bc

if BASE_CPM
	pop bc
	
    dec     bc      	; 6
    ld      a,c     	; 4
    or      b     	; 4
    jp      nz,.cpmloop   	; 10, total = 55 states/iteration
	

endif
;if CPU_CLOCK_8MHZ
;    pop bc
;    push bc
;.dl8:
;    bit     0,a    	; 8
;    bit     0,a    	; 8
;    bit     0,a    	; 8
;    and     255  	; 7
;    dec     bc      	; 6
;    ld      a,c     	; 4
;    or      b     	; 4
;    jp      nz,.dl8   	; 10, total = 55 states/iteration
;endif

;if CPU_CLOCK_10MHZ
;    pop bc
;    push bc
;.dl8:
;    bit     0,a    	; 8
;    bit     0,a    	; 8
;    bit     0,a    	; 8
;    and     255  	; 7
;    dec     bc      	; 6
;    ld      a,c     	; 4
;    or      b     	; 4
;    jp      nz,.dl8   	; 10, total = 55 states/iteration
;endif
    pop bc

	ret



; eof
