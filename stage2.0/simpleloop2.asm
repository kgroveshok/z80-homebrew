org 0h
         ; due to circuit memory corruption bug in pic programmer first byte must be NOP
          nop    
          ld hl, 0
          ld (0x20), hl
          nop

loop:     ld hl,(0x20)
          nop
          inc hl
          nop 
          ld (0x20), hl
          nop
          jp loop
