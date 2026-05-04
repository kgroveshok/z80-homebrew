Tape Format
-----------


Trying a combination of pulse counts vs pulse lengths.

As this platform is inspired by the Jupiter Ace then would seem natural to use the ZX-81 tape approach, though it is the most 
unreliable one being just an RC circuit rather than making use of something like KCS or other reliable frequency detection
circuits.

It is a very easy circuit to put together but requires a tight firmware loop for decoding. I had hoped to provide a
Forth implentation but due to interp and guard rails in the OS it isn't fast enough. But there is a TAPESET word that
will allow tweaking for the params.

Objective is to have some words that can save random strings (which could be uwords) as well as a whole user 
dicitionary dump to tape.


Prototype
---------

The add-on for the moment will remain as a strip/bread board solution and once reliable enough (within reason) 
I will include on the main board as the board needs reworking from previous changes.


Development/Testing
-------------------

When time allows samples and screen shots of development will be included.

For source see firmware_tape.asm


