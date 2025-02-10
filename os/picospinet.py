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
#
# Commands to send to client:
#    ATD<user>:<password>@<ip>  - Connect to a host with options user, password and IP
#    D<string> - Send a string to the client
#
# All clocked in data from client to the server (z80) to be pushed to stack on the z80

from machine import Pin, SoftSPI
import time

DI=Pin(0,mode=Pin.IN)      #pico pin 21  eprom 5
DO=Pin(1,mode=Pin.OUT)    # pico pin 22   eprom 2
SCLK=Pin(2,mode=Pin.IN)   # pico pin 24  eprom 6
CE=Pin(3,mode=Pin.IN)     # pico pin 25  eprom 1

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


        while(SCLK.value() ) ;    # wait for high to low to clock out
        while(!SCLK.value() ) ;    # wait for low to high clock out and move on

        #time.sleep(0.025)
        #print("clock low")

def clockbytein():
   # msb first
    b=""
    for n in range(7,-1,-1):
        #SCLK.high()
        while not SCLK.value() :
                print("clock is low")
                pass
        print("clock high")

        #print("clock low")
        bit=DI.value()
#        SCLK.low()
        while SCLK.value() :
                pass
        print("clock low")
        bit=DI.value()
        if bit  :
            print( " bit "+str(n)+" is high   1")
            b=b+"1"
            
        else:
            print( " bit "+str(n)+" is low 0")
            b=b+"0"

    print(b)

        


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


while(1):
    if CE.value() == 0 :
        # chip has been selected

        # test data
        a=clockbytein()
        print( a )        



