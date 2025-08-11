
; DEBUG Level 2 - All useful debug on and memory courruption guards

; Odd specific debug points for testing hardware dev

;DEBUG_LEVEL0: equ 0
;DEBUG_LEVEL0: equ 0
;DEBUG_LEVEL2: equ 1
DEBUG_LEVEL: equ '2'

DEBUG_SOUND: equ 0     
DEBUG_STK_FAULT: equ 0
DEBUG_INPUT: equ 0     ; Debug input entry code
DEBUG_INPUTV2: equ 0     ; Debug input entry code
DEBUG_KEYCINWAIT: equ 0
DEBUG_KEYCIN: equ 0
DEBUG_KEY: equ 0
DEBUG_KEY_MATRIX: equ 0
DEBUG_STORECF: equ 0
DEBUG_STORESE: equ 1        ; TODO  w locks up, r returns. 
DEBUG_SPI_HARD_CE0: equ 0    ; only handshake on CE0 on port A
DEBUG_SPI: equ 0    ; low level spi tests

; Enable many break points

DEBUG_FORTH_PARSE_EXEC: equ 0     ; 6
DEBUG_FORTH_PARSE_EXEC_SLOW: equ 0     ; 6
DEBUG_FORTH_PARSE_NEXTWORD: equ 0
DEBUG_FORTH_JP: equ 0    ; 4
DEBUG_FORTH_MALLOC: equ 0
DEBUG_FORTH_MALLOC_INT: equ 0
DEBUG_FORTH_DOT: equ 1
DEBUG_FORTH_DOT_WAIT: equ 0
DEBUG_FORTH_MATHS: equ 0
DEBUG_FORTH_TOK: equ 0    ; 4
DEBUG_FORTH_PARSE: equ 0    ; 3
DEBUG_FORTH: equ 0  ;2
DEBUG_FORTH_WORDS: equ 1   ; 1
DEBUG_FORTH_PUSH: equ 1   ; 1
DEBUG_FORTH_UWORD: equ 1   ; 1

; Enable key point breakpoints

DEBUG_FORTH_DOT_KEY: equ 0
DEBUG_FORTH_PARSE_KEY: equ 0   ; 5
DEBUG_FORTH_WORDS_KEY: equ 1   ; 1

; Debug stack imbalances

ON: equ 1
OFF: equ 0

DEBUG_STACK_IMB: equ 0
STACK_IMB_STORE: equ 20

; House keeping and protections

DEBUG_FORTH_STACK_GUARD: equ 1    ; under/over flows
DEBUG_FORTH_MALLOC_GUARD: equ 1
DEBUG_FORTH_MALLOC_HIGH: equ 0     ; warn only if more than 255 chars being allocated. would be highly unusual!
FORTH_ENABLE_FREE: equ 0
FORTH_ENABLE_MALLOCFREE: equ 1
FORTH_ENABLE_DSPPOPFREE: equ 1    ; TODO BUG Seems to be OK in some situations but with SW it crashes straight away
FORTH_ENABLE_FLOATMATH: equ 0
; eof
