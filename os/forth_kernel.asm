;
; kernel to the forth OS

; parse cli

; to move to ram

cli_buffer: db 20
cli_token: db 20
cli_ptr: dw 0

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


; get start of dict
;
; word comp
;    get compiled byte and save it (need to decide if code is compiled or not for comparison)
;    if byte is 0 then end parsing and report failed lookup (or could be something to add to stack etc)
;    move to start of word 
;    compare word to cli_token
;    if not same
;	scan for zero term
;	get ptr for next word
;	goto word comp
;    if same
;       scan for zero term
;       skip ptr for next word
;       exec code block




; move cli_ptr to start of next word in cli_buffer 


strtok: 
	
	ret


; eof
