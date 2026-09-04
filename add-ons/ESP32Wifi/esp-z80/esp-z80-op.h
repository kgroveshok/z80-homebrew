

#define USING_OPS

// internal byte code


#define OP_MAKEWORD 0x01             // takes lsb, msb to create a new word in var x
#define OP_INBYTE 0x02        // done
#define OP_OUTBYTE 0x03    // done
#define OP_BREAKWORD 0x04            // takes 

// byte sub options
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


// back to main op codes
// mark loop start
#define OP_LOOP_START 0x05       //done

// until byte =
#define OP_UNTIL_BYTE 0x06       // done 

// until count
#define OP_UNTIL_COUNT 0x07         // broken

//#define OP_GET_FLAG 0x05
// get flag

//#define OP_SET_FLAG 0x06
// set flag


// open file
#define OP_OPENF 0x08              // done

// close file
#define OP_CLOSEF 0x09


#define OP_STORE_VAR 0x0c

#define OP_VAR_LIT 0x0d          // store a lit val into a var slot



// mark loop start
//#define OP_LOOP_START 0x10    // done

// until byte =
//#define OP_UNTIL_BYTE 0x11           //done

// until count
//#define OP_UNTIL_COUNT 0x12      // need to debug

// open file
//#define OP_OPENF 0x13

// close file
//#define OP_CLOSEF 0x14

// TODO new file ops
#define OP_FILESEEK 0x15
#define OP_FILEREWIND 0x16
#define OP_FILEEOF 0x17

// get/set a config flag

#define OP_CONFIG_SET  0x30     
#define OP_CONFIG_GET  0x31

#define OP_EXEC_FUNC   0x32     // execute a void function

// string ops
#define OP_STR_CLR 0x40
#define OP_STR_ADD 0x41
#define OP_STR_NEXT 0x42


#define OP_SET_VAR_POS 0x43           // set current op var position
#define OP_VAR_POS_INC 0x44           // increment current op var position
#define OP_VAR_POS_DEC 0x45           // decrement current op var position

#define OP_END_PROC 0xff


///// 

int op_vars[2048];   // progressive vars for each get
//byte op_vars_str[255];
//int op_param[5];   // param for an op
byte *current_cmd;
int current_var;
File current_file;
byte *current_loop_start;
int current_loop_count;
int (*exec_func[20])(void);    // user functions for more complex actions using var data

void dump_op_vars(){
  Serial.println("Var dump");
for( int i=0 ; i < 15;i++) {
  Serial.printf(" %d:%d ", i, op_vars[i]);
}

}
// op array
// op code, num of param bytes, function
/*
typedef struct {
const byte op_code;
const uint8_t params;
} OP_PARAM;

OP_PARAM op_param_count[] = { 
{OP_GETWORD, 1 }, // channel
{OP_GETBYTE, 1},   // channel
{OP_PUTBYTE, 2},   // channel, param
{OP_PUTWORD, 2},   // channel param
{OP_LOOP_START,0},
{OP_UNTIL_BYTE,1},   // byte
{OP_UNTIL_COUNT,1},   // count
{OP_OPENF,2},    // file, param
{OP_CLOSEF,0},
{OP_CLEAR_STR,0},
{OP_ADD_TO_STR,0},
{OP_STORE_VAR, 2},  // address param, data param
{0,0}
} ;
*/
// op code processing
/*
byte op_getbyte() {
switch(op_param[0]){
case OP_BYTE_SPI: 
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


void op_store_var() {

}
*/


// eof

