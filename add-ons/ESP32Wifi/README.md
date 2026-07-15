ESP32Wifi
---------

With the 4.5 board revision I've added an ESP32 Zero device to provide a number of features. It is communicated via the SPI device 1. Device 0 
continues support for SPINet in case that is useful for wired networking once the code base has been resolved.

As this device is a one to one connection for an IP network, that simplifies the range of features it needs to have.


Programming can be one of three options on the ESP.
1. Using C via the main SDK
2. Arduino code
3. ESPForth


I will give ESPForth a go first. A bit of a learning curve but considering the OS is in Forth then why not have all of it in the same
language? We will see. :-) 

As it happens, had issues with ESPForth and the ESP S3 Zero I'm using. Wouldn't conenct to Wifi with: wifi z" <ssid>" z" <pass>" login

Would just hang. The Arduino IDE wifi SDK is working so will be using that instead as the code is easy to port between that and Forth. May revisit as some time.



* TODO Could add mailbox on web server
* TODO Can I get esp to send email
* TODO Set output pin to input to force high imped and to not corrupt the SPI bus once done.
* TODO setup inter-esp comms for a mesh network to share files
* TODO Put a scope on the SPI lines and decode what is going wrong with EEPROM support




SPI Command Protocol
--------------------

The revised protocol functions at two levels. There is a main class of command byte e.g. wifi services, and then a sub command byte which gives the function.

Please look at the esp-spi-op.h file for the function list. Once it has become stable then a more detailed version will be included here.


ESP Command Operators
----------------------

To aid in removing duplicate code I have implemented an "interpreter" that has a number of simple op codes (see esp-z80-op.h) that form simple features common to all commands e.g. get a byte, put a byte, store something, etc

Likewise from above, once the OP code list has become stable then there will be more detail here. But the naming should be fairly easy to understand.





