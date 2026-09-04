// SPI structure

//#if USING_OPS

// eeprom emul command bytes

#define SPI_STORAGE_READ 0x03
#define SPI_STORAGE_WRITE 0x02
#define SPI_STORAGE_WREN 0x06

// ESP System main command byte
#define SPI_ESP_SYS 0x20

// ESP System sub command byte

#define SPI_ESP_SYS_POWERED 0x01      // done
#define SPI_ESP_SYS_DEBUG 0x02        // done
#define SPI_ESP_SYS_SLEEP 0x04             // TODO decide if the device will go to sleep when CE high
#define SPI_ESP_SYS_FREQ 0x05       // TODO set cpu frequency

// wifi

#define SPI_WIFI 0x21

// wifi sub commands
#define SPI_WIFI_SET_SSID 0x01           // done
#define SPI_WIFI_SET_PASS 0x02            // done
#define SPI_WIFI_GET_IP 0x03             // done to debug (prtip works, but getstrz has bug)
//#define SPI_WIFI_CREATE_PROF 0x04
//#define SPI_WIFI_SELECT_PROF 0x05
//#define SPI_WIFI_LIST_PROF 0x06
//#define SPI_WIFI_CONNECT 0x07
//#define SPI_WIFI_DISCON 0x08
//#define SPI_WIFI_GETNTP  0x09    // get current ntp time
//#define SPI_WIFI_GETDATE  0x0a
//#define SPI_WIFI_GETTIME  0x0b
//#define SPI_WIFI_SETTZ  0x0c    // set ntp time zone
#define SPI_WIFI_USE_WEBSERVER  0x0d     // done
//#define SPI_WIFI_USE_FTPSERVER  0x0e    // get rid


// Buffers
#define SPI_POOL 0x23

// Buffers sub commands
#define SPI_POOL_PUT 0x01             // TODO broken: append or over write next pos
#define SPI_POOL_GET 0x02             // TODO broken: get next char from pool until eof
#define SPI_POOL_SELECT 0x03         // done
#define SPI_POOL_CLR 0x04            // done
#define SPI_POOL_UART_OUT 0x05         //done     // dump pool to uart
//#define SPI_POOL_UART_IN 0x06      // load pool from uart
//#define SPI_POOL_POS  0x07     // TODO set pos for get
//#define SPI_POOL_REWIND 0x08    // TODO fast set pos to start
//#define SPI_POOL_APPEND 0x09    // TODO fast set pos to end of file for next put
//#define SPI_POOL_IS_EOF 0x0a    // TODO are we done reading?
#define SPI_POOL_PUTZ 0x0b          // done   // append or over write next pos a zero term string
#define SPI_POOL_GETZ 0x0c          // TODO 

// UART

#define SPI_PUTC 0x60                    // done
#define SPI_GETC 0x61
// eof
