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



# Sample sample FORTH code to send data

# clock out a string on stack
#


# use: "hello" ptr count clostro

# : clkstro $00 do dup i + @ spio loop ;




# clock in a string to SCRATCHPAD

# : clkstri scratchpad $01 - repeat $01 + dup dup spii ! @ $00 = until ; 

# use: "hello" $00 send
# : send spicel $01 spio spio ptr count clkstro spiceh ;
# : listen spicel $02 spio spii $00 clkstri spiceh ;
# : storestr spicel $03 spio spio ptr count clkstro spiceh ;
# : getstr spicel $04 spio clkstri spiceh ;

# use: "pass" "ssid" wifi
# : wifi $0b spio ptr count clkstro ptr drop ptr count clkstro ; 

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
# 03 <0-255> <zero term packet>
#
#   stores the zero term packet as a file on local storage with store_<node id>_<address>.txt

CMD_GET=4
# Get store
# 04 <0-255> <zero term packet>
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

CMD_WIFI=11
# 11 <SSID> <PASS>  Send SSID and password to configure Wifi

CMD_LANSTATUS=12
# 12 Request current LAN status, IP, datetime etc

CMD_TERM=13
# 13 Send a byte stream to terminal hosted by server (more useful if a Pi with HDMI and not Pico)

CMD_NOTE=14
# 14 <note> <duration>  Play a note via PWM on the Pico (useful as dont have the sound chip working yet)

CMD_GETNODE=15
# 15 Clock back the node hub and id this device is connected to

CMD_GETMAP=16
# 16 clock back hub id and status of each node (connected or not). 

CMD_GETCHR=17
# 17 clock back next byte in buffer

# server (ff node) commands
#
# URL <url>    - wget on the url and places ascii version in new next buffer
# SEND <ip> <address>  - sends the contents of the string at storage address to ip
# READ <ip> <address>  - gets the contents of the string on ip and saves to storage address

# All clocked in data from client to the server (z80) to be pushed to stack on the z80

from machine import Pin
import time

# just one node for now

#DI=Pin(2,mode=Pin.IN)      #pico pin 1
#DO=Pin(1,mode=Pin.OUT)    # pico pin 2
#SCLK=Pin(0,mode=Pin.IN)   # pico pin 4
#CE=Pin(3,mode=Pin.IN)     # pico pin 5

#node_1=0
#node_1_buff="Hi!"
#node_1_cmd=""
#node_1_strings={}


# structrure to hold each node

#     Node 1          Node 2    Node 3    Node 4      Node 5       Node 6
#       GPIO  Pin  
#SLK    0     1      4   6       8   11     12  16    16    21     20  26 
#DO     1     2      5   7       9   12     13  17    17    22     21  27
#DI     2     4      6   9      10   14     14  19    18    24     22  29
#CE     3     5      7  10      11   15     15  20    19    25     26  31

# sub seq steps
SEQ_SPICLKPULSE=1
SEQ_SPIINBIT7=2
SEQ_SPIINBIT6=3
SEQ_SPIINBIT5=4
SEQ_SPIINBIT4=5
SEQ_SPIINBIT3=6
SEQ_SPIINBIT2=7
SEQ_SPIINBIT1=8
SEQ_SPIINBIT0=9
`
SEQ_SPIOUTBIT7=10
SEQ_SPIOUTBIT6=11
SEQ_SPIOUTBIT5=12
SEQ_SPIOUTBIT4=13
SEQ_SPIOUTBIT3=14
SEQ_SPIOUTBIT2=15
SEQ_SPIOUTBIT1=16
SEQ_SPIOUTBIT0=17

SEQ_SAVEPARAM1=18
SEQ_SAVEPARAM2=19
SEQ_SAVEPARAM3=20
SEQ_SAVEPARAM4=21

# command sequence ops

seq={
        { "cmd" : CMD_SEND,   # the command in operation for this node
          "seq" : [ SEQ_SPIINBIT7, SEQ_SPIINBIT6, SEQ_SPIINBIT5,   ]
        }

    }

# node setup

nodes={

    { "hub" : 0,     # this hub id (not used yet but could be used to chain hubs over ip)
      "node" : 1,    # this current node 
      "DIpin" : 2,      # DI pin for node
      "DOpin" : 1,      # DO pin for node
      "SCLKpin" : 0,    # SCLK pin for node
      "CEpin" : 3,      # CE pin for node
      "buff" : "",   # Current buffer
      "cmd" : "",    # Current command selected 
      "cmdseq": [],   # sequence of actions for current command
      "cmdseqp": 0,   # position of sequence of actions for current command
      "cmdspiseq": "",   # spi action for current command
      "strings" : {},    # Strings stash for node
      "seq" : "",     # Current position on processing command
      "byteclk" : 0,   # Current value of clocked in byte
      "param" : {},   # Hash of params currently being constructed for command
      "clkstate" : 0,   # state current SCLK is in
      "lastactive" : 0,    # unix time stamp of when we last saw a clock pulse. Used to detect dead node
      "islive" : 0      # flag is set when any data is detected on this node
    },


    { "hub" : 0,     # this hub id (not used yet but could be used to chain hubs over ip)
      "node" : 2,    # this current node 
      "DIpin" : 6,      # DI pin for node
      "DOpin" : 5,      # DO pin for node
      "SCLKpin" : 4,    # SCLK pin for node
      "CEpin" : 7,      # CE pin for node
      "buff" : "",   # Current buffer
      "cmd" : "",    # Current command selected 
      "cmdseq": [],   # sequence of actions for current command
      "cmdseqp": 0,   # position of sequence of actions for current command
      "cmdspiseq": "",   # spi action for current command
      "strings" : {},    # Strings stash for node
      "seq" : "",     # Current position on processing command
      "byteclk" : 0,   # Current value of clocked in byte
      "param" : {},   # Hash of params currently being constructed for command
      "clkstate" : 0,   # state current SCLK is in
      "lastactive" : 0,    # unix time stamp of when we last saw a clock pulse. Used to detect dead node
      "islive" : 0      # flag is set when any data is detected on this node
    },






}


def setupNodes():
    print("Setup PICO GPIO pins for SPI on each node")
    for a in nodes:
        print(a)

        # setup SPI pin for node
        
        a["DI"]=Pin(a["DIpin"],mode=Pin.IN) 
        a["DO"]=Pin(a["DOpin"],mode=Pin.OUT)
        a["SCLK"]=Pin(a["SCLKpin"],mode=Pin.IN) 
        a["CE"]=Pin(a["CEpin"],mode=Pin.IN)     

    print(nodes)


#READ=1   # ; Read data from memory array beginning at selected address
#WRITE=2  #;  Write data to memory array beginning at selected address


# Wifi support routines for the pico w
# Wifi card setup
#https://peppe8o.com/getting-started-with-wifi-on-raspberry-pi-pico-w-and-micropython/
from time import sleep
from time import ticks_ms, ticks_diff
import framebuf,sys
import os
import json
import network
import socket


WifiSSID=""
WifiPass=""



def saveSettings():
        global WifiSSID
        global WifiPass
        global node_1_strings

        settings = [ WifiSSID, WifiPass ] 
   
        print( "Saving wifi settings") # STRIP
#        print(settings)
        with open('/spinet-wifi.json', "w") as file_write:
            json.dump(settings, file_write)
        file_write.close()
        print( "Saving string store for node 1") # STRIP
#        print(settings)
        with open('/spinet-strings-1.json', "w") as file_write:
            json.dump(node_1_strings, file_write)
        file_write.close()
        

def loadSettings():
    global WifiSSID
    global WifiPass
    global node_1_strings
    try:
        f = open( "/spinet-wifi.json","r" )
        print( "Loading wifi settings") # STRIP
        p = f.read()
        sett=json.loads(p)
 #       print(sett)

        WifiSSID= sett[0]
        WifiPass= sett[1]
        
        f = open( "/spinet-strings-1.json","r" )
        print( "Loading string store for node 1") # STRIP
        p = f.read()
        sett=json.loads(p)
        node_1_strings=sett
        print(node_1_strings)        
        
    except:
        saveSettings()

wlan=None
connection=None
connectretries=5

def connect():
   # wlan = network.WLAN(network.STA_IF)
   # wlan.active(True)
   # wlan.connect(SSIDWifi, passwordWifi)
   pass

try:
#if True:
  import network
  import urequests
  #import socket
  import struct
  import ntptime
# actually check if any of the wifi functions are present. If so then we have wifi!
  wlan = network.WLAN(network.STA_IF)
  print(wlan)
except :
    hasWifi = False

def wifistatus():
    return wlan.isconnected()
        
        
# See: https://docs.python.org/3/library/time.html#time.struct_time
tm_year = 0
tm_mon = 1 # range [1, 12]
tm_mday = 2 # range [1, 31]
tm_hour = 3 # range [0, 23]
tm_min = 4 # range [0, 59]
tm_sec = 5 # range [0, 61] in strftime() description
tm_wday = 6 # range 8[0, 6] Monday = 0
tm_yday = 7 # range [0, 366]
tm_isdst = 8 # 0, 1 or -1 
tm_tmzone = 'Europe/London' # default (set in dst_data.json) abbreviation of timezone name
timezone_set = False
#tm_tmzone_dst = "WET0WEST,M3.5.0/1,M10.5.0"
time_is_set=False
# Timezone and dst data are in external file "dst_data.json"
# See: https://www.epochconverter.com/
# The "start" and "end" values are for timezone "Europe/Portugal"
dst = None # See setup()

tm_gmtoff = 0 # offset east of GMT in seconds
# added '- tm_gmtoff' to subtract 1 hour = 3600 seconds to get GMT + 1 for Portugal
NTP_DELTA = 2208988800 - tm_gmtoff # mod by @PaulskPt.
# modified to use Portugues ntp host
ntphost = "uk.pool.ntp.org" # mod by @PaulskPt
#dim = {1:31, 2:28, 3:31, 4:30, 5:31, 6:30, 7:31, 8:31, 9:30, 10:31, 11:30, 12:31}

connectretries=5
ntp_retries=5
def settime():
    #global lastUpdate
    global time_is_set
    global connectretries
    global ntp_retries
    global wlan

    if not wlan.isconnected():
        if connectretries>0:
            wlan.active(True)
            usessid=WifiSSID
            #.replace(" ","")
            usepass=WifiPass.replace(" ","")
            wlan.connect(usessid, usepass)        
            #wifiStatus(wlan.isconnected())
            if not wlan.isconnected():
                connectretries=connectretries-1
    if wlan.isconnected() and not time_is_set :
            #ntp_set_time()
            try:
                print("Trying NTP Set time") # STRIP
                ntptime.settime()
                time_is_set=True
                print("NTP Set time") # STRIP
            except Exception as E:
                print(E)
                ntp_retries=ntp_retries-1
                print( "NTP retries %d" % ntp_retries) # STRIP
                if ntp_retries == 0:
                    time_is_set=True
                    print( "Too many NTP tries. SKipping") # STRIP
                sleep(1)
                
    print(wlan.isconnected())


def clockbyteout(byte):
   # msb first
    while( not SCLK.value() ):
            pass # wait for low to high clock out and move on

    pat=""
    print("byte "+str(byte))
    for n in range(7,-1,-1):
        
#        print("clock high")
        if ( byte & ( 1<<n)) :
            DI.high()
            pat=pat+"1"
 #           print( " bit "+str(n)+" high  1")
            
        else:
            DI.low()
            pat=pat+"0"
  #          print( " bit "+str(n)+" low   0")
        #time.sleep(0.025)


        while(SCLK.value() ):
            pass     # wait for high to low to clock out
        #time.sleep(0.025)
        while( not SCLK.value() ):
            pass # wait for low to high clock out and move on

        #time.sleep(0.025)
    print(pat)
    #    print("clock low")

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



# clock in a zero term string from a node

def clockinzs():
    s=""
    cond=True
    print("Clock-in zero term string")
    while cond:
        b=clockbytein()
        if b == 0:
            cond=False
        else:
            print(chr(b))
            s=s+chr(b)
    print("Got string: "+s)
    return s


setupNodes()

loadSettings()
print("Tring wlan connection")
settime()

fromserver=""
gotcmd=False
celast=False
curCmd=0
while(1):
    # smallest unit of step is a single SCLK hand shake. Multiplex the bit handshake for each node
    # on clock pulse


    status=""
    for n in nodes:
        if n["CE"].value() == 0:     # Node wants to talk
            status=status+"Y-"

            # get current clock state

            clk=n["SCLK"].value()
            preclk=n["clkstate"]

            if clk:
                status=status+"H-"
            else:
                status=status+"L-"

            # clock state has changed

            if clk <> preclk:
                status=status="C"

                # TODO if clock is low then clock in/out a single bit for current sequence

                # are we looking for a command first?

                if n["cmd"]="" and n["cmdspiseq"]="" :
                    # yes, start clock in a bit
                    n["cmdspiseq"]=SEQ_SPIINBIT7


                # TODO clock in a bit for cmdspiseq


                # process sequence steps

                # TODO progress SPI IN
                # TODO progress SPI OUT
                # TODO end of in and out
                # TODO is this byte a command? if command is empty and we have a byte then yes. Load sequence for the command
                # TODO process a sequence 

            else:
                status=status=" "

            n["clkstate"]=clk

        else:
            status=status+"N-?-? "


    print( "Status: "+status)


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
            
#    if CE.value() == 0 :
#    #    print( "CE low")
#    
#        # no command is in progress so see if we have one
#        if curCmd == 0:
#            node_1=clockbytein()
#            print("Cmd: "+str(node_1))
#            curCmd=node_1
#            
#        if curCmd == CMD_WIFI:
#            print( "Setting Wifi... Waiting for SSID")
#            WifiSSID=clockinzs()
#            print( "Set Wifi SSID to "+WifiSSID)
#            print("Waiting for password")
#            WifiPass=clockinzs()
#            print( "Set Wifi password to "+WifiPass)
#            saveSettings()
#            settime()
#
#
#
#        if curCmd == CMD_SEND:
#            dest_node=clockbytein()
#            print( "Sending string to node "+str(dest_node)+"...")
#            node_1_cmd=clockinzs() 
#            # TODO save string to node's buffer list
#           
#            print("Saving string to node buffer "+str(dest_node))
#            # TODO echo back sending
#            node_1_buff=node_1_cmd
#            
#            
#            if dest_node == 255 :   # Tell the server to do something
#                print("Node is server. Handle remote commands")
#                if "GET" == node_1_cmd[:3]:    # look up something on the lan
#                        print("Get remote URL..")
#                        blob = urequests.get(node_1_cmd[4:])
#                        node_1_buff=blob.text
#                        print(blob.reason) # STRIP
#                        print(blob.text) # STRIP
#                        blob.close()
#
#            
#            
#            
#            
#        if curCmd == CMD_LISTEN:
#            print( "Node is listening...")
#            
#            if len(node_1_buff) > 0:
#                clockbyteout(1)
#                for i,c in enumerate(node_1_buff):
#                    print(ord(c))
#                    clockbyteout(ord(c))
#                    if i > 40:
#                        # TODO limit to getting 40 chars for testing. Need to do in max string
#                        # length blocks when live which is 250 chars
#                        break
#                clockbyteout(0)
#            else:
#                clockbyteout(0)
#            
#            
#        if curCmd == CMD_STORE:
#            ix=clockbytein()
#            print( "Node wants to store a string in "+str(ix)+"...")
#            s=clockinzs()
#            print("String: "+s)
#            node_1_strings[ix]=s
#            print("Stored strings: "+str(node_1_strings))
#            saveSettings()
#            
#            
#        if curCmd == CMD_GET:
#            ix=clockbytein()
#            print( "Node wants to a string from store "+str(ix)+"...")
#            for i,c in enumerate(node_1_strings[ix]):
#                    print(ord(c))
#                    clockbyteout(ord(c))
#            clockbyteout(0)
#            
#            
#        curCmd = 0
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

