Words List
------------------
 + ( u u -- u )    Add two numbers and push result   | INT DONE
 - ( u1 u2 -- u )    Subtract u2 from u1 and push result  | INT DONE
 / ( u1 u2 -- result remainder )     Divide u1 by u2 and push result | INT DONE
 * ( u1 u2 -- u )     Multiply TOS and push result | INT DONE
 DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE
  EMIT ( u -- )        Display ascii character  TOS   |
 . ( u -- )    Display TOS   |DONE
SWAP ( w1 w2 -- w2 w1 )    Swap top two items (of whatever type) on TOS
IF ( w -- f )     If TOS is true exec code following before??
THEN ( -- )     control????
ELSE ( -- )     control???
DO ( u1 u2 -- )   Loop starting at u2 with a limit of u1
LOOP ( -- )     Current loop end marker
: ( -- )         Create new word | WIP
; ( -- )     Terminate new word
DROP ( w -- )   drop the TOS item   |DONE
2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  
2DROP ( w w -- )    Double drop | DONE
2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items
 @ ( w -- ) Push onto TOS byte stored at address   | DONE
C@  ( w -- ) Push onto TOS byte stored at address   |DONE
! ( x w -- ) Store x at address w      | DONE
C!  ( x w -- ) Store x at address w  | DONE
0< ( u -- f ) Push true if u is less than o | CANT DO UNTIL FLOAT
0= ( u -- f ) Push true if u equals 0 | TEST NO DEBUG
< ( u1 u2 -- f ) True if u1 is less than u2 | DONE
> ( u1 u2 -- f ) True if u1 is greater than u2 | DONE
= ( u1 u2 -- f ) True if u1 equals u2 | DONE
CALL ( w -- w  ) machine code call to address w  push the result of hl to stack
IN ( u1-- u )    Perform z80 IN with u1 being the port number. Push result to TOS | TO TEST
 OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | TO TEST
CLS ( -- ) clear frame buffer    |DONE
DRAW ( -- ) Draw contents of current frame buffer  | DONE
DUMP ( x --  ) With address x display dump   |DONE
CDUMP ( -- ) continue dump of memory from DUMP |  DONE
DEPTH ( -- u ) Push count of stack | DONE
DIR ( u -- w... u )   Using bank number u push directory entries from persistent storage as w with count u 
SAVE  ( w u -- )    Save user word memory to file name w on bank u
 LOAD ( w u -- )    Load user word memory from file name w on bank u
 CURSOR ( u1 u2 -- )  Set next output via . or emit at row u2 col u1 |DONE
KEY ( -- w f )      scan for keypress but do not wait true if next item on stack is key press
 WAITK ( -- w )      wait for keypress TOS is key press | DONE
ACCEPT ( -- w )    Prompt for text input and push pointer to string | TEST
HOME ( -- )    Reset the current cursor for output to home |DONE
OVER ( n1 n2 -- n1 n2 n1 )  Copy one below TOS onto TOS | DONE
 PAUSEMS ( n -- )  Pause for n millisconds | DONE
 PAUSES ( n -- )  Pause for n seconds | DONE
 ROT (  -- )  
 SPACE (  -- c ) Push the value of space onto the stack as a string  | DONE
 SPACES ( u -- str )  A string of u spaces is pushed onto the stack
 CONCAT ( s1 s2 -- s3 ) A string of u spaces is pushed onto the stack
 MIN (  u1 u2 -- u3 ) Whichever is the smallest value is pushed back onto the stack | TEST NO DEBUG
 MAX (  u1 u2 -- u3 )  Whichever is the largest value is pushed back onto the stack | TEST NO DEBUG
 FIND (  -- )  
 LEN (  u1 -- u2 ) Push the length of the string on TOS
 CHAR (  -- )  
 RND (  -- )  
 WORDS (  -- )   List the system and user word dict
 UWORDS (  -- )   List user word dict
 SPIO ( u1 u2 -- ) Send byte u1 to SPI device u2 |  WIP
 SPII ( u1 -- ) Get a byte from SPI device u2 |  WIP
 SCROLL ( u1 c1 -- ) Scroll u1 lines/chars in direction c1 | WIP
 BP ( u1 -- ) Enable or disable break point monitoring | TEST
 MONITOR ( -- ) Display system breakpoint/monitor | DONE
 MALLOC ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | TEST
 FREE ( u --  ) Free memory block from malloc given u address  | TEST
 STRLEN ( u1 -- Using given address u1 push then zero term length string to TOS )   |
 STRCPY ( u1 u2 -- Copy string u2 to u1 )   |
BSAVE  ( w u a s -- )    Save binary file to file name w on bank u starting at address a for s bytes
 BLOAD ( w u a -- )    Load binary file from file name w on bank u into address u
 I ( -- ) Loop counter
Words ready to use
------------------
 + ( u u -- u )    Add two numbers and push result   | INT DONE
 - ( u1 u2 -- u )    Subtract u2 from u1 and push result  | INT DONE
 / ( u1 u2 -- result remainder )     Divide u1 by u2 and push result | INT DONE
 * ( u1 u2 -- u )     Multiply TOS and push result | INT DONE
 DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE
 . ( u -- )    Display TOS   |DONE
DROP ( w -- )   drop the TOS item   |DONE
2DROP ( w w -- )    Double drop | DONE
 @ ( w -- ) Push onto TOS byte stored at address   | DONE
C@  ( w -- ) Push onto TOS byte stored at address   |DONE
! ( x w -- ) Store x at address w      | DONE
C!  ( x w -- ) Store x at address w  | DONE
< ( u1 u2 -- f ) True if u1 is less than u2 | DONE
> ( u1 u2 -- f ) True if u1 is greater than u2 | DONE
= ( u1 u2 -- f ) True if u1 equals u2 | DONE
CLS ( -- ) clear frame buffer    |DONE
DRAW ( -- ) Draw contents of current frame buffer  | DONE
DUMP ( x --  ) With address x display dump   |DONE
CDUMP ( -- ) continue dump of memory from DUMP |  DONE
DEPTH ( -- u ) Push count of stack | DONE
 CURSOR ( u1 u2 -- )  Set next output via . or emit at row u2 col u1 |DONE
 WAITK ( -- w )      wait for keypress TOS is key press | DONE
HOME ( -- )    Reset the current cursor for output to home |DONE
OVER ( n1 n2 -- n1 n2 n1 )  Copy one below TOS onto TOS | DONE
 PAUSEMS ( n -- )  Pause for n millisconds | DONE
 PAUSES ( n -- )  Pause for n seconds | DONE
 SPACE (  -- c ) Push the value of space onto the stack as a string  | DONE
 MONITOR ( -- ) Display system breakpoint/monitor | DONE
Words still left to do
----------------------
  EMIT ( u -- )        Display ascii character  TOS   |
SWAP ( w1 w2 -- w2 w1 )    Swap top two items (of whatever type) on TOS
IF ( w -- f )     If TOS is true exec code following before??
THEN ( -- )     control????
ELSE ( -- )     control???
DO ( u1 u2 -- )   Loop starting at u2 with a limit of u1
LOOP ( -- )     Current loop end marker
: ( -- )         Create new word | WIP
; ( -- )     Terminate new word
2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  
2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items
0< ( u -- f ) Push true if u is less than o | CANT DO UNTIL FLOAT
0= ( u -- f ) Push true if u equals 0 | TEST NO DEBUG
CALL ( w -- w  ) machine code call to address w  push the result of hl to stack
IN ( u1-- u )    Perform z80 IN with u1 being the port number. Push result to TOS | TO TEST
 OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | TO TEST
DIR ( u -- w... u )   Using bank number u push directory entries from persistent storage as w with count u 
SAVE  ( w u -- )    Save user word memory to file name w on bank u
 LOAD ( w u -- )    Load user word memory from file name w on bank u
KEY ( -- w f )      scan for keypress but do not wait true if next item on stack is key press
ACCEPT ( -- w )    Prompt for text input and push pointer to string | TEST
 ROT (  -- )  
 SPACES ( u -- str )  A string of u spaces is pushed onto the stack
 CONCAT ( s1 s2 -- s3 ) A string of u spaces is pushed onto the stack
 MIN (  u1 u2 -- u3 ) Whichever is the smallest value is pushed back onto the stack | TEST NO DEBUG
 MAX (  u1 u2 -- u3 )  Whichever is the largest value is pushed back onto the stack | TEST NO DEBUG
 FIND (  -- )  
 LEN (  u1 -- u2 ) Push the length of the string on TOS
 CHAR (  -- )  
 RND (  -- )  
 WORDS (  -- )   List the system and user word dict
 UWORDS (  -- )   List user word dict
 SPIO ( u1 u2 -- ) Send byte u1 to SPI device u2 |  WIP
 SPII ( u1 -- ) Get a byte from SPI device u2 |  WIP
 SCROLL ( u1 c1 -- ) Scroll u1 lines/chars in direction c1 | WIP
 BP ( u1 -- ) Enable or disable break point monitoring | TEST
 MALLOC ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | TEST
 FREE ( u --  ) Free memory block from malloc given u address  | TEST
 STRLEN ( u1 -- Using given address u1 push then zero term length string to TOS )   |
 STRCPY ( u1 u2 -- Copy string u2 to u1 )   |
BSAVE  ( w u a s -- )    Save binary file to file name w on bank u starting at address a for s bytes
 BLOAD ( w u a -- )    Load binary file from file name w on bank u into address u
 I ( -- ) Loop counter