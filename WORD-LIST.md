Words List


------------------


 EXEC ( u -- )    Execs the string on TOS as a FORTH expression | TO TEST


 DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE


 SWAP ( w1 w2 -- w2 w1 )    Swap top two items  on TOS | DONE


 : ( -- )         Create new word | DONE


 ; ( -- )     Terminate new word and return exec to previous exec level | DONE


 DROP ( w -- )   drop the TOS item   | DONE


 2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  | DONE


 2DROP ( w w -- )    Double drop | DONE


 2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items


 @ ( w -- ) Push onto TOS byte stored at address   | DONE


 C@  ( w -- ) Push onto TOS byte stored at address   | DONE


 ! ( x w -- ) Store x at address w      | DONE


 C!  ( x w -- ) Store x at address w  | DONE


 CALL ( w -- w  ) machine code call to address w  push the result of hl to stack | TO TEST


 DEPTH ( -- u ) Push count of stack | DONE


 OVER ( n1 n2 -- n1 n2 n1 )  Copy one below TOS onto TOS | DONE


 PAUSEMS ( n -- )  Pause for n millisconds | DONE


 PAUSE ( n -- )  Pause for n seconds | DONE


 ROT ( u1 u2 u3 -- u2 u3 u1 ) Rotate top three items on stack | DONE


 WORDS (  -- )   List the system and user word dict


 UWORDS (  -- )   List user word dict


 BP ( u1 -- ) Enable or disable break point monitoring | DONE


 MONITOR ( -- ) Display system breakpoint/monitor | DONE


 MALLOC ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | TEST


 FREE ( u --  ) Free memory block from malloc given u address  | TEST


 LIST ( uword -- )    List the code to the word on TOS


 FORGET ( uword -- )    Forget the uword on TOS


 NOP (  --  ) Do nothing | DONE


 ( ( -- )  Start of comment | DONE


 ) ( -- )  End of comment |  DONE 


 NOTE ( ud uf --  )  Plays a note of frequency uf for the duration of ud millseconds |


 IN ( u1-- u )    Perform z80 IN with u1 being the port number. Push result to TOS | TO TEST


 OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | TO TEST


 SPIO ( u1 u2 -- ) Send byte u1 to SPI device u2 |  WIP


 SPII ( u1 -- ) Get a byte from SPI device u2 | WIP


 BANK ( u1 -- ) Select Serial EEPROM Bank Device at bank address u1 1-5 (disables CARTDEV). Set to zero to disable storage. | DONE


 CARTDEV ( u1 -- ) Select cart device 1-8 (Disables BANK). Set to zero to disable devices. |  DONE


  FB ( u -- )        Select frame buffer ID u (1-3)  |  DONE


  EMIT ( u -- )        Display ascii character  TOS   | DONE


 .- ( u -- )    Display TOS replacing any dashes with spaces. Means you dont need to wrap strings in double quotes!   | DONE


 . ( u -- )    Display TOS   | DONE


 CLS ( -- ) clear frame buffer    | DONE


 DRAW ( -- ) Draw contents of current frame buffer  | DONE


 DUMP ( x --  ) With address x display dump   | DONE


 CDUMP ( -- ) continue dump of memory from DUMP | DONE


 AT ( u1 u2 -- )  Set next output via . or emit at row u2 col u1 | DONE


 HOME ( -- )    Reset the current cursor for output to home | DONE


 SPACE (  -- c ) Push the value of space onto the stack as a string  | DONE


 SPACES ( u -- str )  A string of u spaces is pushed onto the stack | TO TEST


 SCROLL ( u1 c1 -- ) Scroll u1 lines/chars in direction c1 | WIP


 AT? ( u1 u2 -- n )  Push to stack ASCII value at row u2 col u1 | DONE


 ADSP ( u1 --  )  Enable/Disable Auto screen updates (SLOW). If off, use DRAW to refresh. Default is on. $0003 will enable direct screen writes (TODO) | DONE


 MENU ( u1....ux n ut -- n ) Create a menu. Ut is the title, n is the number of menu items on stack. Push number selection to TOS |


 IF ( w -- f )     If TOS is true exec code following up to THEN - Note: currently not supporting ELSE or nested IF | DONE


 THEN ( -- )    Does nothing. It is a marker for the end of an IF block | DONE


 ELSE ( -- )   Not supported - does nothing


 DO ( u1 u2 -- )   Loop starting at u2 with a limit of u1 | DONE


 LOOP ( -- )     Increment and test loop counter  | DONE


 I ( -- ) Current loop counter | DONE


 -LOOP ( -- )    Decrement and test loop counter  | DONE


 REPEAT ( --  ) Start REPEAT...UNTIL loop  | DONE


 UNTIL ( u -- ) Exit REPEAT...UNTIL loop if TOS is false  | DONE


 KEY ( -- w f )      scan for keypress but do not wait true if next item on stack is key press


 WAITK ( -- w )      wait for keypress TOS is key press | DONE


 ACCEPT ( -- w )    Prompt for text input and push pointer to string | TEST


 0< ( u -- f ) Push true if u is less than o | CANT DO UNTIL FLOAT


 0= ( u -- f ) Push true if u equals 0 | TEST NO DEBUG


 < ( u1 u2 -- f ) True if u1 is less than u2 | DONE


 > ( u1 u2 -- f ) True if u1 is greater than u2 | DONE


 = ( u1 u2 -- f ) True if u1 equals u2 | DONE


 + ( u u -- u )    Add two numbers and push result   | INT DONE


 - ( u1 u2 -- u )    Subtract u2 from u1 and push result  | INT DONE


 / ( u1 u2 -- result remainder )     Divide u1 by u2 and push result | INT DONE


 * ( u1 u2 -- u )     Multiply TOS and push result | INT DONE


 MIN (  u1 u2 -- u3 ) Whichever is the smallest value is pushed back onto the stack | TEST NO DEBUG


 MAX (  u1 u2 -- u3 )  Whichever is the largest value is pushed back onto the stack | TEST NO DEBUG


 RND16 (  -- n ) Generate a random 16bit number and push to stack | DONE


 RND8 (  -- n ) Generate a random 8bit number and push to stack | DONE


 DIR ( u -- lab id ... c t )   Using bank number u push directory entries from persistent storage as w with count u  | DONE


 SAVE  ( w u -- )    Save user word memory to file name w on bank u


 LOAD ( w u -- )    Load user word memory from file name w on bank u


 BSAVE  ( w u a s -- )    Save binary file to file name w on bank u starting at address a for s bytes


 BLOAD ( w u a -- )    Load binary file from file name w on bank u into address u


 SEO ( u1 u2 -- ) Send byte u1 to Serial EEPROM device at address u2 | DONE


 SEI ( u2 -- u1 ) Get a byte from Serial EEPROM device at address u2 | DONE


 FFREE ( -- n )  Gets number of free file blocks on current storage bank | DONE


 SIZE ( u -- n )  Gets number of blocks used by file id u and push to stack | DONE


 CREATE ( u -- n )  Creates a file with name u on current storage bank and pushes the file id number to TOS | DONE


 APPEND ( u n --  )  Appends data u to file id on current storage bank | DONE


 ERA ( n --  )  Deletes all data for file id n on current storage bank | DONE


 OPEN ( n --  )  Sets file id to point to first data page for subsequent READs - CURRENTLY n IS IGNORED AND ONLY ONE STREAM IS SUPPORTED | DONE


 READ ( n -- n  )  Reads next page of file id and push to stack | TESTING - Crashes on second read


 EOF ( n -- u )  Returns EOF logical state of file id n - CURRENTLY n IS IGNORED AND ONLY ONE STREAM IS SUPPORTED | DONE


 FORMAT (  --  )  Formats the current bank selected (NO PROMPT!) | DONE


 LABEL ( u --  )  Sets the storage bank label to string on top of stack  | DONE


 LABELS (  -- b n .... c  )  Pushes each storage bank labels (n) along with id (b) onto the stack giving count (c) of banks  | DONE


 CONCAT ( s1 s2 -- s3 ) A string of u spaces is pushed onto the stack


 FIND (  -- )  


 LEN (  u1 -- u2 ) Push the length of the string on TOS | DONE


 CHAR ( u -- n ) Get the ascii value of the first character of the string on the stack | TO TEST


 STRLEN ( u1 -- Using given address u1 push then zero term length string to TOS )   |


 STRCPY ( u1 u2 -- Copy string u2 to u1 )   |


Words ready to use


------------------


 DUP ( u -- u u )     Duplicate whatever item is on TOS | DONE


 SWAP ( w1 w2 -- w2 w1 )    Swap top two items  on TOS | DONE


 : ( -- )         Create new word | DONE


 ; ( -- )     Terminate new word and return exec to previous exec level | DONE


 DROP ( w -- )   drop the TOS item   | DONE


 2DUP ( w1 w2 -- w1 w2 w1 w2 ) Duplicate the top two items on TOS  | DONE


 2DROP ( w w -- )    Double drop | DONE


 @ ( w -- ) Push onto TOS byte stored at address   | DONE


 C@  ( w -- ) Push onto TOS byte stored at address   | DONE


 ! ( x w -- ) Store x at address w      | DONE


 C!  ( x w -- ) Store x at address w  | DONE


 DEPTH ( -- u ) Push count of stack | DONE


 OVER ( n1 n2 -- n1 n2 n1 )  Copy one below TOS onto TOS | DONE


 PAUSEMS ( n -- )  Pause for n millisconds | DONE


 PAUSE ( n -- )  Pause for n seconds | DONE


 ROT ( u1 u2 u3 -- u2 u3 u1 ) Rotate top three items on stack | DONE


 BP ( u1 -- ) Enable or disable break point monitoring | DONE


 MONITOR ( -- ) Display system breakpoint/monitor | DONE


 NOP (  --  ) Do nothing | DONE


 ( ( -- )  Start of comment | DONE


 ) ( -- )  End of comment |  DONE 


 BANK ( u1 -- ) Select Serial EEPROM Bank Device at bank address u1 1-5 (disables CARTDEV). Set to zero to disable storage. | DONE


 CARTDEV ( u1 -- ) Select cart device 1-8 (Disables BANK). Set to zero to disable devices. |  DONE


  FB ( u -- )        Select frame buffer ID u (1-3)  |  DONE


  EMIT ( u -- )        Display ascii character  TOS   | DONE


 .- ( u -- )    Display TOS replacing any dashes with spaces. Means you dont need to wrap strings in double quotes!   | DONE


 . ( u -- )    Display TOS   | DONE


 CLS ( -- ) clear frame buffer    | DONE


 DRAW ( -- ) Draw contents of current frame buffer  | DONE


 DUMP ( x --  ) With address x display dump   | DONE


 CDUMP ( -- ) continue dump of memory from DUMP | DONE


 AT ( u1 u2 -- )  Set next output via . or emit at row u2 col u1 | DONE


 HOME ( -- )    Reset the current cursor for output to home | DONE


 SPACE (  -- c ) Push the value of space onto the stack as a string  | DONE


 AT? ( u1 u2 -- n )  Push to stack ASCII value at row u2 col u1 | DONE


 ADSP ( u1 --  )  Enable/Disable Auto screen updates (SLOW). If off, use DRAW to refresh. Default is on. $0003 will enable direct screen writes (TODO) | DONE


 IF ( w -- f )     If TOS is true exec code following up to THEN - Note: currently not supporting ELSE or nested IF | DONE


 THEN ( -- )    Does nothing. It is a marker for the end of an IF block | DONE


 DO ( u1 u2 -- )   Loop starting at u2 with a limit of u1 | DONE


 LOOP ( -- )     Increment and test loop counter  | DONE


 I ( -- ) Current loop counter | DONE


 -LOOP ( -- )    Decrement and test loop counter  | DONE


 REPEAT ( --  ) Start REPEAT...UNTIL loop  | DONE


 UNTIL ( u -- ) Exit REPEAT...UNTIL loop if TOS is false  | DONE


 WAITK ( -- w )      wait for keypress TOS is key press | DONE


 < ( u1 u2 -- f ) True if u1 is less than u2 | DONE


 > ( u1 u2 -- f ) True if u1 is greater than u2 | DONE


 = ( u1 u2 -- f ) True if u1 equals u2 | DONE


 + ( u u -- u )    Add two numbers and push result   | INT DONE


 - ( u1 u2 -- u )    Subtract u2 from u1 and push result  | INT DONE


 / ( u1 u2 -- result remainder )     Divide u1 by u2 and push result | INT DONE


 * ( u1 u2 -- u )     Multiply TOS and push result | INT DONE


 RND16 (  -- n ) Generate a random 16bit number and push to stack | DONE


 RND8 (  -- n ) Generate a random 8bit number and push to stack | DONE


 DIR ( u -- lab id ... c t )   Using bank number u push directory entries from persistent storage as w with count u  | DONE


 SEO ( u1 u2 -- ) Send byte u1 to Serial EEPROM device at address u2 | DONE


 SEI ( u2 -- u1 ) Get a byte from Serial EEPROM device at address u2 | DONE


 FFREE ( -- n )  Gets number of free file blocks on current storage bank | DONE


 SIZE ( u -- n )  Gets number of blocks used by file id u and push to stack | DONE


 CREATE ( u -- n )  Creates a file with name u on current storage bank and pushes the file id number to TOS | DONE


 APPEND ( u n --  )  Appends data u to file id on current storage bank | DONE


 ERA ( n --  )  Deletes all data for file id n on current storage bank | DONE


 OPEN ( n --  )  Sets file id to point to first data page for subsequent READs - CURRENTLY n IS IGNORED AND ONLY ONE STREAM IS SUPPORTED | DONE


 EOF ( n -- u )  Returns EOF logical state of file id n - CURRENTLY n IS IGNORED AND ONLY ONE STREAM IS SUPPORTED | DONE


 FORMAT (  --  )  Formats the current bank selected (NO PROMPT!) | DONE


 LABEL ( u --  )  Sets the storage bank label to string on top of stack  | DONE


 LABELS (  -- b n .... c  )  Pushes each storage bank labels (n) along with id (b) onto the stack giving count (c) of banks  | DONE


 LEN (  u1 -- u2 ) Push the length of the string on TOS | DONE


Words still left to do


----------------------


 EXEC ( u -- )    Execs the string on TOS as a FORTH expression | TO TEST


 2SWAP ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) Swap top pair of items


 CALL ( w -- w  ) machine code call to address w  push the result of hl to stack | TO TEST


 WORDS (  -- )   List the system and user word dict


 UWORDS (  -- )   List user word dict


 MALLOC ( u -- u ) Allocate u bytes of memory space and push the pointer TOS  | TEST


 FREE ( u --  ) Free memory block from malloc given u address  | TEST


 LIST ( uword -- )    List the code to the word on TOS


 FORGET ( uword -- )    Forget the uword on TOS


 NOTE ( ud uf --  )  Plays a note of frequency uf for the duration of ud millseconds |


 IN ( u1-- u )    Perform z80 IN with u1 being the port number. Push result to TOS | TO TEST


 OUT ( u1 u2 -- ) Perform Z80 OUT to port u2 sending byte u1 | TO TEST


 SPIO ( u1 u2 -- ) Send byte u1 to SPI device u2 |  WIP


 SPII ( u1 -- ) Get a byte from SPI device u2 | WIP


 SPACES ( u -- str )  A string of u spaces is pushed onto the stack | TO TEST


 SCROLL ( u1 c1 -- ) Scroll u1 lines/chars in direction c1 | WIP


 MENU ( u1....ux n ut -- n ) Create a menu. Ut is the title, n is the number of menu items on stack. Push number selection to TOS |


 ELSE ( -- )   Not supported - does nothing


 KEY ( -- w f )      scan for keypress but do not wait true if next item on stack is key press


 ACCEPT ( -- w )    Prompt for text input and push pointer to string | TEST


 0< ( u -- f ) Push true if u is less than o | CANT DO UNTIL FLOAT


 0= ( u -- f ) Push true if u equals 0 | TEST NO DEBUG


 MIN (  u1 u2 -- u3 ) Whichever is the smallest value is pushed back onto the stack | TEST NO DEBUG


 MAX (  u1 u2 -- u3 )  Whichever is the largest value is pushed back onto the stack | TEST NO DEBUG


 SAVE  ( w u -- )    Save user word memory to file name w on bank u


 LOAD ( w u -- )    Load user word memory from file name w on bank u


 BSAVE  ( w u a s -- )    Save binary file to file name w on bank u starting at address a for s bytes


 BLOAD ( w u a -- )    Load binary file from file name w on bank u into address u


 READ ( n -- n  )  Reads next page of file id and push to stack | TESTING - Crashes on second read


 CONCAT ( s1 s2 -- s3 ) A string of u spaces is pushed onto the stack


 FIND (  -- )  


 CHAR ( u -- n ) Get the ascii value of the first character of the string on the stack | TO TEST


 STRLEN ( u1 -- Using given address u1 push then zero term length string to TOS )   |


 STRCPY ( u1 u2 -- Copy string u2 to u1 )   |


