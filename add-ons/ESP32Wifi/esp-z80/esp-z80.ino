#include <Arduino.h>
#include <WiFi.h>
#include <NetworkClient.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include "FS.h"
#include "SPIFFS.h"
//#include <threadSafeFS.h>         // Include thread-safe wrapper since SPIFFS, LittleFS, FFat and SD file systems are not thread safe
//using File = threadSafeFS::File;
//#include <threadSafeFS.h>         // Include thread-safe wrapper since SPIFFS, LittleFS, FFat and SD file systems are not thread safe
//using File = threadSafeFS::File;  // Use thread-safe wrapper for all file operations from now on in your code
//#include <ntpClient.h>            // Setting the time is not really necessary, only if you want to see the correct file creation times
//#define HOSTNAME "Esp32Server"    // Choose your server's name - this is how FTP server would introduce itself to the clients
//#include <ftpServer.h>
//#include <WiFiS3.h>
//#include <XModem.h>
#include "esp-z80-op.h"
#include "esp-spi-op.h"
#include "esp-z80-file.h"

//#include <ESP32FtpServer.h>  // Usando < > para bibliotecas instaladas
//#include <ftpServer.h>
//#define HOSTNAME "espz80"

//threadSafeFS::FS TSFS (LittleFS);
#define RUN_WEBSERVER 1


// wifi

String wifi_ssid = "";
String wifi_password = "";
//const char *fna = "That feature is not available right now!";

// Profile/Page ids

int storage_page = 0;
int wifi_profile = 0;
int internet_profile = 0;
int pool_page = 0;

// System configuration switches

int debug_level = 1;
int config_byte = 1;
//int use_webserver = 0;

byte storage_block[48000];

//XModem xmodem;

//#include <XModem.h>
//XModem xmodem;
//The arduino toolchain will add these declarations automatically but doing
//manually so things also just work if someone uses a different/custom toolchain
//bool process_block(void *blk_id, size_t idSize, byte *data, size_t dataSize);

/*
 * You can test this over your USB port using lrzsz: `stty -F /dev/ttyUSB0 4800 && sx -vaX /path/to/send/file > /dev/ttyUSB0 < /dev/ttyUSB0`
 * If you want to try CRC_XMODEM then add a o flag to the sx command (-vaoX)
 */
//void setup() {
//  Serial.begin(4800, SERIAL_8N1);
//  xmodem.begin(Serial, XModem::ProtocolType::XMODEM);
//  xmodem.setRecieveBlockHandler(process_block);
//}

//void loop() {
//This simple example continuously tries to read data
//  xmodem.receive();
//}

//bool process_block(void *blk_id, size_t idSize, byte *data, size_t dataSize) {
//byte id = *((byte *) blk_id);
//for(int i = 0; i < dataSize; ++i) {
////do stuff with the recieved data
//  }
//
//  //return false to stop the transfer early
//  return true;
//}


/*
 * You can test this over your USB port using lrzsz: `stty -F /dev/ttyUSB0 4800 && rx -vaX /path/to/save/file > /dev/ttyUSB0 < /dev/ttyUSB0`
 * If you want to try CRC_XMODEM then add a c flag to the rx command (-vacX)
 */
//void setup() {
//  Serial.begin(4800, SERIAL_8N1);
//  xmodem.begin(Serial, XModem::ProtocolType::XMODEM);
//}

//static const char text[] = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed sollicitudin tempor ex et sagittis. Sed feugiat justo ac dui posuere, in porta odio aliquet. Vestibulum dignissim malesuada lacus eu consectetur. Fusce sed varius nibh. Nulla lacinia ipsum non porttitor auctor. Aenean eget eros pharetra, fringilla ipsum eget, pharetra turpis. Suspendisse vitae leo id orci consectetur faucibus. Praesent elementum ex eget venenatis consequat.\n"
//"\n"
//
//void loop() {
//  //This simple example continuously tries to send data
//  xmodem.send(text, strlen(text));
//}

/*
 * You can test this over your USB port using lrzsz: `stty -F /dev/ttyUSB0 4800 && rx -vaX /path/to/save/file > /dev/ttyUSB0 < /dev/ttyUSB0`
 * If you want to try CRC_XMODEM then add a c flag to the rx command (-vacX)
 */
//void setup() {
//  Serial.begin(4800, SERIAL_8N1);
//  xmodem.begin(Serial, XModem::ProtocolType::XMODEM);
//}
//
//static const char text[] = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed sollicitudin tempor ex et sagittis. Sed feugiat justo ac dui posuere, in porta odio aliquet. Vestibulum dignissim malesuada lacus eu consectetur. Fusce sed varius nibh. Nulla lacinia ipsum non porttitor auctor. Aenean eget eros pharetra, fringilla ipsum eget, pharetra turpis. Suspendisse vitae leo id orci consectetur faucibus. Praesent elementum ex eget venenatis consequat.\n"
//"\n"
//
//void loop() {
//  //This simple example continuously tries to send data
//  xmodem.send(text, strlen(text));
//}



//char *wifi_profile="Default";

WebServer server(80);
int runWebServer;

byte cmd = 0, cmd2 = 0;
byte tmpByte;
int storeAddr;
byte storeData;
String tmpString;
int tmpInt;

WiFiClient TCP_client;



int wifi_ready = 0;
const int led = LED_BUILTIN;

#define esp_wake_up_ce GPIO_NUM_10
const int spi_ce_pin = 10;
const int spi_do_pin = 7;
const int spi_sck_pin = 8;
const int spi_di_pin = 9;


// command arrays



typedef struct {
  byte p_cmd;
  byte s_cmd;
  const char *des;
  byte op_codes[];
} COMMAND_STREAM;

#define FUNC_SET_DEBUG 0
#define FUNC_SET_SSID 1
#define FUNC_SET_WIFIPASS 2
#define FUNC_ESP_SLEEP 3
#define FUNC_SET_WEBSERVER 4
#define FUNC_POOL_PUTZ 5
#define FUNC_POOL_UART_OUT 6
#define FUNC_SET_FTPSERVER 7
#define FUNC_GET_IP 8
#define FUNC_POOL_GETZ 9

COMMAND_STREAM spi_esp_powered = { SPI_ESP_SYS, SPI_ESP_SYS_POWERED, "ESP is on?", { OP_VAR_LIT, 0, 1, OP_OUTBYTE, OP_BYTE_SPI, 0, OP_END_PROC } };
COMMAND_STREAM spi_esp_debug = { SPI_ESP_SYS, SPI_ESP_SYS_DEBUG, "Set debug flag", { OP_INBYTE, OP_BYTE_SPI, OP_EXEC_FUNC, FUNC_SET_DEBUG, OP_END_PROC } };
COMMAND_STREAM spi_esp_sleep = { SPI_ESP_SYS, SPI_ESP_SYS_SLEEP, "Go to sleep", { OP_EXEC_FUNC, FUNC_ESP_SLEEP, OP_END_PROC } };


COMMAND_STREAM spi_wifi_setssid = { SPI_WIFI, SPI_WIFI_SET_SSID, "Set SSID", { OP_LOOP_START, OP_INBYTE, OP_BYTE_SPI, OP_UNTIL_BYTE, 0, OP_EXEC_FUNC, FUNC_SET_SSID, OP_END_PROC } };
COMMAND_STREAM spi_wifi_setpass = { SPI_WIFI, SPI_WIFI_SET_PASS, "Set Wifi Password", { OP_LOOP_START, OP_INBYTE, OP_BYTE_SPI, OP_UNTIL_BYTE, 0, OP_EXEC_FUNC, FUNC_SET_WIFIPASS, OP_END_PROC } };
COMMAND_STREAM spi_wifi_use_webserver = { SPI_WIFI, SPI_WIFI_USE_WEBSERVER, "Use Webserver", { OP_EXEC_FUNC, FUNC_SET_WEBSERVER, OP_END_PROC } };
//COMMAND_STREAM spi_wifi_use_ftpserver = { SPI_WIFI, SPI_WIFI_USE_FTPSERVER, "Use FTP server", { OP_INBYTE, OP_BYTE_SPI, OP_EXEC_FUNC, FUNC_SET_FTPSERVER, OP_END_PROC } };

//COMMAND_STREAM spi_wifi_getip = { SPI_WIFI, SPI_WIFI_GET_IP, "Get IP/MAC", { OP_EXEC_FUNC, FUNC_GET_IP, OP_OUTBYTE, OP_BYTE_SPI, OP_OUTBYTE, OP_BYTE_SPI, OP_OUTBYTE, OP_BYTE_SPI, OP_END_PROC } };
COMMAND_STREAM spi_wifi_getip = { SPI_WIFI, SPI_WIFI_GET_IP, "Get IP/MAC", { OP_EXEC_FUNC, FUNC_GET_IP, OP_LOOP_START, OP_OUTBYTE, OP_BYTE_SPI, OP_UNTIL_BYTE, 1, OP_END_PROC } };


COMMAND_STREAM spi_pool_get = { SPI_POOL, SPI_POOL_GET, "Pool get", { OP_INBYTE, OP_BYTE_FILE, OP_SET_VAR_POS, 0, OP_OUTBYTE, OP_BYTE_SPI, OP_END_PROC } };
COMMAND_STREAM spi_pool_put = { SPI_POOL, SPI_POOL_PUT, "Pool put", { OP_INBYTE, OP_BYTE_SPI, OP_OUTBYTE, OP_BYTE_FILE, 0, OP_END_PROC } };
COMMAND_STREAM spi_pool_select = { SPI_POOL, SPI_POOL_SELECT, "pool select", { OP_INBYTE, OP_BYTE_SPI, OP_OPENF, 'p', 0, OP_FILEEOF, OP_END_PROC } };
COMMAND_STREAM spi_pool_putz = { SPI_POOL, SPI_POOL_PUTZ, "Pool put string", { OP_LOOP_START, OP_INBYTE, OP_BYTE_SPI, OP_UNTIL_BYTE, 0, OP_EXEC_FUNC, FUNC_POOL_PUTZ, OP_END_PROC } };
COMMAND_STREAM spi_pool_art_out = { SPI_POOL, SPI_POOL_UART_OUT, "Dump pool to uart", { OP_EXEC_FUNC, FUNC_POOL_UART_OUT, OP_END_PROC } };

COMMAND_STREAM spi_pool_getsz = { SPI_POOL, SPI_POOL_GETZ, "Pool get string", { OP_EXEC_FUNC, FUNC_POOL_GETZ, OP_SET_VAR_POS, 0, OP_LOOP_START, OP_OUTBYTE, OP_BYTE_SPI, OP_UNTIL_BYTE, 1, OP_END_PROC } };



COMMAND_STREAM spi_putc = { SPI_PUTC, 0, "Uart put", { OP_INBYTE, OP_BYTE_SPI, OP_OUTBYTE, OP_BYTE_UART, 0, OP_END_PROC } };
COMMAND_STREAM spi_getc = { SPI_GETC, 0, "Uart get", { OP_INBYTE, OP_BYTE_UART, OP_OUTBYTE, OP_BYTE_SPI, 0, OP_END_PROC } };




//const char *ftp_user = "admin";
//const char *ftp_pass = "1234";

//FtpServer ftp;
//ftpServer_t *ftpServer = NULL;


void SaveDebug() {
  if (debug_level) { Serial.println("Saving debug.txt..."); }
  Serial.println(String(debug_level));
  writeFile(SPIFFS, "/debug.txt", String(debug_level));
}



int exec_pool_putz() {
  if (debug_level) { Serial.println("exec save string to pool"); }
  char s[512];
  memset(s, 0, sizeof(s));
  for (int i = 0; op_vars[i] != 0; i++) s[i] = op_vars[i];

  current_file.print(s);
  current_file.flush();
  return 0;
}


int exec_pool_getz() {
  if (debug_level) { Serial.println("exec get pool to string"); }

  current_file.seek(0L, SeekSet);
  String r = "";
  byte ar[2];
  ar[1] = 0;
  int v = 0;
  while (current_file.available()) {
    ar[0] = current_file.read();
    op_vars[v++] = ar[0];
  }
  op_vars[v++] = 0;

  return 0;
}


int exec_esp_sleep() {
  if (debug_level) { Serial.println("exec go to sleep"); }
  int ret = esp_light_sleep_start();
  Serial.printf("\nReturn from sleep: %d", ret);
  return 0;
}

int exec_set_webserver() {
  if (debug_level) { Serial.println("exec set webserver"); }
  //  use_webserver = op_vars[0];
  runWebServer = 1;
  while (runWebServer) {
    server.handleClient();
  }

  if (debug_level) { Serial.println("exit exec webserver"); }

  return 0;
}

int exec_set_ftpserver() {
  if (debug_level) { Serial.println("exec set ftp server"); }
  if (op_vars[0]) {
    debug_level = (debug_level || 128);
  } else {
    debug_level = (debug_level && 127);
  }

  SaveDebug();
  //listDir(SPIFFS, "/", 0);   // do a list dir to help with any diags
  return 0;
}


int exec_set_debug() {
  if (debug_level) { Serial.println("exec set config"); }
  debug_level = op_vars[0];
  SaveDebug();
  listDir(SPIFFS, "/", 0);  // do a list dir to help with any diags
  return 0;
}

int exec_set_ssid() {
  if (debug_level) { Serial.println("exec set ssid"); }

  char s[512];
  memset(s, 0, sizeof(s));
  for (int i = 0; op_vars[i] != 0; i++) s[i] = op_vars[i];

  wifi_ssid = s;
  if (debug_level) { Serial.printf("Wifi set:%s", wifi_ssid); }

  writeFile(SPIFFS, "/0wifi_ssid.txt", String(wifi_ssid));

  return 0;
}

int exec_set_wifipass() {
  if (debug_level) { Serial.println("exec set wifi pass"); }
  char s[512];
  memset(s, 0, sizeof(s));
  for (int i = 0; op_vars[i] != 0; i++) s[i] = op_vars[i];


  wifi_password = s;
  if (debug_level) { Serial.printf("Wifi set:%s", wifi_password); }
  writeFile(SPIFFS, "/0wifi_password.txt", String(wifi_password));
  return 0;
}

int exec_pool_uart_out() {
  current_file.seek(0L, SeekSet);



  String r = "";
  byte ar[2];
  ar[1] = 0;
  while (current_file.available()) {
    ar[0] = current_file.read();
    r = r + String((char *)ar);
  }
  Serial.println(r);
  return 0;
}

int exec_get_ip() {
  String ip, mac, res;
  int i;

  // Fill IP address
  ip = String(WiFi.localIP().toString());
  if (debug_level) { Serial.println("Settings:" + ip); }

  // Fill Mac address
  mac = String(WiFi.macAddress());
  if (debug_level) { Serial.println("Settings:" + mac); }
  res = ip + "-" + mac + "\0";
  //char s[512];
  if (debug_level) { Serial.println("Settings:" + res); }
  memset(op_vars, 1, sizeof(op_vars));
  for (i = 0; res[i] != 0; i++) { op_vars[i] = res[i]; }

  op_vars[i] = 0;
  //op_vars[i+1]=0;
  //op_vars[i+2]=0;
  // TODO

  return 0;
}



void set_exec_funcs() {
  exec_func[FUNC_SET_DEBUG] = exec_set_debug;
  exec_func[FUNC_SET_SSID] = exec_set_ssid;
  exec_func[FUNC_SET_WIFIPASS] = exec_set_wifipass;
  exec_func[FUNC_ESP_SLEEP] = exec_esp_sleep;
  exec_func[FUNC_POOL_PUTZ] = exec_pool_putz;

  exec_func[FUNC_POOL_UART_OUT] = exec_pool_uart_out;
  exec_func[FUNC_SET_WEBSERVER] = exec_set_webserver;
  exec_func[FUNC_GET_IP] = exec_get_ip;
  exec_func[FUNC_POOL_GETZ] = exec_pool_getz;
}


COMMAND_STREAM *op_commands[] = {
  &spi_esp_powered,
  &spi_esp_debug,
  &spi_pool_get,
  &spi_pool_put,
  &spi_pool_select,
  &spi_pool_art_out,
  &spi_putc,
  &spi_getc,
  &spi_wifi_setssid,
  &spi_wifi_setpass,
  &spi_wifi_use_webserver,
  &spi_pool_putz,
  //&spi_wifi_use_ftpserver,
  &spi_wifi_getip,
  &spi_pool_getsz,
  0
};


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
  while (!isCLK()) {
    d = getDO();
    if (isCE2()) return 255;
  };
  //Serial.println("Done");
  return d;
}
void fromCLKLowOut() {
  //Serial.println("In isCLKLowOut");
  while (!isCLK()) {
    if (isCE2()) return;
  };
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
    if (isCE2()) return 255;
    if (fromCLKLowIn() == 1) {
      b++;
      //Serial.printf("\n%d: 1 ", i);
    }  //else { Serial.printf("\n%d: 0 ", i);}
    b = b << 1;
  }
  fromCLKHigh();
  if (isCE2()) return 255;
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

  r = readFile(SPIFFS, "/debug.txt");
  Serial.println(r);
  if (r.length() == 0) {
    SaveDebug();
  }

  debug_level = r.toInt();

  /*// TODO set server config flags
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
  */
}
void SaveCfg() {
  if (debug_level) { Serial.println("Saving config.txt..."); }
  writeFile(SPIFFS, "/config.txt", String(debug_level));
}
/*
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
*/

// Webserver support
#ifdef RUN_WEBSERVER

// Username and password for web page access
const char *http_username = "admin";
const char *http_password = "admin";

// Function to authenticate user
bool isAuthenticated() {
  if (!server.authenticate(http_username, http_password)) {
    server.requestAuthentication();
    return false;
  }
  return true;
}
//void handleRoot(WiFiClient& client, const String& method, const String& request ) {
//
//}, const QueryParams& params, const String& jsonData) {
//https://blog.hirnschall.net/esp32-webserver/
//https://avantmaker.com/references/esp32-arduino-core-index/esp32-webserver-library/esp32-webserver-library-onfileupload/

File fsUploadFile;

void handleFileUpload() {
  Serial.println("In handle file upload");
  HTTPUpload &upload = server.upload();
  if (upload.status == UPLOAD_FILE_START) {
    String filename = upload.filename;
    if (!filename.startsWith("/")) {
      filename = "/" + filename;
    }
    Serial.println("Upload Started: " + filename);
    fsUploadFile = SPIFFS.open(filename, FILE_WRITE);
    if (!fsUploadFile) {
      Serial.println("Failed to open file for writing");
      return;
    }
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (fsUploadFile) {
      fsUploadFile.write(upload.buf, upload.currentSize);
      Serial.printf("Uploaded %d bytes\n", upload.currentSize);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (fsUploadFile) {
      fsUploadFile.close();
      Serial.println("Upload Finished: " + String(upload.totalSize) + " bytes");
    }
  }
}



void handleRoot() {
  if (!isAuthenticated()) return;
  digitalWrite(led, 1);
  String html;
  html = "<html><body><form action='/upload'  enctype='multipart/form-data'  method=post>";
  html += "<input type='file' name='upload' id='fileInput' onchange='checkFileSelected()'>";
  html += "<input type='submit' value='Upload' id='uploadButton'>";
  html += "</form> <a href='/stop'>[Stop]</a>";

  if (server.hasArg("upload")) {
    html = html + "<br><b>Upload file " + server.arg("upload") + "</b>";
  }


  if (server.hasArg("del")) {
    html = html + "<br><b>Deleted file " + server.arg("del") + "</b>";
    deleteFile(SPIFFS, "/" + server.arg("del"));
  }

  if (server.hasArg("file")) {
    server.send(200, "text/plain", readFile(SPIFFS, "/" + server.arg("file")));
  }

  else {
    server.send(200, "text/html", html + listDir(SPIFFS, "/", 0) + "</body></html>");
  }
  digitalWrite(led, 0);
}

void handleGetFile() {
  if (!isAuthenticated()) return;
  digitalWrite(led, 1);
  server.send(200, "text/plain", readFile(SPIFFS, "/1pool.txt"));
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
#endif

//// op exec

void execOpOutByte() {
  if (debug_level) { Serial.println("op out byte"); }

  current_cmd++;  // move to source of get
  switch (*current_cmd) {
    case OP_BYTE_SPI:

      //current_cmd++;
      if (debug_level) { Serial.println("byte via spi "); }
      sndspibyte(op_vars[current_var]);

      break;

    case OP_BYTE_FILE:
      if (debug_level) { Serial.println("byte via file"); }
      char buf[10];
      current_file.readBytes(buf, 1);
      op_vars[current_var] = buf[0];

      break;
    case OP_BYTE_SOCK:
      if (debug_level) { Serial.println("byte via socket"); }

      break;
    case OP_BYTE_VARLOC:
      if (debug_level) { Serial.println("byte via varloc"); }
      break;
    case OP_BYTE_UART:

      if (debug_level) { Serial.println("byte via uart"); }
      //current_cmd++;
      //Serial.printf("%c", op_vars[*current_cmd]);
      break;
  }
  current_var++;
}
void execOpInByte() {
  if (debug_level) { Serial.println("op in byte"); }
  current_cmd++;  // move to source of get

  switch (*current_cmd) {
    case OP_BYTE_SPI:
      if (debug_level) { Serial.println("byte via spi"); }
      op_vars[current_var] = rcvspibyte();
      break;

    case OP_BYTE_FILE:
      if (debug_level) { Serial.println("byte via file"); }
      current_cmd++;
      current_file.printf("%c", op_vars[*current_cmd]);
      break;
    case OP_BYTE_SOCK:
      if (debug_level) { Serial.println("byte via socket"); }

      break;
    case OP_BYTE_VARLOC:
      if (debug_level) { Serial.println("byte via varloc"); }
      break;
    case OP_BYTE_UART:

      if (debug_level) { Serial.println("byte via uart"); }

      break;
  }

  if (debug_level) { Serial.printf("\ngot var %d as %d", current_var, op_vars[current_var]); }
  current_var++;
}
void execOpMakeWord() {
  // construct a 16bit word using msb, lsb from given var slots to depost in var slot x
  if (debug_level) { Serial.println("op word word"); }
  int msb = ++*current_cmd;
  int lsb = ++*current_cmd;
  int var = ++*current_cmd;

  op_vars[var] = (msb << 8) + lsb;
}
void execOpBreakWord() {
  // split a 16bit word in var slot x into given msb, lsb from given var slots
  if (debug_level) { Serial.println("op brake word"); }
  int var = op_vars[++*current_cmd];
  int msb = ++*current_cmd;
  int lsb = ++*current_cmd;


  op_vars[msb] = var >> 8;
  op_vars[lsb] = var && 255;
}

void execOpLoopStart() {
  if (debug_level) { Serial.println("op loop start"); }
  current_loop_start = current_cmd;
  current_loop_count = 0;
}

void execOpUntilByte() {
  if (debug_level) { Serial.println("op untl byte"); }
  ++current_cmd;
  if (op_vars[current_var - 1] != *current_cmd) {
    current_cmd = current_loop_start;
    if (debug_level) { Serial.println("not byte so back to start of loop"); }
  } else {
    if (debug_level) { Serial.println("byte found"); }
  }
}
void execOpUntilCount() {
  if (debug_level) { Serial.println("op until count"); }
  current_loop_count++;
  if (current_loop_count < *(++current_cmd)) { current_cmd = current_loop_start; }
}
void execOpOpenF() {
  if (debug_level) { Serial.println("op openf"); }

  if (current_file) { current_file.close(); }
  // open file with prefix and var number
  current_cmd++;
  byte p = *current_cmd;
  current_cmd++;
  int v = op_vars[*current_cmd];
  char path[20];
  sprintf(path, "/%c%d.txt", p, v);
  //String path = "/" + String(p) + String(v) + ".txt";
  if (debug_level) { Serial.println(path); }
  // TODO set rw append mode instead
  current_file = SPIFFS.open(path, "a+");
}

void execOpVarLit() {
  // set lit on a var
  // op, position, value
  if (debug_level) { Serial.println("op var lit"); }
  current_cmd++;
  int thisvar = *current_cmd;
  current_cmd++;
  op_vars[thisvar] = *current_cmd;
}



void execOpCloseF() {
  if (debug_level) { Serial.println("op closef"); }
  if (current_file) { current_file.close(); }
}
void execOpClrStr() {
  if (debug_level) { Serial.println("op clr str"); }
}
void execOpAddToStr() {
  if (debug_level) { Serial.println("op add to str"); }
}
void execOpStarVar() {
  if (debug_level) { Serial.println("op store var"); }
}



void cmdExec(byte *opcodes) {
  current_cmd = opcodes;  // pointer to cmd op being processed
  current_var = 0;        // current var that any get will insert into

  if (debug_level) { Serial.println("Exec op codes..."); }

  while (*current_cmd != OP_END_PROC) {
    if (debug_level) { dump_op_vars(); }
    if (debug_level) { Serial.printf("\nExec op code: %d", *current_cmd); }


    switch (*current_cmd) {

      case OP_SET_VAR_POS:
        // set the position of the current var op array
        current_var = *(++current_cmd);
        current_cmd++;
        break;
      case OP_MAKEWORD:

        execOpMakeWord();
        break;

      case OP_INBYTE:

        execOpInByte();
        break;
      case OP_OUTBYTE:

        execOpOutByte();
        break;
      case OP_BREAKWORD:

        execOpBreakWord();
        break;
      case OP_LOOP_START:

        execOpLoopStart();
        break;
      case OP_UNTIL_BYTE:

        execOpUntilByte();
        break;
      case OP_UNTIL_COUNT:

        execOpUntilCount();
        break;
      case OP_OPENF:

        execOpOpenF();
        break;
      case OP_CLOSEF:

        execOpCloseF();
        break;
      case OP_STR_CLR:

        execOpClrStr();
        break;
      case OP_STR_ADD:

        execOpAddToStr();
        break;
      case OP_STORE_VAR:

        execOpStarVar();
        break;
      case OP_VAR_LIT:
        execOpVarLit();
        break;
      case OP_EXEC_FUNC:
        if (debug_level) { Serial.println("op exec func"); }
        current_cmd++;
        int func = *current_cmd;
        int ret = (*exec_func[func])();
        break;
    }


    current_cmd++;
  }

  if (debug_level) { Serial.printf("\nExec done"); }
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

  esp_sleep_enable_ext0_wakeup(esp_wake_up_ce, 0);

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


  set_exec_funcs();


  // TODO remove this once configured

  if (wifi_ready) {
    WiFi.mode(WIFI_STA);
    WiFi.begin(wifi_ssid, wifi_password);
    Serial.println("");

    // Wait for connection

    for (int retries = 0; WiFi.status() != WL_CONNECTED & retries < 10; retries++) {
      delay(500);
      Serial.print(".");
    }

    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("Failed to connect to wifi. Disabled.");
      deleteFile(SPIFFS, "/0wifi_password.txt");
      wifi_ready = 0;
    } else {
      Serial.println("");
      Serial.print("Connected to ");
      Serial.println(wifi_ssid);
      Serial.print("IP address: ");
      Serial.println(WiFi.localIP());

      if (MDNS.begin("esp32")) {
        Serial.println("MDNS responder started");
      }
    }

    setCpuFrequencyMhz(80);

    //if (debug_level & 128) {
    //      Serial.println("FTP Server init");
    //ftp.begin(ftp_user, ftp_pass);
    //ftpServer = new (std::nothrow) ftpServer_t ();
    //setCpuFrequencyMhz(30);

#ifdef RUN_WEBSERVER
    server.on("/", handleRoot);
    //server.on("/upload", HTTP_POST, handleUploadReply, handleUpload);
    server.on(
      "/upload", HTTP_POST, []() {
        server.send(200, "text/plain", "File Uploaded Successfully");
      },
      handleFileUpload);
    server.on("/stop", []() {
      runWebServer = 0;
    });
    //server.onFileUpload(handleFileUpload);

    //server.on("/get", handleGetFile);
    //server.addRoute("/", handleRoot);
    //server.addHandler()
    //server.on("/inline", []() {
    //  server.send(200, "text/plain", "this works as well");
    //});
    //https://avantmaker.com/references/esp32-arduino-core-index/esp32-webserver-library/esp32-webserver-library-upload/

    server.onNotFound(handleNotFound);
    //server.onFileUpload(handleUpload);
    //if (use_webserver) {
    server.begin();
    Serial.println("HTTP server started");


    //}
    //} else {
//        Serial.println("HTTP server configured to not run. Skipped start up.");
//}
#endif
  } else {
    Serial.println("Wifi not configured. Skipping HTTP server startup");
  }
  uint32_t Freq = getCpuFrequencyMhz();
  Serial.print("CPU Freq = ");
  Serial.print(Freq);
  Serial.println("");

  Serial.println("Waiting for CE2 line...");
}

void loop(void) {

  int sleep_ret;

  debug_level=2;

  //#ifdef RUN_WEBSERVER
  //
  //  if (wifi_ready) {
  //if (use_webserver) {
  //      server.handleClient();
  //} else {
  //}
  //}

  //#endif
  if (isCE2()) {
    //if (debug_level & 128) {
    // If web server is enabled and ce2 is high then switch to running webserver tasks
    // and not go to sleep
    //        if (debug_level) { Serial.println("Handle WWW"); }
    //while (isCE2()) { server.handleClient(); }
    //        setCpuFrequencyMhz(240);
    //ftp.handleFTP();

    //delay(500);
    //} else {
    if (debug_level) { Serial.println("\nNo activity, entering sleep"); }
    sleep_ret = esp_light_sleep_start();
    if (debug_level) { Serial.printf("\nReturn from sleep: %d", sleep_ret); }
    //  }
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

    // scan the first byte of command array for a hit

    if (debug_level) { Serial.println("Scanning"); }
    for (int a = 0; op_commands[a] != 0; a++) {
      if (debug_level > 5) { Serial.printf("\np_cmd: %d", op_commands[a]->p_cmd); }

      if (op_commands[a]->p_cmd == cmd) {
        if (debug_level) { Serial.println("First level command found on "); }
        if (debug_level) { Serial.println(a); }
        // Check for second level need
        if (op_commands[a]->s_cmd > 0) {
          if (debug_level) { Serial.println("Need a sub command..."); }

          // TODO get another byte
          cmd2 = rcvspibyte();
          // TODO rescan
          for (int aa = 0; op_commands[aa] != 0; aa++) {
            if (op_commands[aa]->p_cmd == cmd & op_commands[aa]->s_cmd == cmd2) {
              if (debug_level) { Serial.println("Exec:" + String(op_commands[aa]->des)); }
              cmdExec(op_commands[aa]->op_codes);
              break;
            }
          }
          break;
        } else {
          if (debug_level) { Serial.println("Don't need sub command passing off to processing"); }
          if (debug_level) { Serial.println("Exec:" + String(op_commands[a]->des)); }
          cmdExec(op_commands[a]->op_codes);
          // TODO process
          break;
        }
        if (debug_level) { Serial.println("Done"); }
      }
    }


    digitalWrite(led, 0);
    pinMode(spi_di_pin, INPUT);
  } else {
  }
}

// eof
