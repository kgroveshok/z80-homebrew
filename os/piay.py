from machine import Pin, lightsleep
import time


# test coding of AY sound chip for porting to Z80

# data bus
# gpio  pin    z80
# 0     1     d0
# 1    2    d1
# 2   4 d2
# 3   5  d3
# 4   6  d4
# 5   7 d5
# 6  9 d6
# 7  10 d7
#

#CE
# a8          25
# a9  18 24        24

# bc1   17   22      29
# bc2         28
# bdir  16  21      27



#

CE=Pin( 18, mode=Pin.OUT )

D0=Pin(0, mode=Pin.OUT)
D1=Pin(1, mode=Pin.OUT)
D2=Pin(2, mode=Pin.OUT)
D3=Pin(3, mode=Pin.OUT)
D4=Pin(4, mode=Pin.OUT)
D5=Pin(5, mode=Pin.OUT)
D6=Pin(6, mode=Pin.OUT)
D7=Pin(7, mode=Pin.OUT)


BC1_PIN=Pin(17, mode=Pin.OUT)
BDIR_PIN=Pin(16, mode=Pin.OUT)
RESET_PIN=Pin(19, mode=Pin.OUT)


def readByte():
    b=D0.value()
    b=b+D1.value()<<1
    b=b+D2.value()<<2
    b=b+D3.value()<<3
    b=b+D5.value()<<5
    b=b+D6.value()<<6
    b=b+D7.value()<<7

    return b

def writeByte(b):
    print(b)
    D0(b&1)
    D1(b&2)
    D2(b&4)
    D3(b&8)
    D4(b&16)
    D5(b&32)
    D6(b&64)
    D7(b&128)

    

def set_mode_inactive():
    BC1_PIN.low()
    BDIR_PIN.low()


def set_mode_latch():
    BC1_PIN.high()
    BDIR_PIN.high()

def set_mode_write():
    BC1_PIN.low()
    BDIR_PIN.high()

def write_register(reg, value):
    set_mode_latch()
    writeByte(reg)
    set_mode_inactive()
    set_mode_write()
    writeByte(value)
    set_mode_inactive()

CE.high()
CE.low()

set_mode_inactive()
RESET_PIN.low()
time.sleep(.5)
RESET_PIN.high()

# // Enable only the Tone Generator on Channel A
write_register(7, 0b00111110)
  
#  // Set the amplitude (volume) to maximum on Channel A
write_register(8, 0b00001111)


while True:

    #  // Change the Tone Period for Channel A every 500ms

    write_register(0, 223)
    write_register(1, 1)

    #delay(500);
      
    write_register(0, 170)
    write_register(1, 1)

    time.sleep(.5)
    #delay(500);
      
    write_register(0, 123)
    write_register(1, 1)

    time.sleep(.5)
    #delay(500);
      
    write_register(0, 102)
    write_register(1, 1)

    time.sleep(.5)
    #delay(500);
      
    write_register(0, 63)
    write_register(1, 1)

    time.sleep(.5)
    #delay(500);
      
    write_register(0, 28)
    write_register(1, 1)

    time.sleep(.5)
    #delay(500);
      
    write_register(0, 253)
    write_register(1, 0)

    time.sleep(.5)
    #delay(500);







