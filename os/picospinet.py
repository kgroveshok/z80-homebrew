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


# Network protocol
#
# cmd dest len <packet>

CMD_SEND=1
# Send message to node 1-4 - node ff is ext
# 01 <node> <zero term packet>
#
# will add the zero term packet to the receive buffer of the node
# if the node is ff then it is taken as a server command
# adds the zero term packet as a file on local storage with rec_<dest id>_<src id>_<seq>.txt

CMD_LISTEN=2
# Listen for message to receive
# 02  ->
#  <source node id> or 00 if no data waiting
#  if >0 then clock in <zero term packet>

CMD_STORE=3
# Store string
# 03 <low> <high> <zero term packet>
#
#   stores the zero term packet as a file on local storage with store_<node id>_<address>.txt

CMD_GET=4
# Get store
# 04 <low> <high> clock in <zero term packet>
#
# gets the zero term packet as a file on local storage with store_<node id>_<address>.txt

CMD_CLRALL=5
# clear receive buffer 
#
# 05
#
# delets all rec_<node id>_*.txt

CMD_NEXT=6
# 06 next buffer
# removes most recent rec_<node id>_*.txt 


CMD_UNIXTS=7
# 07   get unix time stamp

CMD_DATE=8
# 08 get current date

CMD_TIME=9
# 09 get current time

CMD_TZ=10
# 10 Set current timezone for NTP




# server (ff node) commands
#
# URL <url>    - wget on the url and places ascii version in new next buffer
# SEND <ip> <address>  - sends the contents of the string at storage address to ip
# READ <ip> <address>  - gets the contents of the string on ip and saves to storage address

# All clocked in data from client to the server (z80) to be pushed to stack on the z80

from machine import Pin
import time

# just one node for now

DI=Pin(2,mode=Pin.IN)      #pico pin 1
DO=Pin(1,mode=Pin.OUT)    # pico pin 2
SCLK=Pin(0,mode=Pin.IN)   # pico pin 4
CE=Pin(3,mode=Pin.IN)     # pico pin 5

#READ=1   # ; Read data from memory array beginning at selected address
#WRITE=2  #;  Write data to memory array beginning at selected address


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
    a=0
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
     #       print( " bit "+str(n)+" is high   1")
            b=b+"1"
            a=(a<< 1 ) +1
            
        #    
        else:
      #      print( " bit "+str(n)+" is low 0")
            b=b+"0"
            a=(a<< 1 ) 

    #print(b)

    return a


#def writebyte(byte,addressh,addressl):
 #      
  #  #; initi write mode
    #;
  #  #;CS low
    #

  #  print("* write "+str(byte)+" to "+str(addressl))
  #  CE.low()
  #  print("ce low")
  #  #;clock out wren instruction##

    #print("* wren")
    #clockbyteout(WREN)

    #;cs high to enable write latch

  #  CE.high()

  #  print("ce high")
    #;
    #; intial write data
    #;
    #; cs low
    #

  #  CE.low()
    #print("ce low")

    #; clock out write instruction
    #
 #   print("* write")
 #   clockbyteout(WRITE)

    #; clock out address (depending on address size)
    #
#    print("* address")
#    clockbyteout(addressh)
#    clockbyteout(addressl)

    #; clock out byte(s) for page

 #   print("* data")
#    clockbyteout(byte)

#    CE.high()
#    print("ce high")


#def readbyte(addressh,addressl):
 #   print("read "+str(addressl))
       
    #; initi write mode
    #;
    #;CS low
    #

 #   CE.low()
    #print("ce low")
    #;clock out read instruction
#
#    clockbyteout(READ)


    #; clock out address (depending on address size)
    #

 #   clockbyteout(addressh)
 #   clockbyteout(addressl)

    #; clock in byte(s) for page

 #   clockbytein()

 #   CE.high()
 #   print("ce high")


fromserver=""
gotcmd=False
celast=False
node_1=0
node_1_buff="Hi!"
node_1_cmd=""
curCmd=0
while(1):
    #cenow=CE.value() 
    #if cenow != celast:
    #    celast=cenow
    #        
    #    if cenow == 0 :
    #            print( "CE low... Clock-in byte")
#   #             a=clockbytein()
    #            #print(a)
    #    else:
    #            print( "CE high")
            
    if CE.value() == 0 :
    #    print( "CE low")
    
        # no command is in progress so see if we have one
        if curCmd == 0:
            node_1=clockbytein()
            print("Cmd: "+str(node_1))
            curCmd=node_1
            
            

        if curCmd == CMD_SEND:
            dest_node=clockbytein()
            print( "Sending string to node "+str(dest_node)+"...")
            cond=True
            node_1_cmd=""
            while cond:
                b=clockbytein()
                if b == 0:
                    cond=False
                else:
                    print(chr(b))
                    node_1_cmd=node_1_cmd+chr(b)
                
            # save string to node's buffer list
            
            
            
            
        if curCmd == CMD_LISTEN:
            print( "Node is listening...")
            
            if len(node_1_buff) > 0:
                clockbyteout(1)
                for i,c in enumerate(node_1_buff):
                    clockbyteout(ord(c))
                clockbyteout(0)
            else:
                clockbyteout(0)
            
            
        if curCmd == CMD_STORE:
            print( "Node wants to store a string...")
            
            
        if curCmd == CMD_GET:
            print( "Node wants to a string from store...")
            
            
        curCmd = 0
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

