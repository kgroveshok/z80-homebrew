
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
int allow_sleep = 0 ;
int config_byte = 1;
//int use_webserver = 0;

byte storage_block[48000];

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


void SaveDebug() {
  if (debug_level) { Serial.println("Saving debug.txt..."); }
  Serial.println(String(debug_level));
  writeFile(SPIFFS, "/debug.txt", String(debug_level));
}


void SaveSleep() {
  if (debug_level) { Serial.println("Saving sleep.txt..."); }
  Serial.println(String(allow_sleep));
  writeFile(SPIFFS, "/allow_sleep.txt", String(allow_sleep));
}





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
// eof
