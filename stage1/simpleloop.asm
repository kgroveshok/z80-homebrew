org 0h
loop:     ld hl,(0x3f3)
          inc hl
          ld (0x5f3), hl
          jp loop
