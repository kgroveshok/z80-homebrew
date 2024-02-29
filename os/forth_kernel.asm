;
; kernel to the forth OS

; parse cli


parsenext:


;PLUS:	db 1
;	db 1
;	ds "+",0
;	dw NEG
;		NEXT


; 1. hold ptr of the line being parsed
; 2. scan word until space is found
; 3. scan dict
;       get start of dict
;       compare token to string
;       if char does not match drop out and get pointer to next word
;       if chars match to zero term then flag as found word
;           do a jump to the code block for word 




