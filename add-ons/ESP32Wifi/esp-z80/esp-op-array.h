
typedef struct {
  byte p_cmd;
  byte s_cmd;
  const char *des;
  byte op_codes[];
} COMMAND_STREAM;

COMMAND_STREAM spi_esp_powered = { SPI_ESP_SYS, SPI_ESP_SYS_POWERED, "ESP is on?", { OP_VAR_LIT, 0, 1, OP_OUTBYTE, OP_BYTE_SPI, 0, OP_END_PROC } };
COMMAND_STREAM spi_esp_debug = { SPI_ESP_SYS, SPI_ESP_SYS_DEBUG, "Set debug flag", { OP_INBYTE, OP_BYTE_SPI, OP_EXEC_FUNC, FUNC_SET_DEBUG, OP_END_PROC } };
COMMAND_STREAM spi_esp_sleep = { SPI_ESP_SYS, SPI_ESP_SYS_SLEEP, "Go to sleep", { OP_EXEC_FUNC, FUNC_ESP_SLEEP, OP_END_PROC } };
// TODO set cpu freq

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
