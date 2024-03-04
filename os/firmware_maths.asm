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
        rl e \ rl d
        rl c \ rla
        rl e \ rl d
        rl c \ rla
        rl e \ rl d
        rl c \ rla
        ld h,a
        rl e \ rl d
        rl c \ rla
        xor b
        rl e \ rl d
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


This is a very fast, quality pseudo-random number generator. It combines a 16-bit Linear Feedback Shift Register and a 16-bit LCG.

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
seed1_0=$+1
    ld hl,12345
seed1_1=$+1
    ld de,6789
    ld b,h
    ld c,l
    add hl,hl \ rl e \ rl d
    add hl,hl \ rl e \ rl d
    inc l
    add hl,bc
    ld (seed1_0),hl
    ld hl,(seed1_1)
    adc hl,de
    ld (seed1_1),hl
    ex de,hl
seed2_0=$+1
    ld hl,9876
seed2_1=$+1
    ld bc,54321
    add hl,hl \ rl c \ rl b
    ld (seed2_1),bc
    sbc a,a
    and %11000101
    xor l
    ld l,a
    ld (seed2_0),hl
    ex de,hl
    add hl,bc
    ret


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
  ld hl,1       ; seed must not be 0

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

  ld (xrnd+1),hl

  ret




; eof

