; Which startup method to use?
;
; version 1 - allows for a single stored file to be selected to run at start up (if se storage is enabled)
; followed by loading of a list of scripts in eeprom

; version 2 - if se storage is enabled then auto load all files which begin with a '*' else use loading
; from eeprom

; Select with define in main stubs

if STARTUP_V1
	include "forth_startupv1.asm"
endif
if STARTUP_V2
	include "forth_startupv2.asm"
endif

