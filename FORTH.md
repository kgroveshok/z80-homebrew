FORTH OS
--------

I love Forth. Used it off and on over the years as it is the easiet programming language to design.

I now have one in this bit of kit. I was inspired by the Jupiter Ace and with screen limitiations
a version of BASIC would be too tedious and painful to use. Forth is best option. With it tied to
the hardware I've added built-in keywords to take advantage of the hardware.

At the moment it is interpreted but there is the possiblity I can add compiled words as each 
keyword has a byte OP code. 



Variables/Stack
================

The data stack pointer (DSP) supports string and numbers on the same stack for opperations (just note some words don't check and assume a particular type)


* $xxxx  - 16bit Hex int value
* $xx    -  8bit Hex int value 
* "xxx"  - String (250 char max)
* #99999   - A 16bit decimal int  
* %xxxxx  - 16bit binary value (todo)

Note: If text appears to the parser that isnt above or a valid word in any form it will be pushed to the stack with the assumption that it is a string of some sort.

e.g.

a b c d

If they are not 'words' then you will get four strings on the stack. It is a handy means to push a single text word to the stack without having to worry about quoting it. There is a further feature in that if you push a sentence onto the stack and join each word with the '-' (hyphen) it will be pushed as a whole string and can be displayed with the '-' automatically replaced with a space using the .- word:

e.g.

this-is-a-string .-

Displays as:

this is a string

Again removes the need to double quote strings and possibly miss one. Reduces the space too!

There are also a number of variables which hold 16bit values: V0-V3. They are set using ! and pushed to stack with @, e.g. $03 v0! to set, and v0@ will push $03 onto the stack. While not that flexible nor using standard FORTH methods, there is another way to have an any kind of data structure available.

The PTR, MALLOC and SCRATCH words provide a dynamic (MALLOC) or fixed buffer (SCRATCH) areas for whatever data/variable structure you require:

e.g.

Pushes a pointer to the stack for the offset 0 in the scratch area.

: score $00 scratch ;

This allows for things such as setting and then incrementing at "variable":

$00 score !

$01 score +!

This method supports both single byte and word accesses via !/2! etc. There is no checking so ensure no overlap!

e.g.

: timer $01 scratch ;

Don't use:

$01 score 2!

As that would over write 'timer'.



Another variable method is the use of VAR.

e.g.

"a" VAR @



Storage
=======


Various storage words for both high level file access as well as direct block access. 

Through the use of the CONFIG word it is possible to select a file to be executed at boot time and load word definitions into memory.



There are a few low level words if you want to write your own file system handler. See BREAD, BWRITE and BUPD in the word list.


Alternativly using the high level file system words provide a more conveient means to access data and code (using CONFIG to enable auto run of stored code).


Bank 1 would normally default (unless selected a different startup bank). Using "$02 bank" for example will change to the second bank of storage. Initially each bank will need to be initialised with the 'format' word.


A default label will be assigned and it can be changed with the 'label' word: "MyCode" label


Creating a new file:      "myfile" create

The file ID used for all file words later is pushed to stack. It is possible to obtain the ID when needing such a number later by using the GETID word to look up the file name
and return the ID.


Once the file has been created it is possible to add data to it via the 'APPEND' word: "a line to add" $01 append


There is no need to close files as such. There is a word 'record' which provides a random access to the created files. For a sequential read use the 'OPEN' word to set the
file record number to the first one and then each use of the 'READ' word to retrieve and push each record to stack until the 'EOF' word reports as true or using the counter that 'open' reports.


As such, only one open file for reading is possible, but it is possible to APPEND to multiple output files.


Autostart
=========


If a file begins with an asterisk the file will be auto loaded at start up. Use RENAME to switch files on and off.
Or for blanket enable and disable use CONFIG word to toggle in the UI. CONFIG will also provide a means to select which bank of files 
will be used for startup; useful if a particular application exists in one bank and you don't need it to always load.

> [!NOTE]
> Usually files will contain a list of user word definitions, however it is possible to exec words 
> as they are loaded using already loaded words, in this case be aware that if any code on the single line affects BANK selection
> ensure that the origin BANK occurs (use BANK?) before end so that auto loading can continue as this is not done
> automatically between each line load just in case that effect is needed.




Words
=====


User words are executed before system words so in theory you could replace system words with your own...

While still a lot of dev going on see ![WORD-LIST.md](WORD-LIST.md) for watch is working and what is left to do. There is also a shell script that lists the words from the source and shows which ones are working and what are left to do.


Demo Code
=========

The board has an auto start-up process that loads extra words. These include some demo programs such as:

* sw - Hello world
* ga - A simple number guessing game
* ssv - A screen saver

Look in the file ![forth_autostart.asm](os/forth_autostart.asm) source file for the definitions.


Restrictions
============


* So far IF THEN is working but can't do nested IFs on same line (sub-words are fine). 
* DO LOOP is working and can do nested loops.
* 16bit integer maths is working. Would like to add floating point...
* Frame buffer display is slowing things down so now have a word to disable refresh on every update but that doesn't help. Needs a rewrite.
* Keyword lookups while running so can be quite slow to run code. A lot of debug code is included as well as memory corruption sanity guards. Will look at speeding things up by switching on/off debug and guard code as well as working on a compile option.

Bugs
====

Oh boy, possibly a heck of a lot of bugs. Little sanity checking so watch out. 

Look at ![DEV-DIARY.md](DEV-DIARY.md) for current state of the bugs.

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


Holding down a key at boot will halt at the end of the splash screen. Releasing the key will display a hardware/system diags screen. Can also get to that point with the use of the CONFIG word.


The firmware.asm file contains many debug switches. If they are all off the resulting binary file is around half the size and runs at a reasonable rate. Will full debug on there isn't much ROM space left and performance does suffer but the level of debug tracking is really useful especially if new words are being developed or a bug is identified in one.


The make.sh will also generate three debug levels of the ROM. Level DL0 is with no debug or system guards in place. Could be a problem if you mess up code but it will run the fastest. DL1 has some debug code in place to help with tracing programs and has stack corruption guards in place. DL2 has the most debug code in place. Will run pretty slow but should be robust if you are testing lowlevel stuff.


Utils
-----

nip ( w1 w2 - w2 )
tuck ( x1 x2 -- x2 x1 x2 ) 

 


