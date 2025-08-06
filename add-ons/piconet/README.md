PicoSPINet
----------


* PicoSPINet - A Pico device which provides 5/6 SPI network ports allowing intercoms between nodes and act as an internet gateway.
   - Provides NTP services
   - Internode communications
   - Internet communications
   - Storage services
   - Powered nodes
   - Emulates the EEPROM used for onboard storage with node specific and common storage banks


More to come with PCB design etc


Demo of the prototype:


[https://youtu.be/h5VUJ3j9RmY]



Example comms
-------------

* Connecting to a remote server

 On remote machine:    nc -klv 192.168.9.101 8000


 On Mega:

    * Create socket connection

    $22 spio "192.168.9.101:8000" spistrz 

    * Send ASCII char $65

    $20 spio $65 spio

    * Get back a character from the remote machine

    $21 spio $01 pause spii emit




