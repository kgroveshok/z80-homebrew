
// command arrays




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
  if (debug_level) { Serial.println("exec set sleep"); }
//  int ret = esp_light_sleep_start();
  //Serial.printf("\nReturn from sleep: %d", ret);
  SaveSleep();
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

  char s[128];
  memset(s, 0, sizeof(s));
  for (int i = 0; op_vars[i] != 0; i++) s[i] = op_vars[i];

  wifi_ssid = s;
  if (debug_level) { Serial.printf("Wifi set:%s", wifi_ssid); }

  writeFile(SPIFFS, "/0wifi_ssid.txt", String(wifi_ssid));

  return 0;
}

int exec_set_wifipass() {
  if (debug_level) { Serial.println("exec set wifi pass"); }
  char s[128];
  memset(s, 0, sizeof(s));
  for (int i = 0; op_vars[i] != 0; i++) s[i] = op_vars[i];


  wifi_password = s;
  if (debug_level) { Serial.printf("\nWifi set:%s", String(wifi_password)); }
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
  if (op_vars[current_var] != *current_cmd) {
    current_cmd = current_loop_start;
    if (debug_level) { Serial.println("not byte so back to start of loop"); }
  } else {
    if (debug_level) { Serial.println("byte found"); }
  }
current_var++;
}
void execOpUntilCount() {
  if (debug_level) { Serial.println("op until count"); }
  current_loop_count++;
  if (current_loop_count < *(++current_cmd)) { current_cmd = current_loop_start; }
current_var++;
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




