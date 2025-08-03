; Prompts 

; boot messages

prom_bootmsg:	db "z80-homebrew OS v1.7",0
prom_bootmsg1:	db "by Kevin Groves",0


; config menus

;prom_c3: db "Add Dictionary To File",0

if STARTUP_V1
prom_c2: db "Select Autoload File",0
prom_c2a: db "Disable Autoload File", 0
endif

if STARTUP_V2
prom_c2: db "Enable Autoload Files",0
prom_c2a: db "Disable Autoload Files", 0

crs_s1: db "*ls-word", 0
crs_s2: db "*ed-word", 0
crs_s3: db "*Demo-Programs", 0
crs_s4: db "*Utils", 0
crs_s5: db "*SPI-Addons", 0
crs_s6: db "*Key-constants", 0
crs_sound: db "*Sound-Util", 0



endif
;prom_c2b: db "Select Storage Bank",0
prom_c4: db "Settings",0
prom_m4:   db "Debug & Breakpoints On/Off",0
prom_m4b:   db "Monitor",0
prom_c1: db "Hardware Diags",0


if STARTUP_V2
prom_c9: db "Create Startup Files",0
endif

prom_notav:    db "Feature not available",0
prom_empty:    db "",0

; eof

