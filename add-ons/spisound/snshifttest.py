

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
    sleep(0.01)
    
    #for i in range(0,8):
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
        sleep(0.01)
        clockPin.high()
        sleep(0.01)
    
    print("latch")
    latchPin.high()
    sleep(0.01)
    soundPin.low()
    sleep(0.01)
    soundPin.high()
    sleep(0.01)
    
    

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

    soundPin.low()
    sleep(0.01)
    soundPin.high()
    sleep(0.01)
    soundPin.low()
    sleep(0.01)

def outbyte(b):
    cePin.low()
    shiftout(b)
    writebyte(b)
    cePin.high()
    

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
SOUND_CH1= 0b0100000
SOUND_CH2=0b1000000   
SOUND_CH3= 0b1100000    
SOUND_VOL= 0b10000
SOUND_TONE= 0


cePin.low()


#sound.high()

outbyte(0x74)
outbyte(0x12)
outbyte(0x90)

outbyte( SOUND_DATA + SOUND_CH0 + SOUND_VOL + 0b1111)
sleep(.25	)
outbyte( SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b0111)
sleep(.25)
outbyte(SOUND_DATA + SOUND_CH0 + SOUND_TONE + 0b0101)
sleep(.5)

#sleep(5)
#shiftout(128)
#sleep(5)
#shiftout(1)
#sleep(5)


while True:

        #  // Change the Tone Period for Channel A every 500ms


        outbyte(223)
        #write_register(1, 1)

        #delay(500);
          
        outbyte(170)
        #write_register(1, 1)

        sleep(.1)
        #delay(500);
          
        outbyte(123)
        #write_register(1, 1)

        sleep(.1)
        #delay(500);
          
        outbyte(102)
        #write_register(1, 1)
        sleep(.1)
        #delay(500);
          
        outbyte(63)
        #write_register(1, 1)

        sleep(.1)
        #delay(500);
          
        outbyte(28)
        #write_register(1, 1)

        sleep(.1)
        #delay(500);
          
        outbyte(253)
        #write_register(1, 0)

        sleep(.1)
        #delay(500);




while False:
    # Increment the value of the shift register by 1
    print("cycle "+str(sr))
    shiftout(sr)

    sr=sr+1
    if sr>255:
        sr=0
    sleep(0.01)


