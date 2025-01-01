; list of commands to perform at system start up

startcmds:
;	dw test11
;	dw test12
;	dw test13
;	dw test14
;	dw test15
;	dw test16
;	dw test17
;	dw ifthtest1
;	dw ifthtest2
;	dw ifthtest3
;	dw mmtest1
;	dw mmtest2
;	dw mmtest3
;	dw mmtest4
;	dw mmtest5
;	dw mmtest6
;	dw iftest1
;	dw iftest2
;	dw iftest3
;	dw looptest1
;	dw looptest2
;	dw test1
;	dw test2
;	dw test3
;	dw test4
;	dw game2r
;	dw game2b1
;	dw game2b2
	dw game2b

	dw game1
	dw game1a
	dw game1b
	dw game1c
	dw game1d
	dw game1s
	dw game1t
	dw game1f
	dw game1z

	dw test5
	dw test6
	dw test7
	dw test8
	dw test9
	dw test10
	
	dw start1
	dw start2
	dw start3
	db 0, 0	

test1:		db ": aa 1 2 3 ;", 0
test2:     	db "111 aa 888 999",0
test3:     	db ": bb 77 ;",0
test4:     	db "$02 $01 do i . loop bb",0
test5:     	db ": hline $13 $00 do i $01 at 1 . i $04 at 1 . loop ;",0
test6:     	db ": vline $04 $01 do $00 i at 1 . $13 i at 1 . loop ;",0
test7:     	db ": box hline vline ;",0
test8:     	db ": world cls box $03 $03 at Hello-World! . ;",0
test9:     	db ": sw $01 adsp world ;",0
test10:     	db ": fw $00 adsp world draw $05 pause ;",0
test11:     	db "hello create .",0
test12:     	db "hello2 create .",0

mmtest1:     	db "cls $0001 $0008 MIN . $0002 pause",0
mmtest2:     	db "cls $0101 $0008 MIN . $0002 pause",0
mmtest3:     	db "cls $0001 $0008 MAX . $0002 pause",0
mmtest4:     	db "cls $0101 $0008 MAX . $0002 pause",0
mmtest5:     	db "cls $0001 $0001 MIN . $0002 pause",0
mmtest6:     	db "cls $0001 $0001 MAX . $0002 pause",0

iftest1:     	db "$0001 IF cls .",0
iftest2:     	db "$0000 IF cls .",0
iftest3:     	db "$0002 $0003 - IF cls .",0
looptest1:     	db "$0003 $0001 do i . loop 8",0
looptest2:     	db "$0003 $0001 do i . $0001 pause loop 8",0

ifthtest1:     	db "$0001 IF is-true . $0005 pause THEN next-word . $0005 pause",0
ifthtest2:     	db "$0000 IF is-true . $0005 pause THEN next-word . $0005 pause",0
ifthtest3:     	db "$0002 $0003 - IF is-true . $0005 pause THEN next-word . $0005 pause",0

start1:     	db ": bpon $0000 bp ;",0
start2:     	db ": bpoff $0001 bp ;",0
;start3:         db ": dirlist dir cls drop dup $00 > if $01 do .> BL .> .> BL .> .> loop then nop ;  ",0, 0, 0, FORTH_END_BUFFER
start3:         db ": dirlist dir cls drop dup $00 > if $01 do $08 i at . $01 i at . $04 i at . loop then nop ;",0

; a small guess the number game

game1:          db ": gsn rnd8 v1! ;",0
game1a:          db ": gs $00 $00 at Enter-a-number .- $00 $02 at between-1-and-255 .- $00 $03 at accept str2num v2! ;",0

game1b:          db ": gcb v2@ v1@ < if $00 $00 at Too-low! .- $01 then ;",0
game1c:          db ": gcc v2@ v1@ > if $00 $00 at Too-high! .- $01 then ;",0
game1d:          db ": gcd v2@ v1@ = if $00 $00 at Yes! .- $00 then ;",0
game1s:          db ": gck gcb gcc gcd ;",0
game1t:          db ": sc v3@ $01 + v3! ;",0
game1f:          db ": fsc v3@ cls $01 $01 at You-Took .- $02 $03 at . ;",0
game1z:         db ": ga $00 v3! gsn repeat cls gs cls gck $02 pause sc until fsc nop ;",0


;game2r:          db ": m2r rnd8 v1! ;  ",0, 0, 0, FORTH_END_BUFFER
;game2b1:          db ": m2b1 $1f $00 do i v2@ at rnd8 $30 < if A . then loop nop ;  ",0, 0, 0, FORTH_END_BUFFER
;game2b2:          db ": m2b cls $04 $01 do i v2! m2b1 loop ;  ",0, 0, 0, FORTH_END_BUFFER

; minesweeper/star war finding game

game2b:          db ": mb cls $04 $01 do i v2! $10 $01 do i v2@ at rnd8 $30 < if A . then loop loop ;",0


; eof
