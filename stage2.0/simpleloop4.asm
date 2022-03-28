org 0h
         ; due to circuit memory corruption bug in pic programmer first byte must be NOP
          nop    
          ld a,0
          ld (0x20), a
          nop

loop:     ld a,(0x20)
          nop
          inc a
          nop 
          ld (0x20), a
          nop
          jp loop
