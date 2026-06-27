#include <Arduino.h>
#include <WiFi.h>
#include <NetworkClient.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include "FS.h"
#include <SPIFFS.h>
#include <WiFiS3.h>
//#include "esp-z80-op.h"
#include "esp-z80-file.h"

#define SPI_STORAGE_READ 0x03
// OP_GET_WORD, OP_BYTE_SPI, OP_STORE_VAR, 1, OP_GET_BYTE, OP_BYTE_VARLOC, 1, OP_PUT_BYTE, OP_BYTE_SPI 
#define SPI_STORAGE_WRITE 0x02
#define SPI_STORAGE_WREN 0x06

#define SPI_ESP_POWERED 0x10
#define SPI_ESP_CONFIG 0x14
#define SPI_ESP_CONSOLE 0x15

// wifi

#define SPI_SET_SSID 0x20
// OP_LOOP_START, OP_GET_BYTE, OP_BYTE_SPI, OP_PUT_BYTE, OP_BYTE_VARLOC, OP_UNTIL_BYTE, 0, 
#define SPI_SET_PASS 0x21
#define SPI_GET_IP 0x22
#define SPI_CREATE_PROF 0x23
#define SPI_SELECT_PROF 0x24
#define SPI_LIST_PROF 0x25
#define SPI_WIFI_CONNECT 0x26
#define SPI_WIFI_DISCON 0x27

// Internet

#define SPI_SET_ITARG  0x30
#define SPI_SEND_ICON 0x33
#define SPI_PUTC_ICON 0x34
#define SPI_GETC_ICON 0x35

// Buffers
#define SPI_GET_POOL 0x40
#define SPI_PUT_POOL 0x41
#define SPI_SELECT_POOL 0x42
#define SPI_CLR_POOL 0x43
#define SPI_UART_OUT_POOL 0x45
#define SPI_UART_IN_POOL 0x46

// UART

#define SPI_PUTC 0x60
#define SPI_GETC 0x61





// wifi

String wifi_ssid = "";
String wifi_password = "";
const char *fna = "That feature is not available right now!";

// Profile/Page ids

int storage_page = 0;
int wifi_profile = 0;
int internet_profile = 0;
int pool_page = 0;

// System configuration switches

int debug_level = 1;
int config_byte = 1;
int use_webserver = 1;

byte storage_block[48000];

//char *wifi_profile="Default";

WebServer server(80);

byte cmd = 0;
byte tmpByte;
int storeAddr;
byte storeData;
String tmpString;
int tmpInt;

WifiClient TCP_client;



int wifi_ready = 0;
const int led = LED_BUILTIN;

const int spi_ce_pin = 10;
const int spi_do_pin = 9;
const int spi_sck_pin = 8;
const int spi_di_pin = 7;

// Signal helper functions

inline int isCLK() {
  return digitalRead(spi_sck_pin);
}
inline int getDO() {
  return digitalRead(spi_do_pin);
}
inline void setDI(int b) {
  digitalWrite(spi_di_pin, b);
}
inline int isCE2() {
  return digitalRead(spi_ce_pin);
}
void fromCLKHigh() {  //Serial.println("In isCLKHigh");
  while (isCLK()) {};
  //Serial.println("Done");
}
int fromCLKLowIn() {
  int d;
  //Serial.println("In isCLKLowIn");
  while (!isCLK()) { d = getDO(); };
  //Serial.println("Done");
  return d;
}
void fromCLKLowOut() {
  //Serial.println("In isCLKLowOut");
  while (!isCLK()) {};
  //Serial.println("Done");
}
void isCE2en() {
  while (isCE2()) {}
}


//: bitin if 1 + then ;

//: rcvspibyte 0 8 1 do isclkhigh isclklowin bitin 1 lshift loop isclkhigh isclklowin bitin ;
byte rcvspibyte() {
  byte b = 0;
  int d;
  for (int i = 0; i < 7; i++) {
    fromCLKHigh();
    if (fromCLKLowIn() == 1) {
      b++;
      //Serial.printf("\n%d: 1 ", i);
    }  //else { Serial.printf("\n%d: 0 ", i);}
    b = b << 1;
  }
  fromCLKHigh();
  if (fromCLKLowIn() == 1) {
    b++;
    //Serial.printf("\nE: 1 ");
  }  //else { Serial.printf("\nE: 0 ");}

  //Serial.printf("\n");
  return b;
}

String rcvspistrz() {
  String s = "";
  byte ar[255];
  byte c;
  int si = 0;
  while ((c = rcvspibyte()) != 0) { ar[si++] = c; }
  ar[si] = 0;

  return String((char *)ar);
}

//: monitor begin rcvspibyte emit 0 = until ;

//( sending out )

void sndspibyte(byte b) {
  //Serial.printf("\nSend byte: %d", (int) b);
  fromCLKHigh();
  for (int i = 0; i < 8; i++) {
    //    Serial.printf("\n%d: %d", i, b & 128);
    setDI(b & 128);
    fromCLKLowOut();
    b = b << 1;
    fromCLKHigh();
  }
  //Serial.println("Done");
}


void sndspistrz(String s) {
  int i;
  for (i = 0; i < s.length(); i++) {
    sndspibyte(s[i]);
  }
  sndspibyte(0);
}



void loadCfg() {
  if (debug_level) { Serial.println("Loading configuration..."); }
  String r;
  r = readFile(SPIFFS, "/0wifi_ssid.txt");
  wifi_ssid = r;
  r = readFile(SPIFFS, "/0wifi_password.txt");
  wifi_password = r;

  if (wifi_ssid.length() > 0 and wifi_password.length() > 0) { wifi_ready = 1; }

  r = readFile(SPIFFS, "/config.txt");
  Serial.println(r);
  if (r.length() == 0) {
    SaveCfg();
  }

  config_byte = r.toInt();

  // TODO set server config flags
  // TODO enable disable webserver on use_webserver

  r = readFile(SPIFFS, "/cur_storage.txt");
  if (r.length() == 0) {
    SaveCurStorage();
  }

  storage_page = r.toInt();

  r = readFile(SPIFFS, "/cur_wprofile.txt");
  if (r.length() == 0) {
    SaveCurWProfile();
  }

  int wifi_profile = r.toInt();

  r = readFile(SPIFFS, "/cur_iprofile.txt");
  if (r.length() == 0) {
    SaveCurIProfile();
  }

  int internet_profile = r.toInt();

  r = readFile(SPIFFS, "/cur_pool.txt");
  if (r.length() == 0) {
    SaveCurPool();
  }

  int pool_page = r.toInt();
}
void SaveCfg() {
  if (debug_level) { Serial.println("Saving config.txt..."); }
  writeFile(SPIFFS, "/config.txt", String(config_byte));
}

void SaveCurStorage() {
  if (debug_level) { Serial.println("Saving cur_storage.txt..."); }
  writeFile(SPIFFS, "/cur_storage.txt", String(storage_page));
}

void SaveCurWProfile() {
  if (debug_level) { Serial.println("Saving cur_wprofile..."); }
  writeFile(SPIFFS, "/cur_wprofile.txt", String(wifi_profile));
}

void SaveCurIProfile() {
  if (debug_level) { Serial.println("Saving cur_iprofile,txt..."); }
  writeFile(SPIFFS, "/cur_iprofile.txt", String(internet_profile));
}

void SaveCurPool() {
  if (debug_level) { Serial.println("Saving cur_pool.txt..."); }
  writeFile(SPIFFS, "/cur_pool.txt", String(pool_page));
}


// Webserver support

void handleRoot() {
  digitalWrite(led, 1);
  server.send(200, "text/plain", "hello from esp32!");
  digitalWrite(led, 0);
}

void handleNotFound() {
  digitalWrite(led, 1);
  String message = "File Not Found\n\n";
  message += "URI: ";
  message += server.uri();
  message += "\nMethod: ";
  message += (server.method() == HTTP_GET) ? "GET" : "POST";
  message += "\nArguments: ";
  message += server.args();
  message += "\n";
  for (int i = 0; i < server.args(); i++) {
    message += " " + server.argName(i) + ": " + server.arg(i) + "\n";
  }
  server.send(404, "text/plain", message);
  digitalWrite(led, 0);
}



void setup(void) {
  pinMode(led, OUTPUT);
  digitalWrite(led, 0);
  Serial.begin(115200);

  // configure interface to z80 spi
  pinMode(spi_ce_pin, INPUT);
  pinMode(spi_do_pin, INPUT);
  pinMode(spi_sck_pin, INPUT);
  
// Only set to output once we have CE so as not to corrupt the singal
   pinMode(spi_di_pin, INPUT);
   //pinMode(spi_di_pin, OUTPUT);

  if (!SPIFFS.begin(FORMAT_SPIFFS_IF_FAILED)) {
    Serial.println("SPIFFS Mount Failed");
    return;
  }

  // Load persistent config
  listDir(SPIFFS, "/", 0);
  loadCfg();

  //  listDir(SPIFFS, "/", 0);
  //  writeFile(SPIFFS, "/hello.txt", "Hello ");
  //  appendFile(SPIFFS, "/hello.txt", "World!\r\n");
  //  readFile(SPIFFS, "/hello.txt");
  //  renameFile(SPIFFS, "/hello.txt", "/foo.txt");
  //  readFile(SPIFFS, "/foo.txt");
  //  deleteFile(SPIFFS, "/foo.txt");
  //  testFileIO(SPIFFS, "/test.txt");
  //  deleteFile(SPIFFS, "/test.txt");










  if (wifi_ready) {
    WiFi.mode(WIFI_STA);
    WiFi.begin(wifi_ssid, wifi_password);
    Serial.println("");

    // Wait for connection
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
    }
    Serial.println("");
    Serial.print("Connected to ");
    Serial.println(wifi_ssid);
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    if (MDNS.begin("esp32")) {
      Serial.println("MDNS responder started");
    }

    server.on("/", handleRoot);

    server.on("/inline", []() {
      server.send(200, "text/plain", "this works as well");
    });

    server.onNotFound(handleNotFound);
    if (use_webserver) {
      server.begin();
      Serial.println("HTTP server started");
    } else {
      Serial.println("HTTP server configured to not run. Skipped start up.");
    }
  } else {
    Serial.println("Wifi not configured. Skipping HTTP server startup");
  }


  Serial.println("Waiting for CE2 line...");
}

void loop(void) {

  if (wifi_ready) {
    if (use_webserver) {
      server.handleClient();
    }
  }
  //delay(2);  //allow the cpu to switch to other tasks


  if (!isCE2()) {
    // Get a command byte
   pinMode(spi_di_pin, OUTPUT);
    if (debug_level) { Serial.printf("\nReady for command byte..."); }
    cmd = rcvspibyte();
    if (debug_level) { Serial.printf("\nCommand byte seen: %d", cmd); }


    // Command processing
digitalWrite(led, 1);
    switch (cmd) {
      case 0:
        break;
      case SPI_STORAGE_READ:
        if (debug_level) { Serial.printf("O"); }
        storeAddr = (int)rcvspibyte();
        storeAddr = storeAddr << 8;
        storeAddr += (int)rcvspibyte();

        storeData = storage_block[storeAddr];
        sndspibyte(storeData);
        break;
      case SPI_STORAGE_WRITE:
        if (debug_level) { Serial.printf("I"); }
        storeAddr = (int)rcvspibyte();
        storeAddr = storeAddr << 8;
        storeAddr += (int)rcvspibyte();
        storeData = rcvspibyte();
        storage_block[storeAddr] = storeData;
        break;
    case SPI_STORAGE_WREN:
    // Ignore this byte 
        //tmpByte = rcvspibyte();
        //if( tmpByte == SPI_STORAGE_WRITE) {
        //  if (debug_level) { Serial.printf("I"); }
        //storeAddr = (int)rcvspibyte();
        //storeAddr = storeAddr << 8;
        //storeAddr += (int)rcvspibyte();
        //storeData = rcvspibyte();
        //storage_block[storeAddr] = storeData;
        //}
      break;
      case SPI_ESP_POWERED:
        sndspibyte(1);
        break;
      case SPI_ESP_CONFIG:
        if (debug_level) { Serial.println("SPI_DEBUG"); }
        tmpByte = rcvspibyte();
        if (debug_level) { Serial.printf("\nDebug set to level: %d", tmpByte); }
        debug_level = (int)tmpByte;
        // TODO Save current level to file
        break;
      case SPI_ESP_CONSOLE:
           Serial.setTimeout(9000); 
          while((tmpByte=Serial.read())!='q' ) {
            Serial.println("Console Mode. Use ? for help.");
          while(Serial.available() == 0 ){}
              
            switch( tmpByte  ) {
                case '?':
                    Serial.println("q=exit, l=list files,r=display file");
                    break;
                case 'l':
                   listDir(SPIFFS, "/", 0);
                  break;
                  case 'r':
                    Serial.println("Enter file name to view");
                    tmpString=Serial.readStringUntil(13);
                    tmpString.trim();
        tmpString = readFile(SPIFFS, "/" + tmpString);            
                    Serial.println(tmpString);
                                        break;
                 case 'q':
                    break;

            }
Serial.println("Console Mode. Use ? for help.");

          }
          Serial.println("Exiting console mode");
Serial.setTimeout(1000); 
        break;

        // Wifi

      case SPI_SET_SSID:

        tmpString = String(rcvspistrz());
        if (debug_level) { Serial.printf("\nSet SSID: %s", tmpString); }

        writeFile(SPIFFS, "/" + String(wifi_profile) + "wifi_ssid.txt", tmpString);
        break;
      case SPI_SET_PASS:
        tmpString = String(rcvspistrz());
        if (debug_level) { Serial.printf("\nSet password: %s", tmpString); }

        writeFile(SPIFFS, "/" + String(wifi_profile) + "wifi_password.txt", tmpString);
        break;
      case SPI_GET_IP:

        if (debug_level) { Serial.printf("\nGet IP: %s", WiFi.localIP()); }


        sndspistrz(String(WiFi.localIP()));

        break;
      case SPI_SELECT_PROF:
        tmpByte = rcvspibyte();
        wifi_profile = (int)tmpByte;
        SaveCurWProfile();
        break;
        //        case SPI_LIST_PROF:
        //
        //        break;
        //       case SPI_WIFI_CONNECT:
        //
        //        break;
        //        case SPI_WIFI_DISCON:
        //
        //        break;

        // Buffers
      case SPI_GET_POOL:
        if (debug_level) { Serial.printf("\nSend string from pool %d", pool_page); }

        tmpString = readFile(SPIFFS, "/" + String(pool_page) + "pool.txt");
        if (debug_level) { Serial.println(tmpString); }
        sndspistrz(tmpString);


        // TODO Consume pool?
        break;
      case SPI_PUT_POOL:
        // Get string to add to pool

        tmpString = String(rcvspistrz());
        if (debug_level) { Serial.println("Got string: " +tmpString); }
        if (debug_level) { Serial.printf("\nAppend to pool %d", pool_page); }
        appendFile(SPIFFS, "/" + String(pool_page) + "pool.txt", tmpString);
        break;
      case SPI_SELECT_POOL:
        tmpByte = rcvspibyte();
        pool_page = (int)tmpByte;
        SaveCurPool();
        if (debug_level) { Serial.printf("\nSelect pool %d", pool_page); }
        break;
      case SPI_CLR_POOL:
        if (debug_level) { Serial.printf("\nClear pool %d", pool_page); }
        deleteFile(SPIFFS, "/" + String(pool_page) + "pool.txt");
        break;

      case SPI_UART_OUT_POOL:
        if (debug_level) { Serial.printf("\nContents of pool %d", pool_page); }
        tmpString = readFile(SPIFFS, "/" + String(pool_page) + "pool.txt");
        Serial.println(tmpString);

        break;
      case SPI_UART_IN_POOL:
        if (debug_level) { Serial.printf("\nAdd to pool from UART %d", pool_page); }

        while (Serial.available() == 0) {}
        tmpString = Serial.readString();
        tmpString.trim();
        appendFile(SPIFFS, "/" + String(pool_page) + "pool.txt", tmpString);

        if (debug_level) { Serial.printf("\nAdded string %s", tmpString); }
        break;

      case SPI_PUTC:
        if (debug_level) { Serial.println("SPI_PUTC"); }
        tmpByte = rcvspibyte();
        Serial.printf("%c", tmpByte);
        break;
        //   case SPI_GETC:
        //     break;

      case SPI_SET_ITARG:
		
        // Get string to add to pool

        tmpString = String(rcvspistrz());
        if (debug_level) { Serial.println("Got IP/Socket: " +tmpString); }

	// TODO Split on colon

	String ip=tmpString.substr(tmpString.IndexOf(":")+1));
	String sock=tmpString.substr(0, tmpString.IndexOf(":")-1));

        if (debug_level) { Serial.println(ip); Serial.println(sock); }
	if( TCP_client.connected() ) {
		TCP_client.stop();
	}
	if( TCP_client.connect( ip,sock) ) {
		
        if (debug_level) { Serial.println("Connected to service"); }
	} else {
        if (debug_level) { Serial.println("Connection failed to service"); }
}
		break;
case SPI_SEND_ICON:
        tmpString = String(rcvspistrz());
        if (debug_level) { Serial.println("Send to service: " +tmpString); }
	TCP_client.writer(tmpString);
	TCP_client.flush();
	break;
case SPI_GETC_ICON:
	if TCP_client.avaiable()) {
char c=TCP_client.read();
sendbyte(c);
} else { sndbyte(0)};
      default:
        // statements
        Serial.printf("\n%d: %s", cmd, fna);

        break;
    }
    digitalWrite(led, 0);
   pinMode(spi_di_pin, INPUT);
  }
}

/*

hex
 
( ce 10 do 9 sck 8 di 7 )
: sck? 8 digitalread ;
: do? 9 digitalread ;
: di 7 pin ;
: ce2? 10 digitalread ;
: isclkhigh begin sck? until ;
: isclklowin 0 begin drop do? sck? 0 = until ;
: isclklowout begin sck? 0 = until ;
: isce2en   begin ce2? 0 = until ;
: bitin if 1 + then ;

: rcvspibyte 0 8 1 do isclkhigh isclklowin bitin 1 lshift loop isclkhigh isclklowin bitin ;

: rcvstrz ( begin rcvspibyte 0 = until) ;

: monitor begin rcvspibyte emit 0 = until ;

( sending out )

: sndspibyte isclkhigh 8 1 do dup 80 and 80 = if high ." 1" else low ." 0" then di 1 lshift isclklowout isclkhigh loop ;

( scan for spi command bytes )

: nae ." EEPROM Bank feature not available yet!" ;
: na ." Feature not available yet!" ;
: nab ." Buffer feature not available yet!" ;
		
		
: bufupdate  cr ." Add string to buffer pool" ;
: bufget  cr ." Get string from buffer pool" ;
: bufclear  cr ." Clear buffer pool" ;								


      
: syscmd case  	10 of na endof 		11 of na endof 		12 of na endof 		 		endcase  ;


: sepcmd case 0 of nae endof   case 1 of nae endof      case 2 of nae endof endcase ;
 
      case 3 of nae endof
      case 4 of nae endof
     case 5 of nae endof
      case 6 of nae endof      
      case 7 of nae endof      
      case 8 of nae endof
      case 9 of nae endof
      case 0a of nae endof
      case 0b of nae endof
      case 0c of nae endof
      case 0d of nae endof
      case 0e of nae endof
      case 0f of nae endof 
      endcase 
      ;

: buffcmd 
        case 
	40 of bufget rcvspibyte ." Use buffer pool:" . nab endof
	41 of bufupdate rcvspibyte ." Send back from buffer pool:" .  nab endof
	42 of bufclear rcvspibyte ." Clear buffer pool:" .  nab endof 
	endcase  
	;
                                               

: cmdscan dup cr ." Command:" .  dup sepcmd  dup syscmd dup buffcmd ;

\ : cmdscan dup cr ." Command:" . dup buffcmd ;    



( : z80start spiinit begin page ." Waiting for CE2 low" isce2en  cr ." Line enabled. Get byte..." cr rcvspibyte dup ." Got byte:" . cr cmdscan 0 until ; )




*/
