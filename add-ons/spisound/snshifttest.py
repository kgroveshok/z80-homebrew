

# https://docs.arduino.cc/tutorials/communication/guide-to-shift-out/
#https://danceswithferrets.org/geekblog/?p=93

# shift reg
#GND (pin 8) to ground,

#    Vcc (pin 16) to 5V

#    OE (pin 13) to ground

#    MR (pin 10) to 5V


#    DS (pin 14) to gpio 0

#    SH_CP (pin 11) to gpio 1

#    ST_CP (pin 12) to gpio 2


# sound chip

# d0-d7 on shift go to reversed d0-d7 on sound
# ce on sound 6 to gnd
# we on sound 5 to gpio 4




from machine import Pin

#//Pin connected to ST_CP of 74HC595
latchPin = Pin(2,mode=Pin.OUT);
#//Pin connected to SH_CP of 74HC595
clockPin = Pin(1,mode=Pin.OUT)
#////Pin connected to DS of 74HC595
dataPin = Pin(0,mode=Pin.OUT)
# pin MR 10
resetPin = Pin(3,mode=Pin.OUT);

soundPin = Pin(4,mode=Pin.OUT);

sr = 0
from time import sleep
#sleep(2)

def shiftout(byte):
    resetPin.low()
    sleep(0.01)
    
    resetPin.high()
    soundPin.high()
     
    latchPin.low()
    sleep(0.01)
    
    for i in range(8,0,-1):

        # Write the new value to the shift register
        
        clockPin.low()
        sleep(0.01)
        
        if ( byte & ( 1<<i)) :
          dataPin.high()
          print("pin "+str(i)+" high")
        else:
          dataPin.low()
          print("pin "+str(i)+" low")
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
    
    

def soundTog():

    soundPin.low()
    sleep(0.01)
    soundPin.high()
    sleep(0.01)
    soundPin.low()
    sleep(0.01)
    

def offAllChannels():
  shiftout(0x9f);
  shiftout(0xbf);
  shiftout(0xdf);
  shiftout(0xff);
   
    
offAllChannels()
shiftout(0x83)
#soundTog()
shiftout(0x12) # // sets channel 0 tone to 0x123
#soundTog()
shiftout(0x90)   #; // sets channel 0 to loudest possible
#soundTog()
#shiftout(0x9F)
#soundTog()

while False:
    # Increment the value of the shift register by 1
    print("cycle "+str(sr))
    shiftout(sr)

    sr=sr+1
    if sr>255:
        sr=0
    sleep(0.01)


