# Forth Language Reference





Also refer to the auto start list examples as these contain extra words created at runtime as needed


## Constants (i.e. Useful memory addresses that can set or get features)


### SPITIME ( -- u1 )   Pushes address of the SPI pulse counter/delay to stack


### If using BANK devices then leave as is.


### Only really useful for the CARTDEV where other devices may be too far or slow. In particular


### the multiplexing of the PicoSPINet device which might not be running fast enough for all of the nodes


### VA ( -- u1 )   Pushes address of block of memory used for v1..5


### SYMBOL ( u1 -- )  Get the address of a system symbol from a look up table to TOS  | DONE





### The value is the number reference and the final address is pushed to stack


## Core Words


### HEAP ( -- u1 u2 )   Pushes u1 the current number of bytes in the heap and u2 the remaining bytes - Only present if using my MALLOC | DONE


 u1 - Current number of bytes in the heap


 u2 - Remaining bytes left on the heap


 


 The heap is used for storing user defined words as well as any values pushed to stack.


### DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE


### ?DUP ( u -- u u )     Duplicate item on TOS if the item is non-zero | DONE


### SWAP ( w1 w2 -- w2 w1 )    Swap top two items on TOS | DONE


### : ( -- )         Create new word | DONE


### ; ( -- )     Terminate new word and return exec to previous exec level | DONE


### DROP ( w -- )   drop the TOS item   | DONE


### 2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  | DONE


### 2DROP ( w w -- )    Double drop | DONE


### 2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items | TODO


### @ ( w -- ) Push onto TOS byte stored at address   | DONE


### C@  ( w -- ) Push onto TOS byte stored at address   | DONE


### ! ( x w -- ) Store x at address w      | DONE


### C!  ( x w -- ) Store x at address w  | DONE


### CALL ( w -- w  ) machine code call to address w  push the result of hl to stack | DONE


### DEPTH ( -- u ) Push count of stack | DONE


### OVER ( n1 n2 -- n1 n2 n1 )  Copy one below TOS onto TOS | DONE


### PAUSEMS ( n -- )  Pause for n millisconds | DONE


### PAUSE ( n -- )  Pause for n seconds | DONE


### ROT ( u1 u2 u3 -- u2 u3 u1 ) Rotate top three items on stack | DONE


### UWORDS (  -- s1 ... sn u )   List user word dict | DONE


 After use the TOS will have a count of the number of user words that have been pushed to stack.


 Following the count are the individual words.





 e.g. UWORDS


 BOX DIRLIST 2


 


 Can be used to save the words to storage via:


 UWORDS $01 DO $01 APPEND LOOP


### BP ( u1 -- ) Enable or disable break point monitoring | DONE


 $00 Will enable the break points within specific code paths


 $01 Will disable break points


 


 By default break points are off. Either the above can be used to enable them


 or if a key is held down during start up the spashscreen will appear to freeze


 and on release of the pressed key a message will be disaplayed to notify


 that break points are enabled. Pressing any key will then continue boot process.


### MONITOR ( -- ) Display system breakpoint/monitor | DONE


 At start the current various registers will be displayed with contents.


 Top right corner will show the most recent debug marker seen.


 The bottom of the screen will also show the values of the data stack pointer (DSP)


 and the return stack pointer (RSP).


 Pressing:


    1 - Initial screen


    2 - Display a data dump of HL


    3 - Display a data dump of DE


    4 - Display a data dump of BC


    5 - Display a data dump of HL


    6 - Display a data dump of DSP


    7 - Display a data dump of RSP


    8 - Display a data dump of what is at DSP


    9 - Display a data dump of what is at RSP


    0 - Exit monitor and continue running. This will also enable break points


    * - Disable break points


    # - Enter traditional monitor mode





 Monitor Mode


 ------------


 A prompt of '>' will be shown for various commands:


    D xxxx - Display a data dump starting from hex address xxxx


    C - Continue display a data dump from the last set address


    M xxxx - Set start of memory edit at address xx


    U xx - Poke the hex byte xx into the address set by M and increment the address to the next location


    Q - Return to previous


### ALLOT ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | DONE


### MALLOC ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | DONE


### FREE ( u --  ) Free memory block from malloc given u address  | DONE


### LIST ( uword -- u )    List the code to the word that is quoted (so as not to exec) on TOS | DONE


 The quoted word must be in upper case.


### FORGET ( uword -- )    Forget the uword on TOS | DONE


 Will flag the word's op code to be deleted as well as replace the first char of the word with '_'. Quote uword name must be in caps.


 


 e.g. "MORE" forget


### NOP (  --  ) Do nothing | DONE


### ( ( -- )  Start of comment | DONE


### ) ( -- )  End of comment |  DONE 


### SCRATCH ( u -- addr ) Pushes address of offset u to stack | DONE


 The scratch area provides 32 word array. Can be used as single byte or as a word by passing the offset on stack. Pushes the resulting address to stack. 


 When used with the direct storage writing/malloc and the !@ or word versions it is possible to construct an expanded and flexible variable system


 


 e.g.    : score $00 scratch ;


 


 $00 score !


 $01 score +!


 


 e.g.   : varword $0a scratch ; 





 $8000 varword !


### +! ( u a -- )  Increment byte at address a by the value u | DONE


### -! ( u a -- )  Decrement byte at address a by the value u | DONE


### +2! ( u a -- )  Increment word at address a by the value u | DONE


### -2! ( u a -- )  Decrement word at address a by the value u | DONE


### 2@ ( a -- u )  Push word at address a onto stack | DONE


### 2! ( u a -- )  Store value u as a word at address a | DONE


### CONFIG ( -- )  Access the system configuration menu. Set boot from file, hardware diags, and more! | DONE


## Device Words


### TODO


### IOIN ( u1 -- u )    Perform a GPIO read of pin u1 and push result  | 


### IOOUT ( u1 u2 --  )    Perform a GPIO write of pin u1 with pin set to 0 or 1 in u2  | 


### IOBYTE ( u1 --  )    Perform a GPIO write of byte u1  | 


### IOSET ( u1 --  )    Setup GPIO pins for I/O direction. Bit is set for write else read pin  | 


### IN ( u1 -- u )    Perform Z80 IN with u1 being the port number. Push result to TOS | TO TEST


### OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | DONE


### SPICEL ( -- ) Set SPI CE low for the currently selected device |  DONE


### SPICEH ( -- ) Set SPI CE high for the currently selected device |  DONE


### SPIO ( u1 -- ) Send byte u1 to SPI  |  DONE


### SPII ( -- u1 ) Get a byte from SPI  | DONE


### BANK ( u1 -- ) Select Serial EEPROM Bank Device at bank address u1 1-5 (disables CARTDEV). Set to zero to disable storage. | DONE


### CARTDEV ( u1 -- ) Select cart device 1-8 (Disables BANK). Set to zero to disable devices. |  DONE


## Display Words


### INFO ( u1 u2 -- )  Use the top two strings on stack to fill in an info window over two lines. Causes a wait for key press to continue. | DONE


### AT? ( -- c r )  Push to stack the current position of the next print | TO TEST


### FB ( u -- ) Select frame buffer ID u (1-3)  |  DONE


 Default frame buffer is 1. System uses 0 which can't be selected for system messages etc.


 Selecting the frame buffer wont display unless automatic display is setup (default).


 If automatic display is off then updates will not be shown until DRAW is used.


###  EMIT ( u -- ) Display ascii character  TOS   | DONE


### .- ( u -- ) Display TOS replacing any dashes with spaces. Means you dont need to wrap strings in double quotes!   | DONE


### .> ( u -- ) Display TOS and move the next display point with display  | WIP


### . ( u -- ) Display TOS | DONE


### CLS ( -- ) Clear current frame buffer and set next print position to top left corner  | DONE


### DRAW ( -- ) Draw contents of current frame buffer  | DONE


### DUMP ( x -- ) With address x display dump   | DONE


### CDUMP ( -- ) Continue dump of memory from DUMP | DONE


### AT ( u1 u2 -- ) Set next output via . or emit at row u2 col u1 | DONE


### HOME ( -- ) Reset the current cursor for output to home | DONE


### BL (  -- c ) Push the value of space onto the stack as a string  | DONE


### SPACES ( u -- str ) A string of u spaces is pushed onto the stack | DONE


### SCROLL ( -- ) Scroll up one line - next write will update if required | DONE


### SCROLLD ( -- ) Scroll down one line - next write will update if required | TO DO


### AT@ ( u1 u2 -- n ) Push to stack ASCII value at row u2 col u1 | DONE


### ADSP ( u1 --  ) Enable/Disable Auto screen updates (SLOW). | DONE


 If off, use DRAW to refresh. Default is on. $0003 will enable direct screen writes (TODO) 


### MENU ( u1....ux n -- n ) Create a menu. n is the number of menu items on stack. Push number selection to TOS | TODO


## Program Flow Words


### IF ( w -- f ) If TOS is true exec code following up to THEN - Note: currently not supporting ELSE or nested IF | DONE


### THEN ( -- ) Does nothing. It is a marker for the end of an IF block | DONE


### ELSE ( -- ) Not supported - does nothing | TODO


### DO ( u1 u2 -- ) Loop starting at u2 with a limit of u1 | DONE


### LOOP ( -- ) Increment and test loop counter  | DONE


### I ( -- ) Current loop counter | DONE


### -LOOP ( -- ) Decrement and test loop counter  | DONE


### REPEAT ( --  ) Start REPEAT...UNTIL loop  | DONE


### UNTIL ( u -- ) Exit REPEAT...UNTIL loop if TOS is false  | DONE


## Keyboard Words


### KEY ( -- w f ) Scan for keypress but do not wait true if next item on stack is key press | TODO


### WAITK ( -- w ) Wait for keypress TOS is key press | DONE


### ACCEPT ( -- w ) Prompt for text input and push pointer to string | DONE


### EDIT ( u -- u ) Takes string on TOS and allows editing of it. Pushes it back once done. | DONE


### DEDIT ( ptr --  ) Takes an address for direct editing in memory. | TO TEST


## Logic Words


### NOT ( u  -- u ) Inverse true/false on stack | DONE


### IS ( s1 s2  -- f ) Push true if string s1 is the same as s2 | TODO


### 0< ( u -- f ) Push true if u is less than o | CANT DO UNTIL FLOAT


### 0= ( u -- f ) Push true if u equals 0 | TEST NO DEBUG


### < ( u1 u2 -- f ) True if u1 is less than u2 | DONE


### > ( u1 u2 -- f ) True if u1 is greater than u2 | DONE


### = ( u1 u2 -- f ) True if u1 equals u2 | DONE


## Maths Words


### + ( u u -- u )    Add two numbers and push result   | INT DONE


### - ( u1 u2 -- u )    Subtract u2 from u1 and push result  | INT DONE


### / ( u1 u2 -- result remainder )     Divide u1 by u2 and push result | INT DONE


### * ( u1 u2 -- u )     Multiply TOS and push result | INT DONE


### MIN (  u1 u2 -- u3 ) Whichever is the smallest value is pushed back onto the stack | DONE


### MAX (  u1 u2 -- u3 )  Whichever is the largest value is pushed back onto the stack | DONE


### RND16 (  -- n ) Generate a random 16bit number and push to stack | DONE


### RND8 (  -- n ) Generate a random 8bit number and push to stack | DONE


### RND ( u1 u2 -- u ) Generate a random number no lower than u1 and no higher than u2 and push to stack | DONE


## Fixed Storage Words


### RECORD ( u id -- s ) With the current bank, read record number u from file id and push to stack  | DONE


 Compatible with PicoSPINet 


### BREAD ( u -- u ) Lowlevel storage word. With the current bank, read a block from page id u (1-512) and push to stack  | DONE


 Compatible with PicoSPINet 


### BWRITE ( s u -- ) Lowlevel storage word. With the current bank, write the string s to page id u | DONE


 Compatible with PicoSPINet 


### BUPD ( u -- ) Lowlevel storage word. Write the contents of the current file system storage buffer directly to page id u | DONE


 Coupled with the use of the BREAD, BWRITE and STOREPAGE words it is possible to implement a direct


 or completely different file system structure.


 Compatible with PicoSPINet 


### GETID ( s -- u ) Get the file ID in the current BANK of the file named s | DONE


 Compatible with PicoSPINet 


### DIR ( u -- lab id ... c t ) Using bank number u push directory entries from persistent storage as w with count u  | DONE


 Compatible with PicoSPINet 


### SEO ( u1 u2 -- ) Send byte u1 to Serial EEPROM device at address u2 | DONE


### SEI ( u2 -- u1 ) Get a byte from Serial EEPROM device at address u2 | DONE


### FFREE ( -- n )  Gets number of free file blocks on current storage bank | DONE


 Compatible with PicoSPINet 


### SIZE ( u -- n )  Gets number of blocks used by file id u and push to stack | DONE


 Compatible with PicoSPINet 


### CREATE ( u -- n )  Creates a file with name u on current storage bank and pushes the file id number to TOS | DONE


 e.g. 


 TestProgram CREATE


 Top of stack will then be the file ID which needs to be used in all file handling words


 


 Max file IDs are 255.


 


 Compatible with PicoSPINet 


### APPEND ( u n --  )  Appends data u to file id on current storage bank | DONE


 e.g.


 Test CREATE      -> $01


 "A string to add to file" $01 APPEND


 


 The maximum file size currently using 32k serial EEPROMS using 64 byte blocks is 15k.


 Compatible with PicoSPINet 


### ERA ( n --  )  Deletes all data for file id n on current storage bank | DONE


 Compatible with PicoSPINet 


### OPEN ( n -- n )  Sets file id to point to first data page for subsequent READs. Pushes the max number of blocks for this file | DONE


 e.g.


 $01 OPEN $01 DO $01 READ . LOOP





 Will return with 255 blocks if the file does not exist


 Compatible with PicoSPINet 


### READ ( -- n  )  Reads next page of current file id and push to stack | DONE


 e.g.


 $01 OPEN $01 DO READ . LOOP





 As this word only reads one 64 byte block in at a time, if the APPEND word has created extra blocks for the excess, this READ


 word is unaware so the long string needs to be joined if the string is a full. A single block read might be what you want,


 but if not then writing a word to join blocks will be required. The upshot is a full string will be 62 bytes as the first


 two bytes contain the file id and extent.


 


 Note: There is a flag that enables/disables long block reads called 'store_longread' and a poke of a non-zero value will


 enable the code to automatically read futher blocks if full. It is BUGGY so don't use for now.


 Compatible with PicoSPINet 


### EOF ( -- u )  Returns EOF logical state of current open file id | DONE


 e.g.


 $01 OPEN REPEAT READ EOF $00 IF LOOP


 Compatible with PicoSPINet 


### FORMAT (  --  )  Formats the current bank selected (NO PROMPT!) | DONE


 Compatible with PicoSPINet 


### LABEL ( u --  )  Sets the storage bank label to string on top of stack  | DONE


 Compatible with PicoSPINet 


### STOREPAGE ( -- addr )  Pushes the address of the file system record buffer to stack for direct access  | DONE


 Compatible with PicoSPINet 


### LABELS (  -- b n .... c  )  Pushes each storage bank labels (n) along with id (b) onto the stack giving count (c) of banks  | TO TEST


 *NOT* Compatible with PicoSPINet 


### FILEID (  -- u1  )  Pushes currently open file ID to stack | DONE


 Compatible with PicoSPINet 


### FILEEXT (  -- u1  )  Pushes the currently read file extent of the file to stack | DONE


 Compatible with PicoSPINet 


### FILEMAXEXT (  -- u1  )  Pushes the maximum file extent of the currenlty open file to stack | DONE


 Compatible with PicoSPINet 


### FILEADDR (  -- u1  )  Pushes the address of the block accessed for the currenlty open file to stack | DONE


 Compatible with PicoSPINet 


### FILEPAGE (  -- u1  )  Pushes the page id block accessed for the currenlty open file to stack | DONE


 Compatible with PicoSPINet 


### READCONT (  -- u1  )  Pushes the READ continuation flag to stack | DONE


 If the most recent READ results in a full buffer load then this flag is set and will indicate that


 a further read should, if applicable, be CONCAT to the previous read.


 Compatible with PicoSPINet 


## String Words


### PTR ( -- addr ) Low level push pointer to the value on TOS | DONE


 If a string will give the address of the string without dropping it. Handy for direct string access


 If a number can then use 2@ and 2! for direct value update without using stack words 


### STYPE ( u -- u type ) Push type of value on TOS - 's' string, 'i' integer...   | DONE


### UPPER ( s -- s ) Upper case string s  | DONE


### LOWER ( s -- s ) Lower case string s  | DONE


### TCASE ( s -- s ) Title case string s  | DONE


### SUBSTR ( s u1 u2 -- s sb ) Push to TOS chars starting at position u1 and with length u2 from string s  | DONE


### LEFT ( s u -- s sub ) Push to TOS string u long starting from left of s  | TODO


### RIGHT ( s u -- s sub ) Push to TOS string u long starting from right of s  | TODO


### STR2NUM ( s -- n ) Convert a string on TOS to number | DONE


### NUM2STR ( n -- s ) Convert a number on TOS to string | NOT DOING


### CONCAT ( s1 s2 -- s3 ) A s1 + s2 is pushed onto the stack | DONE


### FIND ( s c -- s u ) Search the string s for the char c and push the position of the first occurance to TOS | DONE


### COUNT (  str -- str u1 ) Push the length of the string str on TOS as u1 | DONE


### ASC ( u -- n ) Get the ascii value of the first character of the string on the stack | DONE


### CHR ( u -- n ) The ASCII character value of u is turned into a string n on the stack | DONE


# Words Ready To Use





### SYMBOL ( u1 -- )  Get the address of a system symbol from a look up table to TOS  | DONE


### HEAP ( -- u1 u2 )   Pushes u1 the current number of bytes in the heap and u2 the remaining bytes - Only present if using my MALLOC | DONE


### DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE


### ?DUP ( u -- u u )     Duplicate item on TOS if the item is non-zero | DONE


### SWAP ( w1 w2 -- w2 w1 )    Swap top two items on TOS | DONE


### : ( -- )         Create new word | DONE


### ; ( -- )     Terminate new word and return exec to previous exec level | DONE


### DROP ( w -- )   drop the TOS item   | DONE


### 2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  | DONE


### 2DROP ( w w -- )    Double drop | DONE


### @ ( w -- ) Push onto TOS byte stored at address   | DONE


### C@  ( w -- ) Push onto TOS byte stored at address   | DONE


### ! ( x w -- ) Store x at address w      | DONE


### C!  ( x w -- ) Store x at address w  | DONE


### CALL ( w -- w  ) machine code call to address w  push the result of hl to stack | DONE


### DEPTH ( -- u ) Push count of stack | DONE


### OVER ( n1 n2 -- n1 n2 n1 )  Copy one below TOS onto TOS | DONE


### PAUSEMS ( n -- )  Pause for n millisconds | DONE


### PAUSE ( n -- )  Pause for n seconds | DONE


### ROT ( u1 u2 u3 -- u2 u3 u1 ) Rotate top three items on stack | DONE


### UWORDS (  -- s1 ... sn u )   List user word dict | DONE


### BP ( u1 -- ) Enable or disable break point monitoring | DONE


### MONITOR ( -- ) Display system breakpoint/monitor | DONE


### ALLOT ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | DONE


### MALLOC ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | DONE


### FREE ( u --  ) Free memory block from malloc given u address  | DONE


### LIST ( uword -- u )    List the code to the word that is quoted (so as not to exec) on TOS | DONE


### FORGET ( uword -- )    Forget the uword on TOS | DONE


### NOP (  --  ) Do nothing | DONE


### ( ( -- )  Start of comment | DONE


### ) ( -- )  End of comment |  DONE 


### SCRATCH ( u -- addr ) Pushes address of offset u to stack | DONE


### +! ( u a -- )  Increment byte at address a by the value u | DONE


### -! ( u a -- )  Decrement byte at address a by the value u | DONE


### +2! ( u a -- )  Increment word at address a by the value u | DONE


### -2! ( u a -- )  Decrement word at address a by the value u | DONE


### 2@ ( a -- u )  Push word at address a onto stack | DONE


### 2! ( u a -- )  Store value u as a word at address a | DONE


### CONFIG ( -- )  Access the system configuration menu. Set boot from file, hardware diags, and more! | DONE


### OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | DONE


### SPICEL ( -- ) Set SPI CE low for the currently selected device |  DONE


### SPICEH ( -- ) Set SPI CE high for the currently selected device |  DONE


### SPIO ( u1 -- ) Send byte u1 to SPI  |  DONE


### SPII ( -- u1 ) Get a byte from SPI  | DONE


### BANK ( u1 -- ) Select Serial EEPROM Bank Device at bank address u1 1-5 (disables CARTDEV). Set to zero to disable storage. | DONE


### CARTDEV ( u1 -- ) Select cart device 1-8 (Disables BANK). Set to zero to disable devices. |  DONE


### INFO ( u1 u2 -- )  Use the top two strings on stack to fill in an info window over two lines. Causes a wait for key press to continue. | DONE


### FB ( u -- ) Select frame buffer ID u (1-3)  |  DONE


###  EMIT ( u -- ) Display ascii character  TOS   | DONE


### .- ( u -- ) Display TOS replacing any dashes with spaces. Means you dont need to wrap strings in double quotes!   | DONE


### . ( u -- ) Display TOS | DONE


### CLS ( -- ) Clear current frame buffer and set next print position to top left corner  | DONE


### DRAW ( -- ) Draw contents of current frame buffer  | DONE


### DUMP ( x -- ) With address x display dump   | DONE


### CDUMP ( -- ) Continue dump of memory from DUMP | DONE


### AT ( u1 u2 -- ) Set next output via . or emit at row u2 col u1 | DONE


### HOME ( -- ) Reset the current cursor for output to home | DONE


### BL (  -- c ) Push the value of space onto the stack as a string  | DONE


### SPACES ( u -- str ) A string of u spaces is pushed onto the stack | DONE


### SCROLL ( -- ) Scroll up one line - next write will update if required | DONE


### AT@ ( u1 u2 -- n ) Push to stack ASCII value at row u2 col u1 | DONE


### ADSP ( u1 --  ) Enable/Disable Auto screen updates (SLOW). | DONE


### IF ( w -- f ) If TOS is true exec code following up to THEN - Note: currently not supporting ELSE or nested IF | DONE


### THEN ( -- ) Does nothing. It is a marker for the end of an IF block | DONE


### DO ( u1 u2 -- ) Loop starting at u2 with a limit of u1 | DONE


### LOOP ( -- ) Increment and test loop counter  | DONE


### I ( -- ) Current loop counter | DONE


### -LOOP ( -- ) Decrement and test loop counter  | DONE


### REPEAT ( --  ) Start REPEAT...UNTIL loop  | DONE


### UNTIL ( u -- ) Exit REPEAT...UNTIL loop if TOS is false  | DONE


### WAITK ( -- w ) Wait for keypress TOS is key press | DONE


### ACCEPT ( -- w ) Prompt for text input and push pointer to string | DONE


### EDIT ( u -- u ) Takes string on TOS and allows editing of it. Pushes it back once done. | DONE


### NOT ( u  -- u ) Inverse true/false on stack | DONE


### < ( u1 u2 -- f ) True if u1 is less than u2 | DONE


### > ( u1 u2 -- f ) True if u1 is greater than u2 | DONE


### = ( u1 u2 -- f ) True if u1 equals u2 | DONE


### + ( u u -- u )    Add two numbers and push result   | INT DONE


### - ( u1 u2 -- u )    Subtract u2 from u1 and push result  | INT DONE


### / ( u1 u2 -- result remainder )     Divide u1 by u2 and push result | INT DONE


### * ( u1 u2 -- u )     Multiply TOS and push result | INT DONE


### MIN (  u1 u2 -- u3 ) Whichever is the smallest value is pushed back onto the stack | DONE


### MAX (  u1 u2 -- u3 )  Whichever is the largest value is pushed back onto the stack | DONE


### RND16 (  -- n ) Generate a random 16bit number and push to stack | DONE


### RND8 (  -- n ) Generate a random 8bit number and push to stack | DONE


### RND ( u1 u2 -- u ) Generate a random number no lower than u1 and no higher than u2 and push to stack | DONE


### RECORD ( u id -- s ) With the current bank, read record number u from file id and push to stack  | DONE


### BREAD ( u -- u ) Lowlevel storage word. With the current bank, read a block from page id u (1-512) and push to stack  | DONE


### BWRITE ( s u -- ) Lowlevel storage word. With the current bank, write the string s to page id u | DONE


### BUPD ( u -- ) Lowlevel storage word. Write the contents of the current file system storage buffer directly to page id u | DONE


### GETID ( s -- u ) Get the file ID in the current BANK of the file named s | DONE


### DIR ( u -- lab id ... c t ) Using bank number u push directory entries from persistent storage as w with count u  | DONE


### SEO ( u1 u2 -- ) Send byte u1 to Serial EEPROM device at address u2 | DONE


### SEI ( u2 -- u1 ) Get a byte from Serial EEPROM device at address u2 | DONE


### FFREE ( -- n )  Gets number of free file blocks on current storage bank | DONE


### SIZE ( u -- n )  Gets number of blocks used by file id u and push to stack | DONE


### CREATE ( u -- n )  Creates a file with name u on current storage bank and pushes the file id number to TOS | DONE


### APPEND ( u n --  )  Appends data u to file id on current storage bank | DONE


### ERA ( n --  )  Deletes all data for file id n on current storage bank | DONE


### OPEN ( n -- n )  Sets file id to point to first data page for subsequent READs. Pushes the max number of blocks for this file | DONE


### READ ( -- n  )  Reads next page of current file id and push to stack | DONE


### EOF ( -- u )  Returns EOF logical state of current open file id | DONE


### FORMAT (  --  )  Formats the current bank selected (NO PROMPT!) | DONE


### LABEL ( u --  )  Sets the storage bank label to string on top of stack  | DONE


### STOREPAGE ( -- addr )  Pushes the address of the file system record buffer to stack for direct access  | DONE


### FILEID (  -- u1  )  Pushes currently open file ID to stack | DONE


### FILEEXT (  -- u1  )  Pushes the currently read file extent of the file to stack | DONE


### FILEMAXEXT (  -- u1  )  Pushes the maximum file extent of the currenlty open file to stack | DONE


### FILEADDR (  -- u1  )  Pushes the address of the block accessed for the currenlty open file to stack | DONE


### FILEPAGE (  -- u1  )  Pushes the page id block accessed for the currenlty open file to stack | DONE


### READCONT (  -- u1  )  Pushes the READ continuation flag to stack | DONE


### PTR ( -- addr ) Low level push pointer to the value on TOS | DONE


### STYPE ( u -- u type ) Push type of value on TOS - 's' string, 'i' integer...   | DONE


### UPPER ( s -- s ) Upper case string s  | DONE


### LOWER ( s -- s ) Lower case string s  | DONE


### TCASE ( s -- s ) Title case string s  | DONE


### SUBSTR ( s u1 u2 -- s sb ) Push to TOS chars starting at position u1 and with length u2 from string s  | DONE


### STR2NUM ( s -- n ) Convert a string on TOS to number | DONE


### CONCAT ( s1 s2 -- s3 ) A s1 + s2 is pushed onto the stack | DONE


### FIND ( s c -- s u ) Search the string s for the char c and push the position of the first occurance to TOS | DONE


### COUNT (  str -- str u1 ) Push the length of the string str on TOS as u1 | DONE


### ASC ( u -- n ) Get the ascii value of the first character of the string on the stack | DONE


### CHR ( u -- n ) The ASCII character value of u is turned into a string n on the stack | DONE


# Words Still Left To Do





## Constants (i.e. Useful memory addresses that can set or get features)


### SPITIME ( -- u1 )   Pushes address of the SPI pulse counter/delay to stack


### If using BANK devices then leave as is.


### Only really useful for the CARTDEV where other devices may be too far or slow. In particular


### the multiplexing of the PicoSPINet device which might not be running fast enough for all of the nodes


### VA ( -- u1 )   Pushes address of block of memory used for v1..5





### The value is the number reference and the final address is pushed to stack


## Core Words


### 2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items | TODO











## Device Words


### TODO


### IOIN ( u1 -- u )    Perform a GPIO read of pin u1 and push result  | 


### IOOUT ( u1 u2 --  )    Perform a GPIO write of pin u1 with pin set to 0 or 1 in u2  | 


### IOBYTE ( u1 --  )    Perform a GPIO write of byte u1  | 


### IOSET ( u1 --  )    Setup GPIO pins for I/O direction. Bit is set for write else read pin  | 


### IN ( u1 -- u )    Perform Z80 IN with u1 being the port number. Push result to TOS | TO TEST


## Display Words


### AT? ( -- c r )  Push to stack the current position of the next print | TO TEST


### .> ( u -- ) Display TOS and move the next display point with display  | WIP


### SCROLLD ( -- ) Scroll down one line - next write will update if required | TO DO


### MENU ( u1....ux n -- n ) Create a menu. n is the number of menu items on stack. Push number selection to TOS | TODO


## Program Flow Words


### ELSE ( -- ) Not supported - does nothing | TODO


## Keyboard Words


### KEY ( -- w f ) Scan for keypress but do not wait true if next item on stack is key press | TODO


### DEDIT ( ptr --  ) Takes an address for direct editing in memory. | TO TEST


## Logic Words


### IS ( s1 s2  -- f ) Push true if string s1 is the same as s2 | TODO


### 0< ( u -- f ) Push true if u is less than o | CANT DO UNTIL FLOAT


### 0= ( u -- f ) Push true if u equals 0 | TEST NO DEBUG


## Maths Words


## Fixed Storage Words








### LABELS (  -- b n .... c  )  Pushes each storage bank labels (n) along with id (b) onto the stack giving count (c) of banks  | TO TEST


## String Words


### LEFT ( s u -- s sub ) Push to TOS string u long starting from left of s  | TODO


### RIGHT ( s u -- s sub ) Push to TOS string u long starting from right of s  | TODO


### NUM2STR ( n -- s ) Convert a number on TOS to string | NOT DOING


