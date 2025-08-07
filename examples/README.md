Examples
--------

There is a backup.txt file here which is a recent dump over PicoSPINet of my current development of words for use with the addons.

Of point is at the bottom with the various UBI... words which is incremental changes I made to dump the user dict over PicoSPINet to my laptop.

Each change I made I appended to a file and made it auto load so I can test it and not have to write it down. Now I have reached the working
version of UBIALL which works to connect to my laptop and dump the source of all current user words. Each word is displayed and then sent:

 ```
 piconet           <- Switches on the SPI device
 "192.168.9.110:8000" soccon       <- Tell PicoSPINet to make a socket connection to my laptop
 uwords ubiall                <- Push al user words to stack and then iterate over the list sending them via the socket connection via SPI
 ```




