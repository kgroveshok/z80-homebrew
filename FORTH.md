FORTH OS
--------

I love Forth. Used it off and on over the years as it is the easiet programming language to design.

I now have one in this bit of kit. I was inspired by the Jupiter Ace and with screen limitiations
a version of BASIC would be too tedious and painful to use. Forth is best option. With it tied to
the hardware I've (or will) added built-in keywords to take advantage of the hardware.

At the moment it is interpreted but there is the posisblity I can add compiled words as each 
keyword has a byte OP code. 


Stack Values
============

$xxxx  - 16bit Hex int value
$xx    -  8bit Hex int value 
"xxx"  - String (250 char max)
%xxxxx  - 16bit binary value

Words
=====


While still a lot of dev going on see ![WORD-LIST.md](WORD-LIST.md) for watch is working and what is left to do. There is also a shell script that lists the words from the source and shows which ones are working and what are left to do.


Restrictions
============


* So far IF THEN is working but can't do nested IFs on same line (sub-words are fine). 
* DO LOOP is working and can do nested loops.
* 16bit Int maths is working.
* Frame buffer display is slowing things down so now have a word to disable refresh on every . and rely on DRAW to refresh on demand.

Bugs
====

Oh boy, a heck of a lot of bugs. Currently have some spurious stack under/over flows. Have added checks for stack corruption but not getting
everything. Most likely due to little to no constraint checks on things. Need to add guards around as much as possible to provide clues
to where such faults lie. 

There is a built-in reg state display. It is enabled by default and at various break points (see firmware.asm defines) the current reg 
state can be seen with options (via 1-9) dumps of 16bit reg pointers. Use '0' to step to the next point. All breakpoints can be
disabled by using the asterisk and then using '0' to continue. See BP keyword.

Top right of reg state shows labels which can then be looked up in the source code.

Using '#' will launch a full featured monitor. 
   D xxxxx to start a dump from hex address
   C    Continue from last D
   Q  Return to break point

   M xxxx     Start edit address
   U xx        Load byte into address and increment to next


Holding down a key at boot will halt at the end of the splash screen. Releasing the key will display a hardware/system diags screen.







 


