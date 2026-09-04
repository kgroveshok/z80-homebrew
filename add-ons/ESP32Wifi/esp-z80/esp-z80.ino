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
#include "esp-z80-file.h"
#include "esp-z80-common.h"
#include "esp-z80-op.h"
#include "esp-spi-op.h"

#include "esp-op-exec.h"
#include "esp-op-array.h"
//#include <ESP32FtpServer.h>  // Usando < > para bibliotecas instaladas
//#include <ftpServer.h>
//#define HOSTNAME "espz80"

//threadSafeFS::FS TSFS (LittleFS);

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






//const char *ftp_user = "admin";
//const char *ftp_pass = "1234";

//FtpServer ftp;
//ftpServer_t *ftpServer = NULL;





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

  r = readFile(SPIFFS, "/allow_sleep.txt");
  Serial.println(r);
  if (r.length() == 0) {
    SaveSleep();
  }

  allow_sleep = r.toInt();

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




void cmdExec(byte *opcodes) {
  current_cmd = opcodes;  // pointer to cmd op being processed
  current_var = 0;        // current var that any get will insert into

  if (debug_level) { Serial.println("Exec op codes..."); }

  while (*current_cmd != OP_END_PROC) {
    if (debug_level) { dump_op_vars(); }
    if (debug_level) { Serial.printf("\nExec op code: %d", *current_cmd); }


    switch (*current_cmd) {

      case OP_VAR_POS_INC:
        current_var++;
        break;
      case OP_VAR_POS_DEC:
        current_var--;
        break;
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


  setCpuFrequencyMhz(80);

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
    
    if( allow_sleep ) {
      if (debug_level) { Serial.println("\nNo activity, entering sleep"); }
    sleep_ret = esp_light_sleep_start();
    if (debug_level) { Serial.printf("\nReturn from sleep: %d", sleep_ret); }
    } else { 
if (debug_level) { Serial.printf("z"); }
delay(250);
    }
    
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
