
// internal byte code


#define OP_GETWORD 0x0a
#define OP_GETBYTE 0x01
#define OP_PUTBYTE 0x07
#define OP_PUTWORD 0x0b

// byte via spi
#define OP_BYTE_SPI 0x01 
// byte from file
#define OP_BYTE_FILE 0x02 
// byte from socket
#define OP_BYTE_SOCK 0x03 
// byte from var location
#define OP_BYTE_VARLOC 0x04 
// byte from uart
#define OP_BYTE_UART 0x05

// mark loop start
#define OP_LOOP_START 0x02

// until byte =
#define OP_UNTIL_BYTE 0x03

// until count
#define OP_UNTIL_COUNT 0x04

//#define OP_GET_FLAG 0x05
// get flag

//#define OP_SET_FLAG 0x06
// set flag


// open file
#define OP_OPENF 0x08

// close file
#define OP_CLOSEF 0x09

// clear string
#define OP_CLEAR_STR 0x20
#define OP_ADD_TO_STR 0x21

#define OP_STORE_VAR 0x22

// op array
// op code, num of param bytes, function

typedef struct {
const byte op_code,
const uint8_t params
} OP_PARAM;

OP_PARAM op_param_count[] = { 
{OP_GETWORD, 1 },
{OP_GETBYTE, 1},
{OP_PUTBYTE, 1},
{OP_PUTWORD, 1},
{OP_LOOP_START,0},
{OP_UNTIL_BYTE,1},
{OP_UNTIL_COUNT,1},
{OP_OPENF,1},
{OP_CLOSEF,0},
{OP_CLEAR_STR,0},
{OP_ADD_TO_STR,0},
{OP_STORE_VAR, 1},
{0,0}
} ;

// op code processing

int op_vars_int[10];
byte op_vars_str[255];
int op_param[5];

void op_store_var() {

}


int op_getword(){
byte a, b;
a=op_getbyte();
b=op_getbyte();
return (a<<8)+b; 
}

void op_putword( int word) {
byte a, b;

op_putbyte(a);
op_putbyte(b);
}

byte op_getbyte() {
switch(op_param[0]){
case OP_BYTE_SPI;
// byte via spi
break;
/// byte from file
//#define OP_BYTE_FILE 0x02 
// byte from socket
//#define OP_BYTE_SOCK 0x03 
// byte from var location
//#define OP_BYTE_VARLOC 0x04 
// byte from uart
//#define OP_BYTE_UART 0x05
}
}

void op_putbyte(byte a) {
// byte via spi
//#define OP_BYTE_SPI 0x01 
/// byte from file
//#define OP_BYTE_FILE 0x02 
// byte from socket
//#define OP_BYTE_SOCK 0x03 
// byte from var location
//#define OP_BYTE_VARLOC 0x04 
// byte from uart
//#define OP_BYTE_UART 0x05
}


// mark loop start
#define OP_LOOP_START 0x02

// until byte =
#define OP_UNTIL_BYTE 0x03

// until count
#define OP_UNTIL_COUNT 0x04

//#define OP_GET_FLAG 0x05
// get flag

//#define OP_SET_FLAG 0x06
// set flag


// open file
#define OP_OPENF 0x08

// close file
#define OP_CLOSEF 0x09


int processCmd(){
// process the op array for the command

} 


int isCmd(byte a) {
// scan op array for commands we want to run. 
// if a command then run it otherwise return 0

for( int i=0; op_array[i][cmd] != 0 ; i++) {
	if( op_array[i

}


return 0;
}

// eof

