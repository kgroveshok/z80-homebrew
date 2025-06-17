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

	; start up words that are actually useful

    dw spi1
    dw spi2
    dw spi3


	dw longread
	dw clrstack
	dw type
	dw stest
	dw strncpy
	dw list
	dw start1
	dw start2
;	dw start3
	dw start3b
	dw start3c

	; (unit) testing words

	dw mtesta
	dw mtestb
	dw mtestc
	dw mtestd
	dw mteste

	; demo/game words

        dw game3w
        dw game3p
        dw game3sc
        dw game3vsi
        dw game3vs
	
	dw game2b
	dw game2bf
	dw game2mba
	dw game2mbas
	dw game2mb

	dw game1
	dw game1a
	dw game1b
	dw game1c
	dw game1d
	dw game1s
	dw game1t
	dw game1f
	dw game1z
	dw game1zz

	dw test5
	dw test6
	dw test7
	dw test8
	dw test9
	dw test10
	
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

; SPI Net support words

; v0! = node to send to
; ( str count - )
spi1:       db ": spitype spicel $00 do dup i + @ v0@ $10 spio spio spio $01 pause loop spiceh ; ; ",0

; spiputchr ( char node - )
spi2:       db ": spiputchr spicel $10 spio spio ptr @ spio spiceh ; ",0
spi3:       db ": storestr spicel $03 spio spio ptr count clkstro spiceh ; ", 0

; spigetchr ( - n )
spi4:       db ": spigetchr spicel $11 spio spii spiceh ; ", 0

; getnode ( - n )
spi5:       db ": getnode spicel $18 spio spii nop spiceh ; ", 0


; store string ( str i - )

spi6:       db ": storestr spicel $12 spio spio count $00 do dup i + @ spio loop spiceh ; ", 0

; get string ( i - str )

spi7:       db ": getstorestr spicel $13 spio spio \"\" repeat spii dup concat $00 = not until spiceh ; ", 0

; Long read of currently open file
longread:   db ": lread read repeat readcont if read concat then readcont until nop ; ", 0

; clear stack 

clrstack:  db ": clrstk depth ?dup if $01 do drop loop then nop ;", 0

; type ( addr count - )
type:     db ": type $00 do dup i + @ emit loop ;", 0

; some direct memory words
; strncpy ( len t f -- t )

strncpy:   db ": strncpy $00 scratch 2! $02 scratch 2! do $00 scratch 2@ i + @ $02 scratch 2@ i + ! loop nop  ;",0

start1:     	db ": bpon $0000 bp ;",0
start2:     	db ": bpoff $0001 bp ;",0
start3b:         db ": dla dir cls drop dup $00 > if $01 do $08 $04 at . $01 $04 at . $04 $04 at . $23 $04 at accept drop scroll loop then nop ;",0
start3c:         db ": dirlist dir cls drop dup $00 > if $01 do \"/\" .> .> \"Ext:\" .> .> \"Id: \" .> .>  loop then nop ;",0


; a handy word to list items on the stack

list:            db ": more cls repeat scroll $01 $04 at depth . $0a $04 at .> $01 $01 at accept drop depth 0= not until nop ;",0


; test stack 
; rnd8 stest

stest:   db ": stest cls  v0! v0@ $00 do rnd8 $01 $01 at i . $01 pause loop v0@ $00 do drop $12 $01 at depth . $01 pause loop nop ;",0 

; random malloc and free cycles

mtesta:      db ": mtesta $01 v0! repeat heap cls $01 $01 at v0@ . v0@ $01 + v0! $08 $01 at . $08 $02 at . rnd8 dup $13 $01 at . malloc heap $1f $01 at . $1f $02 at . $01 pause free $01 until nop ;", 0

; fixed malloc and free cycles

mtestb:      db ": mtestb $01 v0! repeat heap cls $01 $01 at v0@ . v0@ $01 + v0! $08 $01 at . $08 $02 at . $80 malloc heap $1f $01 at . $1f $02 at . $01 pause free $01 until nop ;", 0

; fixed double string push and drop cycle 

mtestc:      db ": mtestc $01 v0! repeat heap cls $01 $01 at v0@ . v0@ $01 + v0! $08 $01 at . $08 $02 at . $80 spaces $2f spaces  heap $1f $01 at . $1f $02 at . $01 pause drop drop $01 until nop ; ", 0

; consistent fixed string push and drop cycle 

mtestd:      db ": mtestd $01 v0! repeat heap cls $01 $01 at v0@ . v0@ $01 + v0! $08 $01 at . $08 $02 at . $80 spaces heap $1f $01 at . $1f $02 at . $01 pause drop $01 until nop ; ", 0

mteste:      db ": mteste $01 v0! repeat heap cls $01 $01 at v0@ . v0@ $01 + v0! $08 $01 at . $08 $02 at . rnd8 dup spaces $0f $02 at . heap $1f $01 at . $1f $02 at . $01 pause drop $01 until nop ; ", 0

;test1:		db ": aa 1 2 3 ;", 0
;test2:     	db "111 aa 888 999",0
;test3:     	db ": bb 77 ;",0
;test4:     	db "$02 $01 do i . loop bb",0

test5:     	db ": hline $13 $00 do i $01 at 1 . i $04 at 1 . loop nop ;",0
test6:     	db ": vline $04 $01 do $00 i at 1 . $13 i at 1 . loop nop ;",0
test7:     	db ": box hline vline ;",0
test8:     	db ": world cls box $03 $03 at Hello-World! . ;",0
test9:     	db ": sw $01 adsp world ;",0
test10:     	db ": fw $00 adsp world draw $05 pause ;",0
test11:     	db "hello create .",0
test12:     	db "hello2 create .",0

;mmtest1:     	db "cls $0001 $0008 MIN . $0002 pause",0
;mmtest2:     	db "cls $0101 $0008 MIN . $0002 pause",0
;mmtest3:     	db "cls $0001 $0008 MAX . $0002 pause",0
;mmtest4:     	db "cls $0101 $0008 MAX . $0002 pause",0
;mmtest5:     	db "cls $0001 $0001 MIN . $0002 pause",0
;mmtest6:     	db "cls $0001 $0001 MAX . $0002 pause",0

;iftest1:     	db "$0001 IF cls .",0
;iftest2:     	db "$0000 IF cls .",0
;iftest3:     	db "$0002 $0003 - IF cls .",0
;looptest1:     	db "$0003 $0001 do i . loop 8",0
;looptest2:     	db "$0003 $0001 do i . $0001 pause loop 8",0

;ifthtest1:     	db "$0001 IF is-true . $0005 pause THEN next-word . $0005 pause",0
;ifthtest2:     	db "$0000 IF is-true . $0005 pause THEN next-word . $0005 pause",0
;ifthtest3:     	db "$0002 $0003 - IF is-true . $0005 pause THEN next-word . $0005 pause",0



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

; Using 'ga' save a high score across multiple runs using external storage

game1zz:         db ": gas ga $01 bank $80 bread $01 $04 at Prev-Score .> storepage ptr $02 + dup 2@ . v3@ swap 2! $80 bupd ;",0


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



; minesweeper/battleship finding game
; draws a game board of random ship/mine positions
; user enters coords to see if it hits on
; game ends when all are hit
; when hit or miss says how many may be in the area

; setup the game board and then hide it
game2b:          db ": mbsetup $02 fb cls $04 $01 do i v2! $10 $01 do i v2@ at rnd8 $30 < if A . then loop loop $05 pause $01 fb ;",0
game2bf:         db ": mbsetupf cls $04 $01 do i v2! $10 $01 do i v2@ at \"+\" . loop loop nop ;",0
; prompt for where to target
game2mba:        db ": mbp $12 $04 at Turns .> v3@ . $12 $03 at Score .> v0@ . $12 $01 at Enter-X-__ .- $1a $01 at accept $12 $02 at Enter-Y-__ .- $1a $02 at accept nop ;", 0 
game2mbas:        db ": mbsv str2num v2! str2num v1! nop ;", 0 
; TODO see if the entered coords hits or misses pushes char hit of miss
game2mbht:      db ": mbckht nop ;",0
game2mbms:      db ": mbcms nop ;",0
; TODO how many might be near by
game2mb:          db ": mb $00 v0! $00 v3! mbsetup mbsetupf repeat mbp mbsv $02 fb mbckht mbcms v1@ v2@ at@ $01 fb v1@ v2@ at emit $01 until nop ;",0

; Game 3

; Vert scroller ski game - avoid the trees!

; v0 score (ie turns)
; v1 player pos
; v2 left wall
; v3 right wall

; Draw side walls randomly

game3w:   db ": vsw v2@ $04 at \"|\" . v3@ $04 at \"|\" . nop ;", 0

; Draw player
game3p:   db ": vsp v1@ $01 at \"V\" . nop ; ", 0

; TODO Get Key

; TODO Move left right

; scroll and move walls a bit

game3sc:  db ": vsscl v2@ $01 + v2! v3@ $01 - v3! scroll nop ;", 0

; main game loop

game3vsi:    db ": vsi $00 v0! $01 v2! $12 v3! $06 v1! nop ;",0
game3vs:    db ": vs vsi repeat vsw vsp vsscl $05 pause scroll $01 until nop ;",0

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
