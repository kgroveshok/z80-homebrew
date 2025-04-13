# simulate spi via the pico which is and easier change/test cycle than asm
from machine import Pin, SoftSPI
import time

#DI=Pin(0,mode=Pin.IN)      #pico pin 21  eprom 5
#DO=Pin(1,mode=Pin.OUT)    # pico pin 22   eprom 2
#SCLK=Pin(2,mode=Pin.IN)   # pico pin 24  eprom 6
CE=Pin(3,mode=Pin.IN)     # pico pin 25  eprom 1
spi=SoftSPI(baudrate=100_000, sck=Pin(2), mosi=Pin(0), miso=Pin(1), polarity=1, phase=0)

#CE.high()
#SCLK.low()
#DI.low()

READ=3   # ; Read data from memory array beginning at selected address
WRITE=2  #;  Write data to memory array beginning at selected address
WREN=6   #;  Set the write enable latch (enable write operations)


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
        SCLK.high()
        SCLK.low()
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

spi.init()

#while CE.value() :
        #pass

#print("hello")

a=b'\x00'
while a == b'\x00' or a==b'\xff':
    #while CE.value() :
    #    pass

#    while not CE.value() :
        #print("clockin")        
        #clockbytein()
        #print( "DI " + str(DI.value())+ " DO " + str(DO.value()))
        a=spi.read(1)
        #print("DI "+str(a))
        #print("clockindone")

print(a)
print("done")

#writebyte(1,0,1)
##writebyte(2,0,2)
#writebyte(2,0,2)
#writebyte(3,0,3)
#writebyte(0,0,4)
#writebyte(ord('H'),0,5)
##writebyte(ord('H'),0,5)
#writebyte(ord('e'),0,6)
##writebyte(ord('e'),0,6)
#writebyte(ord('l'),0,7)
#writebyte(ord('l'),0,8)
#writebyte(ord('o'),0,9)
#writebyte(ord('!'),0,10)


#readbyte(0,1)
#readbyte(0,2)
#readbyte(0,3)
#readbyte(0,5)
#readbyte(0,6)
#readbyte(0,7)



#; init storage pio
#
#
#store_read_ins: equ 000000011b   ; Read data from memory array beginning at selected address
#store_write_ins: equ 000000010b  ;  Write data to memory array beginning at selected address
#store_wren_ins: equ 000000110b   ;  Set the write enable latch (enable write operations)
#
#; INSTRUCTION SET
#; READ 0000 0011 Read data from memory array beginning at selected address
#; WRITE 0000 0010 Write data to memory array beginning at selected address
#; WREN 0000 0110 Set the write enable latch (enable write operations)
#; WRDI 0000 0100 Reset the write enable latch (disable write operations)
#; RDSR 0000 0101 Read STATUS register
#; WRSR 0000 0001 Write STATUS register
#; PE 0100 0010 Page Erase – erase one page in memory array
#; SE 1101 1000 Sector Erase – erase one sector in memory array
#; CE 1100 0111 Chip Erase – erase all sectors in memory array
#; RDID 1010 1011 Release from Deep power-down and read electronic signature
#
#
#
#
#if DEBUG_STORE
#
#storageput: 
#
#
#
#ret
#
#
#storageread: ret





