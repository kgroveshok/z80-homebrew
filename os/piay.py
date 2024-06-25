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


# using latch
# ser gpio 0
# g   1
# rck 2
# clk 3



#


D0=Pin(0, mode=Pin.OUT)
D1=Pin(1, mode=Pin.OUT)
D2=Pin(2, mode=Pin.OUT)
D3=Pin(3, mode=Pin.OUT)
D4=Pin(4, mode=Pin.OUT)
D5=Pin(5, mode=Pin.OUT)
D6=Pin(6, mode=Pin.OUT)
D7=Pin(7, mode=Pin.OUT)

SER_PIN=Pin(0, mode=Pin.OUT)
G_PIN=Pin(1, mode=Pin.OUT)
RCK_PIN=Pin(2, mode=Pin.OUT)
LATCH_PIN=Pin(3, mode=Pin.OUT)

#bit 2
CE_MASK=4
CE=Pin( 18, mode=Pin.OUT )
#bit 0
BC1_MASK=1
BC1_PIN=Pin(17, mode=Pin.OUT)
#bit 1
BDIR_MASK=2
BDIR_PIN=Pin(16, mode=Pin.OUT)
#bit 3
RESET_MASK=8
RESET_PIN=Pin(19, mode=Pin.OUT)

bytectl=0

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
    
    
def clockbyteout(bytectl,bytedata):
   # msb first
    print("byte ctl"+str(bytectl))
    for n in range(7,-1,-1):
        
        #print("clock high")
        if ( bytectl & ( 1<<n)) :
            SER_PIN.high()
#            print( " bit "+str(n)+" high  1")
            
        else:
            SER_PIN.low()
#            print( " bit "+str(n)+" low   0")
        #time.sleep(0.025)
        RCK_PIN.high()
        RCK_PIN.low()
        #time.sleep(0.025)
        
    print("byte data"+str(bytedata))
        
    for n in range(7,-1,-1):
        
        #print("clock high")
        if ( bytedata & ( 1<<n)) :
            SER_PIN.high()
 #           print( " bit "+str(n)+" high  1")
            
        else:
            SER_PIN.low()
  #          print( " bit "+str(n)+" low   0")
        #time.sleep(0.025)
        RCK_PIN.high()
        RCK_PIN.low()
        #time.sleep(0.025)
        
    LATCH_PIN.low()
        #print("clock low")
    LATCH_PIN.high()

def set_mode_inactive():
    BC1_PIN.low()
    BDIR_PIN.low()
    bytectl=RESET_MASK
    clockbyteout(bytectl,0)


def set_mode_latch():
    BC1_PIN.high()
    BDIR_PIN.high()
    bytectl=RESET_MASK+BC1_MASK+BDIR_MASK
    clockbyteout(bytectl,0)

def set_mode_write():
    BC1_PIN.low()
    BDIR_PIN.high()
    bytectl=RESET_MASK+BDIR_MASK
    clockbyteout(bytectl,0)

def write_register(reg, value):
    set_mode_latch()
    #writeByte(reg)
    clockbyteout(bytectl,reg)
    set_mode_inactive()
    set_mode_write()
    clockbyteout(bytectl, value)
    #writeByte(value)
    set_mode_inactive()


# latch test
a=0
G_PIN.low()
#while True:
 #   for a in range(0,255):#
 #       clockbyteout(a,a)
  #      time.sleep(0.5)
#   RCK_PIN.high() 
#   if a == 0:
#       a=1
#       SER_PIN.low()
#   else:
#       a=0
#       SER_PIN.high()
#
#   RCK_PIN.low() 
#   LATCH_PIN.high()
#   print(a)
#   time.sleep(.5)
#   LATCH_PIN.low()
   




CE.high()
CE.low()

set_mode_inactive()

clockbyteout(RESET_MASK,0)
time.sleep(.5)
#RESET_PIN.low()
clockbyteout(0,0)
time.sleep(.5)
#RESET_PIN.high()
clockbyteout(RESET_MASK,0)

# // Enable only the Tone Generator on Channel A
#write_register(7, 0b00111000)
#write_register(7, 0b00111110)
#write_register(7, 0b00111100)
# All tone channes on
write_register(7, 0b00111000)
  
#  // Set the amplitude (volume) to maximum on Channel A
#A
write_register(8, 0b00001111)
#B
write_register(9, 0b00001111)
#C
write_register(10, 0b00001111)
#write_register(11, 0b0)
#write_register(12, 0b0)
#write_register(8, 0b00001111)



while True:

    #  // Change the Tone Period for Channel A every 500ms

    write_register(0, 223)
    write_register(1, 1)

    write_register(2, 150)
    write_register(3, 1)
    
    write_register(4, 200)
    write_register(5, 1)
    

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

    #write_register(2, 180)
    #write_register(3, 1)

    time.sleep(.5)
    #delay(500);
      
    write_register(0, 63)
    write_register(1, 1)
    
    write_register(2, 40)
    write_register(3, 1)

    write_register(4, 90)
    write_register(5, 1)


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







