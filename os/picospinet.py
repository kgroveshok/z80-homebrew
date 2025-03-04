# Using my simulation of spi via the pico which is and easier change/test cycle than asm
# Watch for chip select and then listen to the SPI bus for commands

# CE needed for network access

# Network support traffic
#
# Most retro internet addons pretend to be a modem. Worth trying to emulate to some extent with SPI
# though of course because SPI is a special format and the platform doesn't provide serial support
# anyway, don't need to be particuarly standard. Just a bit obvious.
#
# SPI Server is Z80
# 
# Data commands:
#
# CE select puts client (pico) on listen
# Byte:
#    01 - Ask client to clk out buffered data until zero term appears on stream
#    02 - Tell client to receive data to act on
#
# use groups of pi pins to connect multiple machines and have the pi as hub
#
#
# have protocol of from to comms packet with 0 for internet????

#
#
# Commands to send to client:
#    ATD<user>:<password>@<ip>  - Connect to a host with options user, password and IP
#    D<string> - Send a string to the client
#
# All clocked in data from client to the server (z80) to be pushed to stack on the z80

from machine import Pin
import time

DI=Pin(2,mode=Pin.IN)      #pico pin 1
DO=Pin(1,mode=Pin.OUT)    # pico pin 2
SCLK=Pin(0,mode=Pin.IN)   # pico pin 4
CE=Pin(3,mode=Pin.IN)     # pico pin 5

READ=1   # ; Read data from memory array beginning at selected address
WRITE=2  #;  Write data to memory array beginning at selected address


def clockbyteout(byte):
   # msb first

    print("byte "+str(byte))
    for n in range(7,-1,-1):
        
        #print("clock high")
        if ( byte & ( 1<<n)) :
            DI.high()
            #print( " bit "+str(n)+" high  1")
            
        else:
            DI.low()
            #print( " bit "+str(n)+" low   0")
        #time.sleep(0.025)


        while(SCLK.value() ):
            pass     # wait for high to low to clock out
        #time.sleep(0.025)
        while( not SCLK.value() ):
            pass # wait for low to high clock out and move on

        #time.sleep(0.025)
        #print("clock low")

def clockbytein():
   # msb first
    b=""
    for n in range(7,-1,-1):
        #SCLK.high()
        #print("clock is low")
        while not SCLK.value() :
                
                pass
        #print("clock high")

        #print("clock low")
        bit=DI.value()
#        SCLK.low()
        while SCLK.value() :
                pass
        #time.sleep(0.025)
        #print("clock low")
        bit=DI.value()
        if bit  :
        #    print( " bit "+str(n)+" is high   1")
            b=b+"1"
        #    
        else:
        #    print( " bit "+str(n)+" is low 0")
            b=b+"0"

    print(b)

    return b 


def writebyte(byte,addressh,addressl):
       
    #; initi write mode
    #;
    #;CS low
    #

    print("* write "+str(byte)+" to "+str(addressl))
    CE.low()
    print("ce low")
    #;clock out wren instruction

    print("* wren")
    clockbyteout(WREN)

    #;cs high to enable write latch

    CE.high()

    print("ce high")
    #;
    #; intial write data
    #;
    #; cs low
    #

    CE.low()
    #print("ce low")

    #; clock out write instruction
    #
    print("* write")
    clockbyteout(WRITE)

    #; clock out address (depending on address size)
    #
    print("* address")
    clockbyteout(addressh)
    clockbyteout(addressl)

    #; clock out byte(s) for page

    print("* data")
    clockbyteout(byte)

    CE.high()
    print("ce high")


def readbyte(addressh,addressl):
    print("read "+str(addressl))
       
    #; initi write mode
    #;
    #;CS low
    #

    CE.low()
    #print("ce low")
    #;clock out read instruction

    clockbyteout(READ)


    #; clock out address (depending on address size)
    #

    clockbyteout(addressh)
    clockbyteout(addressl)

    #; clock in byte(s) for page

    clockbytein()

    CE.high()
    print("ce high")


fromserver=""
gotcmd=False
celast=False
while(1):
    cenow=CE.value() 
    if cenow != celast:
        celast=cenow
            
        if celast == 0 :
            print( "CE low")
        else:
            print( "CE high")
        
    if CE.value() == 0 :
        print( "CE low")
        a=clockbytein()
        print(a)
        # chip has been selected

        # test data
        
     #   if a == 13:
      #      gotcmd=True
      #  else:
#            fromserver=fromserver+a
    
    # code here for buffering data in and out

    #if gotcmd:
     #   print("Exec command: "+fromserver)
      #  fromserver=""

      #  gotcmd=False


# eof

