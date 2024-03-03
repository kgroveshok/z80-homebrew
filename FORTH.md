FORTH OS
--------

I love Forth. Used it off and on over the years as it is the easiet programming language to design.

I now have one in this bit of kit. I was inspired by the Jupiter Ace and with screen limitiations
a version of BASCI would be too tedious and painful to use. Forth is best option. With it tied to
the hardware I've (or will) added built-in keywords to take advantage of the hardware.

At the moment it is interpreted but there is the posisblity I can add compiled words as each 
keyword has a byte OP code. 

Support at this stage is limited as I've only just got the stack working here is what works:

DUMP
CDUMP


The DUMP monitor command was one of the first things I added to this machine to aid testing
so makes sense to add it for the language development but Forth style. i.e. params

In the monitor you would have used: d 8000

That would have dumped a screen full of bytes starting at 8000 hex. 

In this version of Forth you can use: $8000 DUMP

To continue without loading another address use (the monitor command allowd no param for this too): CDUMP


With stack working have proved: $8000 $1111 DUMP DUMP 



Stack Values
============

$xxxx  - 16bit Hex value
$xx    -  8bit Hex Value
"xxx"  - String pointer    (TODO)


Words
=====


While still a lot of dev going on see os/forth_words.asm there is also a shell script that lists the words from the source and shows which ones
are working and what are left to do






 


