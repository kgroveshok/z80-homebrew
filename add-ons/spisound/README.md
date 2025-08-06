SPISound
--------


SPISound - A SPI controled sound card using a SN76389AN chip

Example code:

( byte -- )
: note spicel spio spiceh spicel ;

( bytes ... bytesn n -- )

: play $01 do note $20 mspause nop loop nop ;
: slient $9f note $bf note $df note $ff note ;
: sound $01 cartdev $00 spitime ! ;
: cha $00 ;
: chb $20 ;
: chc $40 ;
: chd $60 ;

( note/vol ch -- )

: cnote $80 + + note ;
: cvol $90 + + note ;


Set the beat time

: btime "b" var ;

( note ch -- )
: beat dup "c" var ! $00 c var @ cvol cnote b var @ mspause $0f c var @ cvol ;



( str cha -- )
: song v1! count $01 do i $01 subtr asc $61 - v2@ beat loop ;


e.g. 

	$00 cha cvol
	$00 cha cnote





: songb v1! ptr scratch 2! repeat scatch 2@ @ asc $61 - v1@ beat scratch +2! scratch 2@ @ $00 = until ; 

: cp v0! open $01 do i record cls . waitk $79 = if v1@ append then loop ;


* Multichannel testing...

: ican $00 scratch ;    chan 1 note pointer w
: icad $02 scratch ;    chan 1 note duration b
: icbn $03 scratch ;     chan 2 note pointer  w 
: icbd $05 scratch ;    chan 2 note duration  b
; indur $06 scratch ;    one beat duration in ms
: iagi ican 2@ @ ican 1+2! ;
: ibgi icbn 2@ @ icbn 1+2! ;
: ichan iagi $8f note anote $90 note iagi $30 - icad ! ;
: ichbn ibgi $8f note anote $90 note ibgi $30 - icbd ! ;
: setchana ptr ican 2! $01 icad ! $ff indur ! ;
: setchanb ptr icbn 2! $01 icbd ! $ff indur ! ;
: ichap icad 1-! icad @ 0= if ichan then ;
: ichbp icbd 1-! icbd @ 0= if ichbn then ;
: iplaya repeat ichap indur @ pausems ican 2@ @ 0= not until ;
: iplayab repeat ichap ichbp indur @ pausems ican 2@ @ 0= not until ;


"h2i2k2h2! setchana
"o4p4!" setchanb    iplayab
