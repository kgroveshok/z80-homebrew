# z80-homebrew
Z80 Home Brew Micro-computer Project
------------------------------------

Having watched so many retro computing videos on YouTube I thought I would relive some of my youth
by building something simple. I remember the old electronic magazines of the 1980's which 
had plenty of simple programmable computing devices to make at home.  Always wanted one. Now I
will do it - only a few decades behind :-)


6502 vs Z80
-----------

My first home computer was a Vic20. Not long after having that in my grubby mitts I was writing
6502 machine code, hand assembling as we all did back then. Later I moved onto an Amstrad CPC464
and dived into Z80 which I then took to the Amstrad PCW 512.

Looking around at parts I found it hard to locate any good 6502 parts and with the vast
Z80 community and lots of great material to dust off my rusty electronics skills I chose that.

Therefore this project, is Z80 based. Turns out that is a good choice as the arch is very simple
with a load of great chips that tie closely together. Makes for an easier life.


Stage 1.0 DONE
--------------

Create a basic breadboard circuit with CPU, clock (for now 555 so I can watch it do things) and RAM.

The CPU is executing whatever random code is in the RAM at start up. Looks pretty with the flashing lights.

See this stage at [![(Stage 1)](https://youtu.be/8DWXKSt4nWc)]

![](images/20220321_072123-stage1.jpg)


Stage 1.5 DONE
--------------

Resolve the issue I have in manual bit bashing machine code into RAM.

Now fixed in [![Stage 1.5](https://youtu.be/Ls7xwXhakNc)]

![](images/20220322_210657-bitbashfixed.jpg)

Stage 2.0 DONE
--------------

Now I have the sequence to program RAM by hand, speed it. Because I don't have an (E)EPROM 
and programmer I will put a PIC to act as a bootstrap loader at Z80 startup and bit bash a simple 
monitor program into RAM which I can then use to load further code.

First part will be to load the same simple program as used in the the Stage 1.5 test. Once that
electronics is working I can then write larger programs to boot strap which will be where Stage 3.0 
comes in...


Testing shift register... [![Video](https://youtu.be/uMFlNMZjTEM)]


![](images/20220324_191246.jpg)


Testing shift reg sequence [![Video](https://youtu.be/3TNWDdLDNPk)]

Ready to boot strap! [![Video](https://youtu.be/jSUHhDZqcws)]

Another go which does'nt quite work... [![Video](https://youtu.be/zBmXrHQtJYk)]... Turns out 
that powering down mid shift register loading fixes it. Will do a better fix with the 
coding on the PIC :-)


Stage 2.5 (NOW)
---------------

The breadboard is becoming quite full, and with the next stage focusing on RS232 where timing is 
important, I think it might be a good idea to finish off the low speed parts first, then
moving as much as I can off of the breadboard to strip board for the space and more stable 
circuit at speed.

In this stage then I want to perhaps add a second 32k RAM chip as the high address bit wire is
currently unconnected. That will then provide a full 64k RAM, as well as the prospect that I
could swap out either RAM and replace with a ROM further down the line. 

I will also obviously add a couple of NAND gates to switch between them. I may also future
proof the setup and consider tapping another address line and splitting the top half into 
smaller sections so that I can slip in external device memory maps. That will depend on the
requirements for the DART, SIO, PIO chips next. Of course moving to strip board using the
stacking method I'm considering means that if I need to change page addressing, I will only
need to swap out the card(s) affected and not the whole board. Bonus!

To do this I *REALLY* need to document the board! :-) I will be using maybe Eagle or easyEDA for 
the main schematic and then ancient VeeCAD for the strip board layout.


Stage 3.0
---------

Rig up the Z80 DART, SIO or PIO chip to add RS232 support and then program the to the boot loader 
with a monitor program and remote program load function.

At this stage I will have serial terminal working and would therefore be a functional computer to
some extent.


Stage 4.0
---------

Add some external interfaces to make it do other things would be useful. Perhaps even to drive a
small LCD screen like those old Sharp handhend computers I remember. Would also need to add keypad
support of somekind which then makes it a self contained computer.


Where to go from here?
----------------------

The DART chip provides more than one serial interface and considering I bought enough parts for 
another Z80 system perhaps I could build some kind of basic networking stack? That would be fun!

Lots of things... Keyboards, screens, SD cards, general interfaces....



Parts
-----

At each stage I will document and attach the schematics for mostly for my own reference should things go wrong.

Final Construction
------------------

I think what would be good is if I at various stages of complete circuit put those working bits down on to
their own strip board (for now) and have the sections stackable. That would help in replacement of parts
and in developing new bits. For example:

* Layer 1 - Power supply and clock selection
* Layer 2 - CPU
* Layer 3 - Memory
# Layer 4 - Boot strap PIC
* Layer 5 - Serial and other interfaces
* Layer 6 - Control Panel (so I could remove the flashy lights and only attach for debug)
* Layer 7 - LCD and keypad

All a bit like the RC2014 but not :-)




References
----------

I found so much great advice and inspiration around the net here are some of those that made the most
impact (in no particular order):


* [https://maker.pro/pic/projects/z80-computer-project-part-1-the-cpu]
* [https://www.electromaker.io/blog/article/z80-computer-memory]
* [https://www.youtube.com/watch?v=yR566HNj0ao]
* [https://bread80.com/category/couch-to-64k/]
* [https://maggi9295.github.io/projects/z80computer/z80computer.html]
* [http://www.breakintoprogram.co.uk/projects/homebrew-z80/homebrew-z80-computer-part-1]
* [https://incoherency.co.uk/blog/stories/rc2014-frontpanel.html]
* [https://www.instructables.com/An-Easy-to-Build-Real-Homemade-Computer-Z80-MBC2/]
* [https://sites.google.com/view/erics-projects/z-80-projects-page/z-80-pio-ps2-keyboard-interface]
* [http://www.cpuville.com/Projects/Standalone-Z80-computer/Standalone-Z80-home.html]
* [http://www.blunk-electronic.de/train-z/]
* [http://www.friendlywire.com/tutorials/pic-flash/]
* [http://www.waveguide.se/?article=programming-pics-using-the-pickit2-and-pk2cmd]
* [https://microcontrollerslab.com/74hc595-shift-register-interfacing-pic-microcontroller/]
* [https://www.electroschematics.com/multiple-shift-registers-arduino-part-1/]



