# PicoNET - SPI networking hub
# (c) 2025 Kevin Groves



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

buffers={}


# Network protocol
#
# cmd dest len <packet>

CMD_PUTCHR=0x10
# Send char to node 1-4 - node ff is ext node 0 is all (todo)
#
#
# To externl, storage to strings. Commands delimited by ',' (comma)
#
# GET <url>    - GET on the url and places ascii version in new next buffer
# PST <url>    - POST on the url and places ascii version in new next buffer
# SND <ip> <port>  - sends the contents of the string at storage address to ip
# REC <ip> <port>  - gets the contents of the string on ip and saves to storage address
# GO                  - Instruct hub to do remote actions


CMD_GETCHR=0x11
# Listen for message to receive
# 02  ->
#   <-  <source node id> or 00 if no data waiting
#       if >0 then clock in <zero term packet>

CMD_PUTSSTRZ=0x12
# Store string
# 03 <0-255> <zero term packet>
#
#   stores the zero term packet as a file on local storage with store_<node id>_<address>.txt

CMD_GETSSTRZ=0x13
# Get stored string
# 04 <0-255> <zero term packet>
#
# gets the zero term packet as a file on local storage with store_<node id>_<address>.txt

CMD_CLRALL=0x15
# clear receive buffer for this node
#



# will add the zero term packet to the receive buffer of the node
# if the node is ff then it is taken as a server command
# adds the zero term packet as a file on local storage with rec_<dest id>_<src id>_<seq>.txt

#CMD_UNIXTS=7
# 07   get unix time stamp

CMD_GETDATE=0x16
# 08 get current date

CMD_GETTIME=0x17
## 09 get current time

#CMD_TZ=10
# 10 Set current timezone for NTP

#CMD_WIFI=11
# 11 <SSID> <PASS>  Send SSID and password to configure Wifi

#CMD_LANSTATUS=12
# 12 Request current LAN status, IP, datetime etc

#CMD_TERM=13
# 13 Send a byte stream to terminal hosted by server (more useful if a Pi with HDMI and not Pico)

#CMD_NOTE=14
# 14 <note> <duration>  Play a note via PWM on the Pico (useful as dont have the sound chip working yet)

CMD_GETNODE=0x18
# 15 Clock back the node hub and id this device is connected to

#CMD_GETMAP=16
# 16 clock back hub id and status of each node (connected or not). 

#CMD_GETCHR=17
# 17 clock back next byte in buffer


# All clocked in data from client to the server (z80) to be pushed to stack on the z80

CMD_DEBUG=0x30
# 18 dump to logs all of the node vars to console to help with debug

CMD_NETDEBUG=0x31
# x -> Debug to console level

CMD_SYNC=0x32
# x -> Number of minutes to sync settings to storage

netdebug=1

# late time storage arrays were synced to storage
lastsync=0
timetosync=1

lastservercmd=0
timetoservercmd=1

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

#SEQ_SPICLKPULSE=1

#SEQ_SAVEPARAM1=18
#SEQ_SAVEPARAM2=19
#SEQ_SAVEPARAM3=20
#SEQ_SAVEPARAM4=21

# command op codes

SEQ_SPIBIT7=7
SEQ_SPIBIT6=6
SEQ_SPIBIT5=5
SEQ_SPIBIT4=4
SEQ_SPIBIT3=3
SEQ_SPIBIT2=2
SEQ_SPIBIT1=1
SEQ_SPIBIT0=0



#SEQ_SPIINBIT7=9
#SEQ_SPIINBIT6=8
#SEQ_SPIINBIT5=7
#SEQ_SPIINBIT4=6
#SEQ_SPIINBIT3=5
#SEQ_SPIINBIT2=4
#SEQ_SPIINBIT1=3
#SEQ_SPIINBIT0=2
#
#SEQ_SPIOUTBIT7=17
#SEQ_SPIOUTBIT6=16
#SEQ_SPIOUTBIT5=15
#SEQ_SPIOUTBIT4=14
#SEQ_SPIOUTBIT3=13
#SEQ_SPIOUTBIT2=12
#SEQ_SPIOUTBIT1=11
#SEQ_SPIOUTBIT0=10

SEQ_BYTEIN=100
SEQ_BYTEOUT=101
SEQ_ZSTRIN=102
SEQ_STROUT=103
SEQ_INIT= 104    # init for the command ie setup params
SEQ_SAVE= 105    # save any params clocked in
SEQ_DEBUG=106
SEQ_SYNC=107    # force sync of buffers to storage
SEQ_NOP=108
SEQ_END=109
SEQ_SAVEBYTE=110
SEQ_REPEAT=150
SEQ_UNTILZ=151
SEQ_SSTRZNEXT=153
 
# command sequence ops

seq=[
        { "cmd" : CMD_PUTCHR,   # the command in operation for this node
          # node to rec byte, byte to send it
          "seq" : [ SEQ_INIT, 
    #        SEQ_SPIINBIT7, SEQ_SPIINBIT6, SEQ_SPIINBIT5, SEQ_SPIINBIT4, SEQ_SPIINBIT3, SEQ_SPIINBIT2, SEQ_SPIINBIT1, SEQ_SPIINBIT0, 
            SEQ_BYTEIN,
            SEQ_SAVEBYTE, 
    #        SEQ_SPIINBIT7, SEQ_SPIINBIT6, SEQ_SPIINBIT5, SEQ_SPIINBIT4, SEQ_SPIINBIT3, SEQ_SPIINBIT2, SEQ_SPIINBIT1, SEQ_SPIINBIT0, 
            SEQ_BYTEIN,
            SEQ_SAVEBYTE, 
            SEQ_END ]
        },
        { "cmd" : CMD_GETCHR,   # the command in operation for this node
          # send back byte in buffer
          "seq" : [ SEQ_INIT,  SEQ_BYTEOUT, SEQ_END
          ]
        },
        { "cmd" : CMD_GETNODE,   # the command in operation for this node
          # send back byte in buffer
          "seq" : [ SEQ_INIT,  SEQ_BYTEOUT, SEQ_END
          ]
        },


        { "cmd" : CMD_NETDEBUG,   # the command in operation for this node
          # send back byte in buffer
          "seq" : [ SEQ_INIT, SEQ_BYTEIN, SEQ_SAVEBYTE, SEQ_END ]
        },
        { "cmd" : CMD_SYNC,   # the command in operation for this node
          # send back byte in buffer
          "seq" : [ SEQ_INIT, SEQ_BYTEIN, SEQ_SAVEBYTE, SEQ_END ]
        },
        
        { "cmd" : CMD_DEBUG,   # the command in operation for this node
          # send back byte in buffer
          "seq" : [ SEQ_DEBUG, SEQ_END ]
        },
        { "cmd" : CMD_CLRALL,   # the command in operation for this node
          # node to rec byte, byte to send it
          "seq" : [ SEQ_INIT,  SEQ_END ]
        },

        { "cmd" : CMD_PUTSSTRZ,   # the command in operation for this node
          # str index, then zero term string
          "seq" : [ SEQ_INIT,
                    SEQ_BYTEIN,    # index
                    SEQ_SAVEBYTE,
                    SEQ_REPEAT,
                    SEQ_BYTEIN,    # zero term str
                    SEQ_SAVEBYTE,
                    SEQ_UNTILZ,
                    SEQ_END ]
        },
        { "cmd" : CMD_GETSSTRZ,   # the command in operation for this node
          # node to rec byte, byte to send it
          "seq" : [ SEQ_INIT, SEQ_BYTEIN, SEQ_SAVEBYTE, SEQ_REPEAT, SEQ_SSTRZNEXT, SEQ_BYTEOUT, SEQ_UNTILZ,  SEQ_END ]
        },
        { "cmd" : CMD_GETTIME,   # the command in operation for this node
          # node to rec byte, byte to send it
          "seq" : [ SEQ_INIT, SEQ_REPEAT, SEQ_SSTRZNEXT, SEQ_BYTEOUT, SEQ_UNTILZ,  SEQ_END ]
        },
        { "cmd" : CMD_GETDATE,   # the command in operation for this node
          # node to rec byte, byte to send it
          "seq" : [ SEQ_INIT, SEQ_REPEAT, SEQ_SSTRZNEXT, SEQ_BYTEOUT, SEQ_UNTILZ,  SEQ_END ]
        },

    ]

# node setup

nodes=[

    { "hub" : 0,     # TODO this hub id (not used yet but could be used to chain hubs over ip)
      "node" : 1,    # this current node 
      "DIpin" : 2,      # DI pin for node
      "DOpin" : 1,      # DO pin for node
      "SCLKpin" : 0,    # SCLK pin for node
      "CEpin" : 3,      # CE pin for node
      "buff" : "",   # Current buffer
      "cmd" : 0,    # Current command selected 
      "cmdseq": [],   # sequence of actions for current command
      "cmdseqp": 0,   # position of sequence of actions for current command
      "cmdspiseq": -1,   # spi action for current command
      "servercmd": "",    # the command server should act on
      "strings" : {},    # Strings stash for node
 #     "seq" : "",     # Current position on processing command
      "byteclk" : 0,   # Current value of clocked in/out byte
      "params" : {},   # Hash of params currently being constructed for command
      "clkstate" : 0,   # state current SCLK 
      "lastactive" : 0,    # TODO unix time stamp of when we last saw a clock pulse. Used to detect dead node
      "islive" : 0      # TODO flag is set when any data is detected on this node
    },



    { "hub" : 0,     # TODO this hub id (not used yet but could be used to chain hubs over ip)
      "node" : 2,    # this current node 
      "DIpin" : 6,      # DI pin for node
      "DOpin" : 5,      # DO pin for node
      "SCLKpin" : 4,    # SCLK pin for node
      "CEpin" : 7,      # CE pin for node
      "buff" : "",   # Current buffer
      "cmd" : 0,    # Current command selected
      "servercmd": "",    # the command server should act on
      "cmdseq": [],   # sequence of actions for current command
      "cmdseqp": 0,   # position of sequence of actions for current command
      "cmdspiseq": -1,   # spi action for current command
      "strings" : {},    # Strings stash for node
 #     "seq" : "",     # Current position on processing command
      "byteclk" : 0,   # Current value of clocked in/out byte
      "params" : {},   # Hash of params currently being constructed for command
      "clkstate" : 0,   # state current SCLK 
      "lastactive" : 0,    # TODO unix time stamp of when we last saw a clock pulse. Used to detect dead node
      "islive" : 0      # TODO flag is set when any data is detected on this node
    },



    { "hub" : 0,     # TODO this hub id (not used yet but could be used to chain hubs over ip)
      "node" : 3,    # this current node 
      "DIpin" : 10,      # DI pin for node
      "DOpin" : 9,      # DO pin for node
      "SCLKpin" : 8,    # SCLK pin for node
      "CEpin" : 11,      # CE pin for node
      "buff" : "",   # Current buffer
      "cmd" : 0,    # Current command selected
      "servercmd": "",    # the command server should act on
      "cmdseq": [],   # sequence of actions for current command
      "cmdseqp": 0,   # position of sequence of actions for current command
      "cmdspiseq": -1,   # spi action for current command
      "strings" : {},    # Strings stash for node
 #     "seq" : "",     # Current position on processing command
      "byteclk" : 0,   # Current value of clocked in/out byte
      "params" : {},   # Hash of params currently being constructed for command
      "clkstate" : 0,   # state current SCLK 
      "lastactive" : 0,    # TODO unix time stamp of when we last saw a clock pulse. Used to detect dead node
      "islive" : 0      # TODO flag is set when any data is detected on this node
    },



    { "hub" : 0,     # TODO this hub id (not used yet but could be used to chain hubs over ip)
      "node" : 4,    # this current node 
      "DIpin" : 14,      # DI pin for node
      "DOpin" : 13,      # DO pin for node
      "SCLKpin" : 12,    # SCLK pin for node
      "CEpin" : 15,      # CE pin for node
      "buff" : "",   # Current buffer
      "cmd" : 0,    # Current command selected
      "servercmd": "",    # the command server should act on
      "cmdseq": [],   # sequence of actions for current command
      "cmdseqp": 0,   # position of sequence of actions for current command
      "cmdspiseq": -1,   # spi action for current command
      "strings" : {},    # Strings stash for node
 #     "seq" : "",     # Current position on processing command
      "byteclk" : 0,   # Current value of clocked in/out byte
      "params" : {},   # Hash of params currently being constructed for command
      "clkstate" : 0,   # state current SCLK 
      "lastactive" : 0,    # TODO unix time stamp of when we last saw a clock pulse. Used to detect dead node
      "islive" : 0      # TODO flag is set when any data is detected on this node
    },




    { "hub" : 0,     # TODO this hub id (not used yet but could be used to chain hubs over ip)
      "node" : 5,    # this current node 
      "DIpin" : 18,      # DI pin for node
      "DOpin" : 17,      # DO pin for node
      "SCLKpin" : 16,    # SCLK pin for node
      "CEpin" : 19,      # CE pin for node
      "buff" : "",   # Current buffer
      "cmd" : 0,    # Current command selected
      "servercmd": "",    # the command server should act on
      "cmdseq": [],   # sequence of actions for current command
      "cmdseqp": 0,   # position of sequence of actions for current command
      "cmdspiseq": -1,   # spi action for current command
      "strings" : {},    # Strings stash for node
 #     "seq" : "",     # Current position on processing command
      "byteclk" : 0,   # Current value of clocked in/out byte
      "params" : {},   # Hash of params currently being constructed for command
      "clkstate" : 0,   # state current SCLK 
      "lastactive" : 0,    # TODO unix time stamp of when we last saw a clock pulse. Used to detect dead node
      "islive" : 0      # TODO flag is set when any data is detected on this node
    },






]


def setupNodes():
    print("Setup PICO GPIO pins for SPI on each node")
    for a in nodes:
        print("Setting up for node "+str(a["node"]))

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
from time import ticks_ms, ticks_diff, localtime
import framebuf,sys
import os
import json
import network
import socket
import utime

WifiSSID=""
WifiPass=""



def saveSettings():
        global WifiSSID
        global WifiPass
        global buffers
        global nodes

        settings = [ WifiSSID, WifiPass ] 
   
        print( "Saving wifi settings") # STRIP
#        print(settings)
        with open('/spinet-wifi.json', "w") as file_write:
            json.dump(settings, file_write)
        file_write.close()
        print( "Saving sbuffers store for nodes") # STRIP
#        print(settings)
        with open('/spinet-buffers.json', "w") as file_write:
            json.dump(buffers, file_write)
        file_write.close()
        
        for n in nodes:
            print("Dumping string array for node "+str(n["node"]))
            with open('/spinet-strings-'+str(n["node"])+'.json', "w") as file_write:
                json.dump(n["strings"], file_write)
            file_write.close()
        

def loadSettings():
        global WifiSSID
        global WifiPass
        global buffers
        global nodes
    #try:
        f = open( "/spinet-wifi.json","r" )
        print( "Loading wifi settings") # STRIP
        p = f.read()
        sett=json.loads(p)
 #       print(sett)

        WifiSSID= sett[0]
        WifiPass= sett[1]
        
        f = open( "/spinet-buffers.json","r" )
        print( "Loading buffers store for nodes") # STRIP
        p = f.read()
        sett=json.loads(p)
        buffers=sett
        print(buffers)        
        
        for n in nodes:
            print("Loading stored string array for node "+str(n["node"]))
            try:   
                f = open('/spinet-strings-'+str(n["node"])+'.json',"r" )
                p = f.read()
                sett=json.loads(p)
                n["strings"]=sett
                print(n["strings"])        
            except:
                    print("File not found")
        
    #except:
    #    saveSettings()

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

def nodeclockbyteout(node):
    global netdebug
   # msb first
    # calc bit to clock
    n=node["cmdspiseq"]
#    print("Node "+str(node["node"])+": out byte "+str(node["byteclk"])+" bit "+str(n))
    #if node["cmd"] != 0 :
    #    node["byteclk"]=node["params"][node["cmdseqp"]]
    byte=node["byteclk"]


    if ( byte & ( 1<<n)) :
        node["DO"].high()
#        print("Node "+str(node["node"])+": bit high ")
        
    else:
        node["DO"].low()
 #       print("Node "+str(node["node"])+": bit low ")

    n=node["cmdspiseq"]-1

    if n < 0:
        n=-1

    return n


def nodeclockbytein(node):
    global netdebug
   # msb first
    n=node["cmdspiseq"]
#    print("Node "+str(node["node"])+": in byte "+str(node["byteclk"])+" bit "+str(n))
    #if node["cmd"] != 0 :
        #try:
        #    node["byteclk"]=node["params"][node["cmdseqp"]]
        #except:
        #    node["byteclk"]=0
    #byte=node["byteclk"]

    byte=node["byteclk"]
    bit=node["DI"].value()
    if bit  :
 #       print( " bit "+str(n)+" is high   1")
        byte=(byte<< 1 ) +1
        
    #    
    else:
  #      print( " bit "+str(n)+" is low 0")
        byte=(byte<< 1 ) 

    #print(b)

    node["byteclk"]=byte
#    if node["cmd"] != 0 :
#        node["params"][node["cmdseqp"]]=byte
 #   print("Node "+str(node["node"])+": byte is "+str(byte))

    n=node["cmdspiseq"]-1

    if n < 0:
        n=-1

    return n

now=""
nowdate=""
nowtime=""

def lpad(str,width,padwith):
        ret=(padwith * width) + str
        return ret[len(ret)-width:30]

def setNow():
    global now
    global nowdate
    global nowtime
    now = localtime()        

    # datetime format
    nowdate=str(now[0])+"-"+lpad(str(now[1]),2,"0")+"-"+lpad(str(now[2]),2,"0")
    nowtime=lpad(str(now[3]),2,"0")+":"+lpad(str(now[4]),2,"0")+":"+lpad(str(now[5]),2,"0")


def cmd_init(n):
    global netdebug
    print("Init params for command %d in node %d" % ( n["cmd"], n["node"])) if netdebug > 0 else 0
#    print(n["params"])
    n["params"]={}


    if n["cmd"] == CMD_GETCHR:
            # put a char from the current buffer into the param list to send back
            print(buffers) if netdebug > 0 else 0
            b=buffers[str(n["node"])]
            if len(b) > 0:
                n["byteclk"]=ord(b[0:1])
            #    n["params"][1]=ord(b[0:1])
            #    n["params"][2]=ord(b[0:1])
                buffers[str(n["node"])]=b[1:]
            else:
                n["byteclk"]=0
                #n["params"][1]=0
                #n["params"][2]=0
                
            #n["params"][1]=32
            #n["params"][2]=32
            pass
            
#    if n["cmd"] == CMD_PUTCHR:
#            n["params"]={}##

    #if n["cmd"] == CMD_PUTSTRZ:
    #        n["params"]={}
    
    if n["cmd"] == CMD_GETNODE:
               n["byteclk"]=n["node"]

    if n["cmd"] == CMD_GETSSTRZ:
            print("getz init counter") if netdebug > 0 else 0
            n["params"]['c']=0

    if n["cmd"] == CMD_GETTIME:
            setNow()
            print("gettime init counter") if netdebug > 0 else 0
            n["params"]['c']=0
            n["params"][2]="time"
            n["strings"]["time"]=nowtime
            
    if n["cmd"] == CMD_GETDATE:
            setNow()
            print("getdate init counter") if netdebug > 0 else 0
            n["params"]['c']=0
            n["params"][2]="date"
            n["strings"]["date"]=nowdate
    
    if n["cmd"] == CMD_CLRALL:
     #       n["params"]={}
            buffers[str(n["node"])]=""
            
    print(n["params"]) if netdebug > 0 else 0
    n["cmdseqp"]=n["cmdseqp"]+1
    n["cmdspiseq"]=-1
    
def cmd_end(n):
    global netdebug
    #global nodes

    
    print("End command. Save params for command %d in node %d" % ( n["cmd"], n["node"])) if netdebug > 0 else 0
    print(n["params"]) if netdebug > 0 else 0


    #try:
    if n["cmd"] == CMD_NETDEBUG:
            print(n["params"])
            print("Set netdebug from " + str(netdebug))
            netdebug=n["params"][1]
            print("Set netdebug to " + str(netdebug))
    #    
    #    
    #except:
    #        print("fail in netbug")
    if n["cmd"] == CMD_SYNC:
            print("Set sync from " + str(timetosync))  if netdebug > 0 else 0
            timetosync=n["params"][1]
            print("Set sync to " + str(timetosync))  if netdebug > 0 else 0



    if n["cmd"] == CMD_PUTCHR:
        # save the param to the dest buffer
        
        if n["params"][1] == 0 :
            # save to all nodes
            print("Save to all buffers") if netdebug > 0 else 0
            for nn in nodes:
                try:
                    curbuff=buffers[str(nn["node"])]
                except:
                    curbuff=""
                if nn["node"] != n["node"] :
                    # but exclude sender node
                    buffers[str(nn["node"])]=curbuff+chr(n["params"][2])
            
            print(buffers)
        elif n["params"][1] == 255 :
                # build server command string
                print("Save to server buffer ") if netdebug > 0 else 0
                try:
                    curbuff=n["servercmd"]
                except:
                    curbuff=""
        
                n["servercmd"]=curbuff+chr(n["params"][2])

        else:
            print("Save to single buffer "+str(n["params"][1])) if netdebug > 0 else 0
            try:
                curbuff=buffers[str(n["params"][1])]
            except:
                curbuff=""
        
            buffers[str(n["params"][1])]=curbuff+chr(n["params"][2])

    if n["cmd"] == CMD_PUTSSTRZ:
        # param one is the string index followed by the string
        p=2
        s=""
        try:
            while 1:
                s=s+chr(n["params"][p])
                p=p+1
        except:
            pass
        n["strings"][int(n["params"][1])]=s
        print("Save string: "+str(s)) if netdebug > 0 else 0

    print(n["params"]) if netdebug > 0 else 0
    print(buffers) if netdebug > 0 else 0
    n["cmdseqp"]=n["cmdseqp"]+1
    n["cmdspiseq"]=-1
    n["cmd"]=0
                        

def cmd_savebyte(n):
    global netdebug
    # save current byte to next param
    pct=len(n["params"])+1
    n["params"][pct]=n["byteclk"]
    print("Save byte -> Save params for command %d in node %d" % ( n["cmd"], n["node"])) if netdebug > 0 else 0
    print(n["params"]) if netdebug > 0 else 0
    n["cmdseqp"]=n["cmdseqp"]+1

setupNodes()

loadSettings()
print("Tring wlan connection")
settime()

fromserver=""
gotcmd=False
celast=False
curCmd=0


#while(1):
#    clockbyteout(33);

def serverCmd(n):
    print("Process server commands")
    cmd=n["servercmd"]
    #if cmd.find(",clr")>0:
    #    print("Clear server commands")
    #    n["servercmd"]=""
    if cmd.find(",go")>=0:
        print("Exec server commands")
        for cmds in cmd.split(","):
            if cmds[:3]=="get":
                print("get: "+cmds[3:])
                # TODO get web request
                
                
        print("Done scan. Clear commands")
        n["servercmd"]=""
        
    


while(1):



# TODO only do when nothing is active??

    # do a sync to storage
    
    thistime=utime.time()
    if lastsync < ( thistime - (60*timetosync)): 
        print("Sync array to storage "+str(thistime))
        lastsync = thistime
        saveSettings()

    # process server commands
    
    thistime=utime.time()
    if lastservercmd < ( thistime - (60*timetoservercmd)): 
        print("Server commands "+str(thistime))
        lastservercmd = thistime
        for n in nodes:
            print("Checking node for server commands "+str(n["node"]))
            print(n["servercmd"])
            if len(n["servercmd"]) > 0:
                print(" Server commands present...")
                serverCmd(n)


    # smallest unit of step is a single SCLK hand shake. Multiplex the bit handshake for each node
    # on clock pulse

    for n in nodes:
        #print("Polling node "+str(n["node"])+str(n["CE"].value()))
        if n["CE"].value() == 1:   # disable any command in progress
                n["cmdspiseq"]=-1
                n["cmd"]=0

        if n["CE"].value() == 0:     # Node wants to talk
   #         print( "Node %d: CE low" % n["node"])


#**** for clock out state change needs to occur after data presented on the bus. it is a clock cycle begind the wave


            # get current clock state

            clk=n["SCLK"].value()
            preclk=n["clkstate"]

#            if clk:
#                print( "Node %d: SCLK high" % n["node"])
#            else:
#                print( "Node %d: SCLK low" % n["node"])


            
            if n["cmd"] == 0 and n["cmdspiseq"] == -1:
                        print( "Node %d: Clock in start of a command" % n["node"]) if netdebug > 0 else 0
                        n["cmdspiseq"]=SEQ_SPIBIT7
                        print("set byteclk=0") if netdebug > 0 else 0
                        n["byteclk"]=0


            # clock state has changed 

            if clk != preclk :
#                print( "Node %d: SCLK state change" % n["node"])
#                if clk:
#                    print( "Node %d: SCLK high" % n["node"])
#                else:
#                    print( "Node %d: SCLK low" % n["node"])

#                if clk == 1:
#                # TODO detect if wanting to clock data out and if so and at first state set byte to
#                go out
#                    if n["cmdspiseq"] != 0 :
#                        if n["cmdspiseq"] > SEQ_SPIINBIT7 :
#                            # OUT
##                            cmd_init()                            
##                            n["cmdspiseq"]=nodeclockbyteout(n["params"][1])
#                            n["cmdspiseq"]=nodeclockbyteout(65)
                    
            

        # if no command active and clk is 0 then clock in a bit
        #   if last bit then decode command



                if n["cmd"] == 0:
                    print("no command") if netdebug > 0 else 0
                    if clk == 1 and n["cmdspiseq"] == -1:
                        print( "Clock in start of a command2") if netdebug > 0 else 0
                        n["cmdspiseq"]=SEQ_SPIBIT7
                        print("set byteclk=0 a") if netdebug > 0 else 0
                        n["byteclk"]=0

                    if clk == 0:
                        print("Clockin in bit for command") if netdebug > 0 else 0
                        n["cmdspiseq"]=nodeclockbytein(n)
                        print("Clock in state: "+str(n["cmdspiseq"])) if netdebug > 0 else 0
                        if n["cmdspiseq"] == -1:
                            n["cmd" ] = n["byteclk"]
                            # must have clocked in the last command byte. Look it up and start a run
                            print("Have command byte. Now look up:"+str(n["cmd"])) if netdebug > 0 else 0
                            
                            print("set byteclk=0 b") if netdebug > 0 else 0
                            n["cmdseqp"]=0
                            n["byteclk"]=0

                            # look up sequence for cmd
                            n["cmdseq"] =[]
                            for a in seq:
                                if a["cmd"] == n["cmd"] :
                                    n["cmdseq"] = a["seq"]
                                    print("Command sequence selected: "+str(a["seq"])) if netdebug > 0 else 0
                            if n["cmdseq"] == []:
                                # no command byte seq found to exec to look for a new command again
                                print("Invalid command byte") if netdebug > 0 else 0
                                n["cmd"]=0
                                        


                else:
                    print("in a step. any spi activity?") if netdebug > 0 else 0
                    try:
                        if n["cmdseq"][n["cmdseqp"]] == SEQ_BYTEOUT and clk == 1 :
                            print("clock high and byte out") if netdebug > 0 else 0
                            # TODO prep a clock out of byte
                            n["cmdspiseq"]=nodeclockbyteout(n)
                            if n["cmdspiseq"]==-1:
                                n["cmdseqp"]=n["cmdseqp"]+1

                        if n["cmdseq"][n["cmdseqp"]] == SEQ_BYTEIN and clk == 0 :
                            # TODO prep a clock out of byte
                            print("clock low and byte in") if netdebug > 0 else 0
                            n["cmdspiseq"]=nodeclockbytein(n)
                            if n["cmdspiseq"]==-1:
                                n["cmdseqp"]=n["cmdseqp"]+1
                    except:
                        # might have gone past end of command sequence
                        pass

#                if clk == 0:
#
#                    # act on a low state (for clock in)
#
#                    # TODO if clock is low then clock in/out a single bit for current sequence
#
#                    # are we looking for a command first?
#
## TODO only clock in if a clock in process
#                    if n["cmd"] == 0 and n["cmdspiseq"] == -1 :
#                        # yes, start clock in a bit
#                        n["cmdspiseq"]=7
#                        print( "Node %d: Start clock in cmd" % n["node"])
#
#
#                    # TODO clock in a bit for cmdspiseq
#
## TODO save or set the current byte for in or out
## TODO keep in sync with param and byte directly in the function def for in/out????
#
#                            #else:
#                            #        # done with a param
#                            #        n["param"][n["cmdseqp"]=n["byteclk"]


                    
                    #if n["cmdspiseq"] >= 0 :
#                        n["cmdspiseq"]=nodeclockbytein(n)
#                if n["cmdspiseq"] == -1 :
#                            # at end of byte transfer
#
#                            # process sequence steps
#
#                            # TODO progress SPI IN
#                            # TODO progress SPI OUT
#                            # TODO end of in and out
#                            # TODO is this byte a command? if command is empty and we have a byte then yes. Load sequence for the command
#
#                            if n["cmd" ] == 0:
#                                n["cmd" ] = n["byteclk"]
#                                n["cmdseqp"]=0
#                                n["byteclk"]=0
#
#                                # look up sequence for cmd
#                                n["cmdseq"] =[]
#                                for a in seq:
#                                    if a["cmd"] == n["cmd"] :
#                                        n["cmdseq"] = a["seq"]
#                                        print("Command sequence selected: "+str(a["seq"]))
#                                if n["cmdseq"] == []:
#                                    # no command byte seq found to exec to look for a new command again
#                                    n["cmd"]=0
#                                    
#                                
#                    

                # TODO process a sequence step

            if n["cmd"] != 0:
                    # process a sequence
#                    print("Node %d : proc sequence at step %d" % ( n["node"], n["cmdseqp"] ) )
                    
                    if n["cmdspiseq"] == -1 :
                            print( "Run seq starting with "+str(n["cmdseq"])) if netdebug > 0 else 0
                            # no byte shift in/out in progress so process setp
                            
                            try:
                                    # TODO byte in set seq
                                if n["cmdseq"][n["cmdseqp"]] == SEQ_BYTEIN:
                                        print( "Start clock in a byte" ) if netdebug > 0 else 0
                                        n["cmdspiseq"] = SEQ_SPIBIT7
                                        print("set byteclk=0 c") if netdebug > 0 else 0
                                        n["byteclk"] = 0

                                # TODO byte out set seq
                                if n["cmdseq"][n["cmdseqp"]] == SEQ_BYTEOUT:
                                        print( "Start clock out a byte" ) if netdebug > 0 else 0
                                        n["cmdspiseq"] = SEQ_SPIBIT7
# TODO BUG clock out leaves clkstate in wrong place for next command

                                if n["cmdseq"][n["cmdseqp"]] == SEQ_SSTRZNEXT:
                                    print("Clock out stored string content") if netdebug > 0 else 0
                                    s1=n["strings"][str(n["params"][2])]
                                    ct=n["params"]['c']
                                    try:
                                        c=s1[ct]
                                        n["byteclk"]=ord(c)
                                    except:
                                        n["byteclk"]=0
                                    #print(s1)
                                    #print(ct)
                                    #print(c)
                                    
                                    print(n["byteclk"]) if netdebug > 0 else 0
                                    n["params"]['c']=ct+1
                                    n["cmdseqp"]=n["cmdseqp"]+1

                                # TODO do seq init call
                                if n["cmdseq"][n["cmdseqp"]] == SEQ_INIT:
                                    cmd_init(n)
                                    
                                if n["cmdseq"][n["cmdseqp"]] == SEQ_SAVEBYTE:
                                    cmd_savebyte(n)
                                    

                                if n["cmdseq"][n["cmdseqp"]] == SEQ_REPEAT:
                                    print("Repeat marker") if netdebug > 0 else 0
                                    n["cmdseqp"]=n["cmdseqp"]+1

                                if n["cmdseq"][n["cmdseqp"]] == SEQ_UNTILZ:
                                    # go back to the last REQ_REPEAT marker
                                    if n["byteclk"]==0:
                                        print("Now have zero term. Next...") if netdebug > 0 else 0
                                        n["cmdseqp"]=n["cmdseqp"]+1
                                    else:
                                        print("No zero term... Jump back to previous repeat marker..") if netdebug > 0 else 0
                                        while n["cmdseq"][n["cmdseqp"]] != SEQ_REPEAT:
                                            n["cmdseqp"]=n["cmdseqp"]-1
                                            
                                if n["cmdseq"][n["cmdseqp"]] == SEQ_DEBUG:
                                    print(n) 
                                    print(buffers) 
                                    saveSettings()
                                    n["cmdseqp"]=n["cmdseqp"]+1

                                # TODO do seq save params
                                if n["cmdseq"][n["cmdseqp"]] == SEQ_END:
                                    cmd_end(n)
                            
                            except:
                                # might have gone past end of command sequence
                                pass

#                            n["cmdseqp"]=n["cmdseqp"]+1
#                            print(n["params"])
#                            print("Next step")
                            if n["cmdseqp"] > len(n["cmdseq"])-1:
                                # sequence complete, new command
                                n["cmd"]=0
                                print("Command processed. Next cmd...") if netdebug > 0 else 0
                                n["cmdspiseq"] = -1 
                                print(n) if netdebug > 0 else 0
                                print("set byteclk=0 g") if netdebug > 0 else 0
                                n["byteclk"]=0
                                
                                
                                
                                n["cmdseqp"]=0
                                
                                #if clk == 1:
                                #    if n["cmdspiseq"] != 0 :
                                #        if n["cmdspiseq"] > SEQ_SPIINBIT7 :
                                #            # OUT
                                #            n["cmdspiseq"]=nodeclockbyteout(n)
                                
                                            
                            

            n["clkstate"]=clk




# eof

