org 0h
          jp loop
counter:
          nop
          nop
loop:     ld a,(counter)
          inc a
          ld (counter), a
          jp loop
