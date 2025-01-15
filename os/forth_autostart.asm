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
;	dw start3
	dw start3b
	dw start3c
        dw ssv5
        dw ssv4
        dw ssv3
        dw ssv2
        dw ssv1
        dw ssv1cpm
;	dw keyup
;	dw keydown
;	dw keyleft
;	dw keyright
;	dw 	keyf1
;	dw keyf2
;	dw keyf3
;	dw keyf4
;	dw keyf5
;	dw keyf6
;	dw keyf7
;	dw keyf8
;	dw keyf9
;	dw keyf10
;	dw keyf11
;	dw keyf12
;	dw keytab
;	dw keycr
;	dw keyhome
;	dw keyend
;	dw keybs
	db 0, 0	

test1:		db ": aa 1 2 3 ;", 0
test2:     	db "111 aa 888 999",0
test3:     	db ": bb 77 ;",0
test4:     	db "$02 $01 do i . loop bb",0
test5:     	db ": hline $13 $00 do i $01 at 1 . i $04 at 1 . loop nop ;",0
test6:     	db ": vline $04 $01 do $00 i at 1 . $13 i at 1 . loop nop ;",0
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
start3:         db ": dirlist dir cls drop dup $00 > if $01 do .> BL .> .> BL .> .> BL .> loop then nop ;",0
start3b:         db ": dla dir cls drop dup $00 > if $01 do $08 i at . $01 i at . $04 i at . loop then nop ;",0
start3c:         db ": dirlist dir cls drop dup $00 > if $01 do \"/\" .> .> \"Ext:\" .> .> \"Id: \" .> .>  loop then nop ;",0

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

; simple screen saver to test code memory reuse to destruction

ssv2:            db ": ssvchr $2a $2d rnd dup $2c = if drop $20 then nop ;",0
ssv3:            db ": ssvposx $01 $27 rnd v0! ;",0
ssv4:            db ": ssvposy $01 $05 rnd v1! ;",0
ssv5:            db ": ssvt ssvposx ssvposy ;",0
ssv1:          db ": ssv cls repeat ssvposx ssvposy v0@ v1@ at ssvchr emit $01 until nop ;",0
ssv1cpm:          db ": ssvcpm cls repeat ssvposx ssvposy v0@ v1@ at ssvchr emit $01 pausems $01 until nop ;",0
;ssv1:          db ": ssv cls repeat ssvt v0@ v1@ at ssvchr emit $01 until nop ;",0
;ssv1:          db ": ssv ssvposx ssvposy at ssvchr ;",0
;ssv1:            db ": ssv repeat ssvpos rnd8 $10 if               $01 until nop ;",0
;ssv2:            db ": ssvchr v0! v1! at? ;",0
;ssv5:            db ": ssvt ssvposx ssvposy v0@ .> v1@ .> ;",0
;ssv2:            db ": ssvchr $2a $2d rnd  ;",0



; minesweeper/star war finding game

game2b:          db ": mb cls $04 $01 do i v2! $10 $01 do i v2@ at rnd8 $30 < if A . then loop loop ;",0

; key board defs

keyup:       db ": keyup $05 ;",0
keydown:       db ": keydown $0a ;",0
keyleft:       db ": keyleft $0b ;",0
keyright:       db ": keyright $0c ;",0
keyf1:       db ": keyf1 $10 ;",0
keyf2:       db ": keyf2 $11 ;",0
keyf3:       db ": keyf3 $12 ;",0
keyf4:       db ": keyf4 $13 ;",0
keyf5:       db ": keyf5 $14 ;",0
keyf6:       db ": keyf6 $15 ;",0
keyf7:       db ": keyf7 $16 ;",0
keyf8:       db ": keyf8 $17 ;",0
keyf9:       db ": keyf9 $18 ;",0
keyf10:       db ": keyf10 $19 ;",0
keyf11:       db ": keyf11 $1a ;",0
keyf12:       db ": keyf12 $1b ;",0

keytab:       db ": keytab $09 ;",0
keycr:       db ": keycr $0d ;",0
keyhome:       db ": keyhome $0e ;",0
keyend:       db ": keyend $0f ;",0
keybs:       db ": keybs $08 ;",0

  



; eof
