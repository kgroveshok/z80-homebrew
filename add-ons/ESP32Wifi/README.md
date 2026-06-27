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




zstr - a zero terminated string
pool - a pool id byte
count - a byte count
byte - single byte
word - a 16bit word little edian

SPI Command Byte(s)            Action
-------------------            ------


0x00-0x0F                      Reserved for future support of EEPROM storage protocol to allow for paged onboard direct file storage

D 0x02             STORAGE_WRITE
D 0x03             STORAGE_READ 
D 0x06              STORAGE_WREN

0x09             STORAGE_SYNC    Writes are cached in ram until the STORAGE_SYNC is used to flush to storage

D 0x10            ESP_POWERED               Device active. Comand is sent, if the device is not powered up then zero will be returned. Any other
                               value indicates the device is functioning
0x11             STORAGE_PAGE              Future set paged current EEPROM bank to use above
0x12             SLEEP              Sleep. Send the ESP into a sleep/low power state and wait for a wake up on the SPI CE line.
0x13             RESTART              Restart ESP
0x14 byte             ESP_CONFIG            ESP Configuration bit mask: abcdefgg  
                                                gg - Debug level
                                                 f - Enable/Disable web server
0x15             ESP_CONSOLE           Switch to ESP console control. Z80 device no longer can send and once console is complete. Returns control back.
                                         Use '?' on uart or usb for console commands.

Wifi:

D 0x20  zstr           SET_SSID          Wifi SSID for current profile. Receive a zero terminated string for the SSID to connect to
D 0x21  zstr           SET_PASS          Wifi Password for current profile. Receive a zero terminated string for the password to connect with.
D 0x22                 GET_IP          Get Local IP
0x23             
0x24  byte          SELECT_PROF          Select wifi profile id
0x25                 LIST_PROF          List wifi profiles
0x26                 WIFI_CONNECT          Connect using above details
0x27                 WIFI_DISCON          Close down wifi



Internet:

D 0x30  zstr           SET_ITARG          Set current target IP address/Socket for connections
0x31                
0x32                 
D 0x33  zstr      SEND_ICON          Send request to current connect. Content will be buffered to the current pool id
D 0x34  byte           PUTC_ICON          Send a single byte to the current connection
D 0x35                 GETC_ICON          Get a single byte from the current connection
0x36 zstr            CREATE_ICON        Set internet connection profile
0x37 zstr            SELECT_ICON        Select the internet connection profile
0x38                 LIST_ICON          List internet connection profiles


Buffers:

D 0x40           GET_POOL          Get all of the pool contents  until zero term string encountered
D 0x41  zstr           PUT_POOL          Add zstr to pool id buffer for later access
D 0x42  byte           SELECT_POOL       set current pool id
D 0x43               CLR_POOL          Clear current pool
0x44  count         CONSUME_POOL          Get the next 'count' bytes from the given pool id, a zero count will get until zero term string encountered
D 0x45                UART_OUT_POOL         Send the contents of the pool to the UART
D 0x46                UART_IN_POOL          Append to contents of the pool from the UART until CR/LF
TODO Not working
0x47                  LIST_POOL           Return a list of the pool ids present (and their sizes?)

TODO BUG cant seem to send more than 13 chars via 0x41. Appears adding more than 13 chars to pool causes the corruption



C like files:

0x50  zstr          FILE_NAME           Set current file name to use
0x51  byte            FILE_MODE           Set file mode
0x52                           
0x53  word            FILE_SEEK         Seek to position
0x54  zstr            FILE_PUT         Write string to file
0x55  count           FILE_GET         Read from current position the number of bytes given. Zero until end of zero term string
0x56                  FILE_CLOSE         Close file
0x57                  LIST_FILE         Get file list
0x58  zstr            ERA_FILE         Delete file given
0x59  zstr zstr       REN_FILE         Rename file from to


UART:

D 0x60 byte           PUTC           Send a byte on the UART
0x61                GETC           Get byte from the UART



Chat:

0x70 zstr1 zstr2    CHAT_PUT              Send the text zstr2 to the chat socket at ip address zstr1 and store in chat buffer
0x71                CHAR_GET           Get next zstr from chat buffer






