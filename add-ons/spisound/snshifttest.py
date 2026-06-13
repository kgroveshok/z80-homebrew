

# https://docs.arduino.cc/tutorials/communication/guide-to-shift-out/
#https://danceswithferrets.org/geekblog/?p=93

# shift reg
#GND (pin 8) to ground,

#    Vcc (pin 16) to 5V

#    OE (pin 13) to ground   see below

#    MR (pin 10) to 5V


#    DS (pin 14) to gpio 0

#    SH_CP (pin 11) to gpio 1

#    ST_CP (pin 12) to gpio 2


# sound chip

# d0-d7 on shift go to reversed d0-d7 on sound
# ce on sound 6 to gnd see below
# we on sound 5 to gpio 4

# going to try spi ce to:
# ce to shift reg
# ce to sn 
# ce to inverter
#    out to shift reg latch
#    out to sn we
#   shift
# will there be enough of a delay to apply changes?


# $01 cartdev
#: latch spicel spio spiceh spicel  ; 

#$74 $12 $90 $1F $07 $05 count $00 do latch $01 delay loop 

#$E9 $AB $7B $66 $3F $1C $FD count $00 do latch $01 delay loop 

#* $74 = 01110100 (in binary)
#* $12 = 00010010 (in binary)
#* $90 = 10010000 (in binary)
#* $1F = 00011111 (in binary)
#* $07 = 00000111 (in binary)
#* $05 = 00000101 (in binary)
#* $E9 = 11101001 (in binary)
#* $AB = 10101011 (in binary)
#* $7B = 01111011 (in binary)
#* $66 = 01100110 (in binary)
#* $3F = 00111111 (in binary)
#* $1C = 00011100 (in binary)
#* $FD = 11111101 (in binary)

# $8f $80 do spicel i spio spiceh spicel $01 delay loop
# : note $80 + spicel spio spiceh spicel ;
# : vol $90 + spicel spio spiceh spicel ;

from machine import Pin

#//Pin connected to ST_CP of 74HC595
latchPin = Pin(2,mode=Pin.OUT);
#//Pin connected to SH_CP of 74HC595
clockPin = Pin(1,mode=Pin.OUT)
#////Pin connected to DS of 74HC595
dataPin = Pin(0,mode=Pin.OUT)
# pin MR 10
resetPin = Pin(3,mode=Pin.OUT)

soundPin = Pin(4,mode=Pin.OUT)

cePin=Pin(5, mode=Pin.OUT)

sr = 0
from time import sleep
#sleep(2)

resetPin.high()

def shiftout(byte):
    print(byte)
    soundPin.high()
    #resetPin.low()
    #sleep(0.01)
    
    #resetPin.high()
    
     
    latchPin.low()
   # sleep(0.01)
    
#    for i in range(0,8):
    for i in range(8,-1,-1):

        # Write the new value to the shift register
        
        clockPin.low()
        #sleep(0.01)
        
        if ( byte & ( 1<<i)) :
          dataPin.high()
          #print("pin "+str(i)+" high")
        else:
          dataPin.low()
          #print("pin "+str(i)+" low")
        #sleep(0.01)
        clockPin.high()
        #sleep(0.01)
        
       # latchPin.low()
       # sleep(1)
       # latchPin.high()
    
    #print("latch high")
    latchPin.high()
    soundTog()
    #sleep(0.01)
    #soundPin.low()
    #sleep(0.01)
    #soundPin.high()
    #sleep(0.01)
    
    

D0=Pin(8, mode=Pin.OUT)
D1=Pin(9, mode=Pin.OUT)
D2=Pin(10, mode=Pin.OUT)
D3=Pin(11, mode=Pin.OUT)
D4=Pin(12, mode=Pin.OUT)
D5=Pin(13, mode=Pin.OUT)
D6=Pin(14, mode=Pin.OUT)
D7=Pin(15, mode=Pin.OUT)




def writebyte(b):
    print("writebyte")
    print(b)
    D0(b&1)
    D1(b&2)
    D2(b&4)
    D3(b&8)
    D4(b&16)
    D5(b&32)
    D6(b&64)
    D7(b&128)

def soundTog():
    #print("sound high")
    soundPin.high()
    #sleep(0.1)
    #print("sound low")
    soundPin.low()
    sleep(0.1)
    soundPin.high()
    #print("sound high")
    #sleep(0.1)

def outbyte(b):
#    cePin.low()
    shiftout(b)
    #writebyte(b)
#    cePin.high()
    

def offAllChannels():
  outbyte(0x9f);
  outbyte(0xbf);
  outbyte(0xdf);
  outbyte(0xff);
   
    
#offAllChannels()
#shiftout(0x83)
#soundTog()
#shiftout(0x12) # // sets channel 0 tone to 0x123
#soundTog()
#shiftout(0x90)   #; // sets channel 0 to loudest possible
#soundTog()
#shiftout(0x9F)
#soundTog()


#
SOUND_LATCH=0b10000000
SOUND_DATA= 0
SOUND_CH0= 0    
SOUND_CH1=  0b00100000
SOUND_CH2=  0b01000000   
SOUND_CH3=  0b01100000    
SOUND_VOL=  0b00010000
SOUND_TONE= 0


cePin.low()


#sound.high()

#outbyte(0x74)
#outbyte(0x12)
#outbyte(0x90)

#outbyte( SOUND_DATA + SOUND_CH0 + SOUND_VOL + 0b1111)
#sleep(.25	)
#outbyte( SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b0111)
#sleep(.25)
#outbyte(SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b0101)
#sleep(.5)

while True:
    for a in range(0,255):
        print(a)
        outbyte(a)
        sleep(0.1)

while False:
    outbyte(128)
    sleep(5)
    outbyte(0)
    sleep(5)
    outbyte(1)
    sleep(5)
    outbyte(2)
    sleep(5)
    outbyte(4)
    sleep(5)
    outbyte(8)
    sleep(5)
    outbyte(16)
    sleep(5)
    outbyte(32)
    sleep(5)
    outbyte(64)
    sleep(5)
    outbyte(128)
    sleep(5)
while False:
    for i in range(128,128+16):
        outbyte(i)
        sleep(0.25)

offAllChannels()
#print("vol")
#outbyte(0x90)
    
    


while False:
    print("vol")
    outbyte(0x90)

    print("n1")
    outbyte(0x80)
    sleep(1)
    print("vol")
    outbyte(0x90)

    print("n2")
    outbyte(0x86)
    sleep(1)
    print("vol")
    outbyte(0x90)

    print("n3")
    outbyte(0x8e)
    
    sleep(1)
        #offAllChannels()
        #sleep(0.25)
    
    
    
#outbyte( SOUND_DATA + SOUND_CH0 + SOUND_VOL + 0b1111)#

#outbyte( SOUND_LATCH + SOUND_CH0 + 0b1111)
#outbyte( 0b111111)
#sleep(1)
#outbyte( SOUND_LATCH + SOUND_CH0 + 0b1111)
#outbyte( 0b001111)
offAllChannels()

outbyte(0x94)
######## This code works with sound chip
while False:
    
    print("lllllllllllllll")
    outbyte(0x83)
    outbyte(0x12)


    sleep(0.25)
    print("ffffffffffffffffff")
    #offAllChannels()
    #outbyte(0x90)
    outbyte(0x82)
    outbyte(0x16)
    sleep(0.25)
    print("aaaaaaaaaaaaaaaaa")
    outbyte(0x83)
    outbyte(0x09)

    sleep(0.25)
    #offAllChannels()

#print("vol")
#outbyte(3)
#print("nt1")
#outbyte(0x8d)
#outbyte(0xda)
#sleep(2)
#offAllChannels()
#sleep(2)
#print("nt2")
#outbyte(3)
#outbyte(0x8d)
#outbyte(0xc0)
#sleep(2)
#offAllChannels()

while False:

        #  // Change the Tone Period for Channel A every 500ms


        #outbyte(223)
        #write_register(1, 1)

        #delay(500);
          
        #outbyte(170)
        #write_register(1, 1)

        #sleep(.1)
        #delay(500);
          
        #outbyte(123)
        #write_register(1, 1)

        #sleep(.1)
        #delay(500);
          
        #outbyte(102)
        #write_register(1, 1)
        #sleep(.1)
        #delay(500);
          
        #outbyte(63)
        #write_register(1, 1)

        #sleep(.1)
        #delay(500);
          
        #outbyte(28)
        ##write_register(1, 1)

        #sleep(.1)
        #delay(500);
          
        #outbyte(253)
        #write_register(1, 0)

        #sleep(.1)
        #delay(500);
        print("off")
        #offAllChannels()
        print("off")
        sleep(1)
        print("h1")
        outbyte( SOUND_LATCH + SOUND_CH0 + SOUND_VOL + 0b1111)
        #sleep(.25)
        #outbyte( SOUND_LATCH + SOUND_CH0 + SOUND_TONE + 0b0111)
                #outbyte( SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b0111)
        sleep(1)
        print("h1a")
        outbyte( SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b0111)
        #outbyte(5)
        #outbyte(SOUND_LATCH + SOUND_CH0 + SOUND_TONE + 0b0101)
        #outbyte(SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b0101)
        sleep(1)
        print("h2")
        #outbyte(SOUND_LATCH + SOUND_CH0 + SOUND_TONE + 0b0001)
        #sleep(1)
        outbyte( SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b0011)
        #outbyte(0)
        #outbyte(SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b1001)
        sleep(1)


while False:
    # Increment the value of the shift register by 1
    print("cycle "+str(sr))
    shiftout(sr)

    sr=sr+1
    if sr>255:
        sr=0
    sleep(0.01)


