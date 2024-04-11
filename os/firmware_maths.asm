; random number generators


; https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Random


;-----> Generate a random number
; output a=answer 0<=a<=255
; all registers are preserved except: af
random:
        push    hl
        push    de
        ld      hl,(randData)
        ld      a,r
        ld      d,a
        ld      e,(hl)
        add     hl,de
        add     a,l
        xor     h
        ld      (randData),hl
        pop     de
        pop     hl
        ret


; randData here must be a 2 byte seed located in ram. While this is a fast generator, it's generally not considered very good in terms of randomness.



;------LFSR------
;James Montelongo
;optimized by Spencer Putt
;out:
; a = 8 bit random number
RandLFSR:
        ld hl,LFSRSeed+4
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld a,(hl)
        ld b,a
        rl e 
	rl d
        rl c 
	rla
        rl e 
	rl d
        rl c 
	rla
        rl e 
	rl d
        rl c 
	rla
        ld h,a
        rl e 
	rl d
        rl c 
	rla
        xor b
        rl e 
	rl d
        xor h
        xor c
        xor d
        ld hl,LFSRSeed+6
        ld de,LFSRSeed+7
        ld bc,7
        lddr
        ld (de),a
        ret

;While this may produces better numbers, it is slower, larger and requires a bigger seed than ionrandom. Assuming theres is a good seed to start, it should generate ~2^56 bytes before repeating. However if there is not a good seed(0 for example), then the numbers created will not be adequate. Unlike Ionrandom and its use of the r register, starting with the same seed the same numbers will be generated. With Ionrandom the code running may have an impact on the number generated. This means this method requires more initialization.

;You can initialize with TI-OS's seeds, stored at seed1 and seed2, both are ti-floats but will serve the purpose. 


;This is a very fast, quality pseudo-random number generator. It combines a 16-bit Linear Feedback Shift Register and a 16-bit LCG.

prng16:
;Inputs:
;   (seed1) contains a 16-bit seed value
;   (seed2) contains a NON-ZERO 16-bit seed value
;Outputs:
;   HL is the result
;   BC is the result of the LCG, so not that great of quality
;   DE is preserved
;Destroys:
;   AF
;cycle: 4,294,901,760 (almost 4.3 billion)
;160cc
;26 bytes
    ld hl,(seed1)
    ld b,h
    ld c,l
    add hl,hl
    add hl,hl
    inc l
    add hl,bc
    ld (seed1),hl
    ld hl,(seed2)
    add hl,hl
    sbc a,a
    and %00101101
    xor l
    ld l,a
    ld (seed2),hl
    add hl,bc
    ret

;On their own, LCGs and LFSRs don't produce great results and are generally very cyclical, but they are very fast to compute. The 16-bit LCG in the above example will bounce around and reach each number from 0 to 65535, but the lower bits are far more predictable than the upper bits. The LFSR mixes up the predictability of a given bit's state, but it hits every number except 0, meaning there is a slightly higher chance of any given bit in the result being a 1 instead of a 0. It turns out that by adding together the outputs of these two generators, we can lose the predictability of a bit's state, while ensuring it has a 50% chance of being 0 or 1. As well, since the periods, 65536 and 65535 are coprime, then the overall period of the generator is 65535*65536, which is over 4 billion. 

rand32:
;Inputs:
;   (seed1_0) holds the lower 16 bits of the first seed
;   (seed1_1) holds the upper 16 bits of the first seed
;   (seed2_0) holds the lower 16 bits of the second seed
;   (seed2_1) holds the upper 16 bits of the second seed
;   **NOTE: seed2 must be non-zero
;Outputs:
;   HL is the result
;   BC,DE can be used as lower quality values, but are not independent of HL.
;Destroys:
;   AF
;Tested and passes all CAcert tests
;Uses a very simple 32-bit LCG and 32-bit LFSR
;it has a period of 18,446,744,069,414,584,320
;roughly 18.4 quintillion.
;LFSR taps: 0,2,6,7  = 11000101
;291cc
;seed1_0=$+1
;    ld hl,12345
;seed1_1=$+1
;    ld de,6789
;    ld b,h
;    ld c,l
;    add hl,hl \ rl e \ rl d
;    add hl,hl \ rl e \ rl d
;    inc l
;    add hl,bc
;    ld (seed1_0),hl
;    ld hl,(seed1_1)
;    adc hl,de
;    ld (seed1_1),hl
;    ex de,hl
;seed2_0=$+1
;    ld hl,9876
;seed2_1=$+1
;    ld bc,54321
;    add hl,hl \ rl c \ rl b
;    ld (seed2_1),bc
;    sbc a,a
;    and %11000101
;    xor l
;    ld l,a
;    ld (seed2_0),hl
;    ex de,hl
;    add hl,bc
;    ret
;

; 16-bit xorshift pseudorandom number generator by John Metcalf
; 20 bytes, 86 cycles (excluding ret)

; returns   hl = pseudorandom number
; corrupts   a

; generates 16-bit pseudorandom numbers with a period of 65535
; using the xorshift method:

; hl ^= hl << 7
; hl ^= hl >> 9
; hl ^= hl << 8

; some alternative shift triplets which also perform well are:
; 6, 7, 13; 7, 9, 13; 9, 7, 13.

;  org 32768

xrnd:
  ld hl,(xrandc)       ; seed must not be 0
  ld a,0
  cp l
  jr nz, .xrnd1
  ld l, 1
.xrnd1:

  ld a,h
  rra
  ld a,l
  rra
  xor h
  ld h,a
  ld a,l
  rra
  ld a,h
  rra
  xor l
  ld l,a
  xor h
  ld h,a

  ld (xrandc),hl

  ret
; 


;;;; int maths

; https://map.grauw.nl/articles/mult_div_shifts.php
; Divide 16-bit values (with 16-bit result)
; In: Divide BC by divider DE
; Out: BC = result, HL = rest
;
Div16:
    ld hl,0
    ld a,b
    ld b,8
Div16_Loop1:
    rla
    adc hl,hl
    sbc hl,de
    jr nc,Div16_NoAdd1
    add hl,de
Div16_NoAdd1:
    djnz Div16_Loop1
    rla
    cpl
    ld b,a
    ld a,c
    ld c,b
    ld b,8
Div16_Loop2:
    rla
    adc hl,hl
    sbc hl,de
    jr nc,Div16_NoAdd2
    add hl,de
Div16_NoAdd2:
    djnz Div16_Loop2
    rla
    cpl
    ld b,c
    ld c,a
ret


;http://z80-heaven.wikidot.com/math
;
;Inputs:
;     DE and A are factors
;Outputs:
;     A is not changed
;     B is 0
;     C is not changed
;     DE is not changed
;     HL is the product
;Time:
;     342+6x
;
Mult16:

     ld b,8          ;7           7
     ld hl,0         ;10         10
       add hl,hl     ;11*8       88
       rlca          ;4*8        32
       jr nc,$+3     ;(12|18)*8  96+6x
         add hl,de   ;--         --
       djnz $-5      ;13*7+8     99
ret

;
; Square root of 16-bit value
; In:  HL = value
; Out:  D = result (rounded down)
;
;Sqr16:
;    ld de,#0040
;    ld a,l
;    ld l,h
;    ld h,d
;    or a
;    ld b,8
;Sqr16_Loop:
;    sbc hl,de
;    jr nc,Sqr16_Skip
;    add hl,de
;Sqr16_Skip:
;    ccf
;    rl d
;    add a,a
;    adc hl,hl
;    add a,a
;    adc hl,hl
;    djnz Sqr16_Loop
;    ret
;
;
; Divide 8-bit values
; In: Divide E by divider C
; Out: A = result, B = rest
;
Div8:
    xor a
    ld b,8
Div8_Loop:
    rl e
    rla
    sub c
    jr nc,Div8_NoAdd
    add a,c
Div8_NoAdd:
    djnz Div8_Loop
    ld b,a
    ld a,e
    rla
    cpl
    ret

;
; Multiply 8-bit value with a 16-bit value (unrolled)
; In: Multiply A with DE
; Out: HL = result
;
Mult12U:
    ld l,0
    add a,a
    jr nc,Mult12U_NoAdd0
    add hl,de
Mult12U_NoAdd0:
    add hl,hl
    add a,a
    jr nc,Mult12U_NoAdd1
    add hl,de
Mult12U_NoAdd1:
    add hl,hl
    add a,a
    jr nc,Mult12U_NoAdd2
    add hl,de
Mult12U_NoAdd2:
    add hl,hl
    add a,a
    jr nc,Mult12U_NoAdd3
    add hl,de
Mult12U_NoAdd3:
    add hl,hl
    add a,a
    jr nc,Mult12U_NoAdd4
    add hl,de
Mult12U_NoAdd4:
    add hl,hl
    add a,a
    jr nc,Mult12U_NoAdd5
    add hl,de
Mult12U_NoAdd5:
    add hl,hl
    add a,a
    jr nc,Mult12U_NoAdd6
    add hl,de
Mult12U_NoAdd6:
    add hl,hl
    add a,a
    ret nc
    add hl,de
    ret

;
; Multiply 8-bit value with a 16-bit value (right rotating)
; In: Multiply A with DE
;      Put lowest value in A for most efficient calculation
; Out: HL = result
;
Mult12R:
    ld hl,0
Mult12R_Loop:
    srl a
    jr nc,Mult12R_NoAdd
    add hl,de
Mult12R_NoAdd:
    sla e
    rl d
    or a
    jp nz,Mult12R_Loop
    ret

;
; Multiply 16-bit values (with 32-bit result)
; In: Multiply BC with DE
; Out: BCHL = result
;
Mult32:
    ld a,c
    ld c,b
    ld hl,0
    ld b,16
Mult32_Loop:
    add hl,hl
    rla
    rl c
    jr nc,Mult32_NoAdd
    add hl,de
    adc a,0
    jp nc,Mult32_NoAdd
    inc c
Mult32_NoAdd:
    djnz Mult32_Loop
    ld b,c
    ld c,a
    ret



;
; Multiply 8-bit values
; In:  Multiply H with E
; Out: HL = result
;
Mult8:
    ld d,0
    ld l,d
    ld b,8
Mult8_Loop:
    add hl,hl
    jr nc,Mult8_NoAdd
    add hl,de
Mult8_NoAdd:
    djnz Mult8_Loop
    ret








;;http://z80-heaven.wikidot.com/math
;;This divides DE by BC, storing the result in DE, remainder in HL
;
;DE_Div_BC:          ;1281-2x, x is at most 16
;     ld a,16        ;7
;     ld hl,0        ;10
;     jp $+5         ;10
;.DivLoop:
;       add hl,bc    ;--
;       dec a        ;64
;       jr z,.DivLoopEnd        ;86
;
;       sla e        ;128
;       rl d         ;128
;       adc hl,hl    ;240
;       sbc hl,bc    ;240
;       jr nc,.DivLoop ;23|21
;       inc e        ;--
;       jp .DivLoop+1
;
;.DivLoopEnd:

;HL_Div_C:
;Inputs:
;     HL is the numerator
;     C is the denominator
;Outputs:
;     A is the remainder
;     B is 0
;     C is not changed
;     DE is not changed
;     HL is the quotient
;
;       ld b,16
;       xor a
;         add hl,hl
;         rla
;         cp c
;         jr c,$+4
;           inc l
;           sub c
;         djnz $-7


if ENABLE_FLOATMATH
include "float/bbcmath.z80"
endif


; eof

