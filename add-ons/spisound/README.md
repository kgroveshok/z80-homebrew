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



