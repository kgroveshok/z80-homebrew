

# https://docs.arduino.cc/tutorials/communication/guide-to-shift-out/

#GND (pin 8) to ground,

#    Vcc (pin 16) to 5V

#    OE (pin 13) to ground

#    MR (pin 10) to 5V


#    DS (pin 14) to gpio 0

#    SH_CP (pin 11) to gpio 1

#    ST_CP (pin 12) to gpio 2

from machine import Pin

#//Pin connected to ST_CP of 74HC595
latchPin = Pin(2,mode=Pin.OUT);
#//Pin connected to SH_CP of 74HC595
clockPin = Pin(1,mode=Pin.OUT)
#////Pin connected to DS of 74HC595
dataPin = Pin(0,mode=Pin.OUT)
# pin MR 10
resetPin = Pin(3,mode=Pin.OUT);

sr = 0
from time import sleep
#sleep(2)

def shiftout(byte):
    resetPin.low()
    sleep(0.01)
    resetPin.high()
    
    latchPin.low()
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
    


while True:
    # Increment the value of the shift register by 1
    print("cycle "+str(sr))
    shiftout(sr)

    sr=sr+1
    if sr>255:
        sr=0
    sleep(0.01)


