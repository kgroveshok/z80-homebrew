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


zstr - a zero terminated string
pool - a pool id byte
count - a byte count
byte - single byte
word - a 16bit word little edian

SPI Command Byte(s)            Action
-------------------            ------


0x00-0x0F                      Reserved for future support of EEPROM storage protocol to allow for paged onboard direct file storage

0x10                           Device active. Comand is sent, if the device is not powered up then zero will be returned. Any other
                               value indicates the device is functioning
0x11                           Future set paged current EEPROM bank to use above
0x12                           Sleep. Send the ESP into a sleep/low power state and wait for a wake up on the SPI CE line.

Wifi:

0x20  zstr                     Wifi SSID. Receive a zero terminated string for the SSID to connect to
0x21  zstr                     Wifi Password. Receive a zero terminated string for the password to connect with.
0x22  zstr                     Local IP. Set the local LAN IP address.
0x23  zstr                     Set netmask.
0x24  zstr                     Set gateway.
0x25  zstr                     Set DNS.
0x26                           Connect using above details
0x27                           Close down wifi


Internet:

0x30  zstr                     Set current IP address/Socket for connections
0x31                           Open the connection
0x32                           Close the connection
0x33  pool zstr                Send request to current connect. Content will be buffered to the pool id
0x34  byte                     Send a single byte to the current connection
0x35                           Get a single byte from the current connection


Buffers:

0x40  pool count               Get the next 'count' bytes from the given pool id, a zero count will get until zero term string encountered
0x41  pool zstr                Add zstr to pool id buffer for later access
0x42  pool                     Clear given pool id


C like files:

0x50  zstr                     Set current file name to use
0x51                           Set file for read
0x52                           Set file to write/append
0x53  word                     Seek to position
0x54  zstr                     Write string to file
0x55  count                    Read from current position the number of bytes given. Zero until end of zero term string
0x56                           Close file
0x57                           Get file list
0x58  zstr                     Delete file given
0x59  zstr zstr                Rename file from to


UART:

0x60 byte                      Send a byte on the UART
0x61                           Get byte from the UART



Chat:

0x70 zstr1 zstr2               Send the text zstr2 to the chat socket at ip address zstr1 and store in chat buffer
0x71                           Get next zstr from chat buffer






