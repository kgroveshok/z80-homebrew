#include <Arduino.h>
#include <WiFi.h>
#include <NetworkClient.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include "FS.h"
#include "SPIFFS.h"

#define SPI_ESP_CONFIG 0x14

// Buffers
#define SPI_GET_POOL 0x40
#define SPI_PUT_POOL 0x41
#define SPI_SELECT_POOL 0x42
#define SPI_CLR_POOL 0x43

// UART

#define SPI_PUTC 0x60
#define SPI_GETC 0x61

const char *ssid = "........";
const char *password = "........";
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



//char *wifi_profile="Default";

WebServer server(80);

byte cmd = 0;
byte tmpByte;
String tmpString;

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

String rcvspistrz () {
  String s="";
  byte ar[255];
  byte c;
  int si=0;
  while( (c = rcvspibyte() ) != 0 ) { ar[si++]=c;}
  ar[si]=0;

  return String((char *) ar);
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


void sndspistrz( String s) {
      int i;
      for( i = 0 ; i< s.length() ; i++) {
            sndspibyte( s[i]);
      }
      sndspibyte(0);
}


// File support

/* You only need to format SPIFFS the first time you run a
   test or else use the SPIFFS plugin to create a partition
   https://github.com/me-no-dev/arduino-esp32fs-plugin */

#define FORMAT_SPIFFS_IF_FAILED true

void listDir(fs::FS &fs, String dirname, uint8_t levels) {
  Serial.printf("Listing directory: %s\r\n", dirname);

  File root = fs.open(dirname);
  if (!root) {
    Serial.println("- failed to open directory");
    return;
  }
  if (!root.isDirectory()) {
    Serial.println(" - not a directory");
    return;
  }

  File file = root.openNextFile();
  while (file) {
    if (file.isDirectory()) {
      Serial.print("  DIR : ");
      Serial.println(file.name());
      if (levels) {
        listDir(fs, file.path(), levels - 1);
      }
    } else {
      Serial.print("  FILE: ");
      Serial.print(file.name());
      Serial.print("\tSIZE: ");
      Serial.println(file.size());
    }
    file = root.openNextFile();
  }
}

String readFile(fs::FS &fs, String path) {
  String r = "";
  byte ar[2];
  ar[1]=0;

  Serial.printf("Reading file: %s\r\n", path);

  File file = fs.open(path);
  if (!file || file.isDirectory()) {
    Serial.println("- failed to open file for reading");
    return String("");
  }

  Serial.println("- read from file:");
  while (file.available()) {
    ar[0]=file.read();
    r = r + String((char *)ar);
  }
  file.close();
  return r;
}

void writeFile(fs::FS &fs, String path, String message) {
  Serial.printf("Writing file: %s\r\n", path);

  File file = fs.open(path, FILE_WRITE);
  if (!file) {
    Serial.println("- failed to open file for writing");
    return;
  }
  if (file.print(message)) {
    Serial.println("- file written");
  } else {
    Serial.println("- write failed");
  }
  file.close();
}

void appendFile(fs::FS &fs, String path, String message) {
  Serial.printf("Appending to file: %s\r\n", path);

  File file = fs.open(path, FILE_APPEND);
  if (!file) {
    Serial.println("- failed to open file for appending");
    return;
  }
  if (file.print(message)) {
    Serial.println("- message appended");
  } else {
    Serial.println("- append failed");
  }
  file.close();
}

void renameFile(fs::FS &fs, String path1, String path2) {
  Serial.printf("Renaming file %s to %s\r\n", path1, path2);
  if (fs.rename(path1, path2)) {
    Serial.println("- file renamed");
  } else {
    Serial.println("- rename failed");
  }
}

void deleteFile(fs::FS &fs, String path) {
  Serial.printf("Deleting file: %s\r\n", path);
  if (fs.remove(path)) {
    Serial.println("- file deleted");
  } else {
    Serial.println("- delete failed");
  }
}

void testFileIO(fs::FS &fs, const char *path) {
  Serial.printf("Testing file I/O with %s\r\n", path);

  static uint8_t buf[512];
  size_t len = 0;
  File file = fs.open(path, FILE_WRITE);
  if (!file) {
    Serial.println("- failed to open file for writing");
    return;
  }

  size_t i;
  Serial.print("- writing");
  uint32_t start = millis();
  for (i = 0; i < 2048; i++) {
    if ((i & 0x001F) == 0x001F) {
      Serial.print(".");
    }
    file.write(buf, 512);
  }
  Serial.println("");
  uint32_t end = millis() - start;
  Serial.printf(" - %u bytes written in %" PRIu32 " ms\r\n", 2048 * 512, end);
  file.close();

  file = fs.open(path);
  start = millis();
  end = start;
  i = 0;
  if (file && !file.isDirectory()) {
    len = file.size();
    size_t flen = len;
    start = millis();
    Serial.print("- reading");
    while (len) {
      size_t toRead = len;
      if (toRead > 512) {
        toRead = 512;
      }
      file.read(buf, toRead);
      if ((i++ & 0x001F) == 0x001F) {
        Serial.print(".");
      }
      len -= toRead;
    }
    Serial.println("");
    end = millis() - start;
    Serial.printf("- %lu bytes read in %" PRIu32 " ms\r\n", (unsigned long)flen, end);
    file.close();
  } else {
    Serial.println("- failed to open file for reading");
  }
}

void loadCfg() {
  if (debug_level) { Serial.println("Loading configuration..."); }
  String r;
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
  pinMode(spi_di_pin, OUTPUT);

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
    WiFi.begin(ssid, password);
    Serial.println("");

    // Wait for connection
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
    }
    Serial.println("");
    Serial.print("Connected to ");
    Serial.println(ssid);
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
    cmd = rcvspibyte();
    Serial.printf("\nCommand byte seen: %c", cmd);
  }

  // Command processing

  switch (cmd) {
    case 0:
      break;
    case SPI_ESP_CONFIG:
      if (debug_level) { Serial.println("SPI_DEBUG"); }
      tmpByte = rcvspibyte();
      if (debug_level) { Serial.printf("\nDebug set to level: %d", tmpByte); }
      debug_level = (int)tmpByte;
      // TODO Save current level to file
      break;

      // Buffers
    case SPI_GET_POOL:
      if (debug_level) { Serial.printf("\nSend string from pool %d", pool_page); }
      
      tmpString=readFile(SPIFFS, "/" + String(pool_page) + "pool.txt");
      if (debug_level) {Serial.println(tmpString);}
      sndspistrz(tmpString);
      

      // TODO Consume pool?
      break;
    case SPI_PUT_POOL:
      // Get string to add to pool

      tmpString = String(rcvspistrz());
      if (debug_level) { Serial.printf("\nGot string: %s", tmpString); }
      if (debug_level) { Serial.printf("\nAppend to pool %d", pool_page); }
      appendFile(SPIFFS, "/" + String(pool_page) + "pool.txt", tmpString);
      break;
    case SPI_SELECT_POOL:
      tmpByte=rcvspibyte();
      pool_page=(int)tmpByte;
      SaveCurPool();
    if (debug_level) { Serial.printf("\nSelect pool %d", pool_page); }
      break;
    case SPI_CLR_POOL:
      if (debug_level) { Serial.printf("\nClear pool %d", pool_page); }
      deleteFile(SPIFFS, "/" + String(pool_page) + "pool.txt");
      break;


    case SPI_PUTC:
      if (debug_level) { Serial.println("SPI_PUTC"); }
      tmpByte = rcvspibyte();
      Serial.printf("%c", cmd);
      break;
    case SPI_GETC:
      break;
    default:
      // statements
      Serial.printf("\n%d: %s", cmd, fna);

      break;
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


