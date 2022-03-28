/*
 * File:   pic-bootstrap.c
 * Author: kgroves
 *
 * Created on 23 March 2022, 18:47
 */
#define _XTAL_FREQ 8000000

#include <xc.h>


// CONFIG
#pragma config FOSC = INTOSCCLK // Oscillator Selection bits (INTRC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RA5/MCLR pin function select (RA5/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config BOREN = OFF      // Brown-out Reset Enable bit (BOD Reset disabled)
#pragma config LVP = OFF         // Low-Voltage Programming Enable bit (RB4/PGM pin has PGM function, low-voltage programming enabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection off)
#pragma config CP = OFF         // Code Protection bits (Program memory code protection off)


// Pin out

// Shift reg: 

// RB0 DS
// RB1 Latch
// RB2 Clock

// Z80 Control:

// RB4: BUSREQ
// RB5: CE
// RB6:  WR
// RB7: Reset


char image[] =  { 0xf3, 0x2a, 0x23, 0x03, 0xf3, 0x22, 0xc3, 0x05, 0x00, 0x00  } ;

void clock_signal(void){

   RB2 = 1;
    __delay_us(100);
   RB2 = 0;
    __delay_us(100);
}
void latch_enable(void)
   {
    // portb 1
    RB1 = 1;
    __delay_us(100);
    RB1 = 0;
    }


void send_data(unsigned int data_out)
{
    int i;
    unsigned hold;
    
    
    for (i=0 ; i<8; i++)
    {
        RB0 = (data_out >> i) & (0x01);
        __delay_ms(50);
        clock_signal();
        
    }
    
}


void main(void) {
     
    
        TRISB = 0; //PORTB as Output 

        PORTB=0;
                 
        while(1)
      {
            
            // Issue busreq signel to take over programming

            RB4 = 1 ;

            __delay_ms(1000); // should test acq but lets wait instead

            // put wr and ce high
            RB5 = 1 ;
            RB6 = 1 ;
                  
            
            
            for( int addr = 0 ; addr < sizeof(image) ; addr++ ) {
                  
                  // dara byte
                  send_data(image[addr]);
                  
                  // Send address (or test count on 16 bits))
                  send_data(addr & 0xff);
                  send_data(addr & 0xff00);
                  
                    latch_enable(); // Data finally submitted              
                    
                  __delay_ms(1000);
                  
                                    // put ce low now data present on bus
                  RB5=0;
                  __delay_ms(500);
                  
                  RB6 = 0;  // write ram
                  __delay_ms(500); 
                  
                  RB6 = 1;  // bring back up
                  __delay_ms(500); 
                  
                  RB5 = 1 ;
                  __delay_ms(500); 
                  
                  
              }
    
    
      
   
            RB4 = 0 ; // release bus reqest
            // issue z80 reset?????
      }            
    return;
}
