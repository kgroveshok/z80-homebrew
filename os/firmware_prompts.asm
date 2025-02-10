; Prompts 

; boot messages

prom_bootmsg:	db "z80-homebrew OS v1.6",0
prom_bootmsg1:	db "by Kevin Groves",0


; config menus

prom_c3: db "Add Dictionary To File",0
prom_c2: db "Select Autoload File",0
prom_c2a: db "Disable Autoload File", 0
prom_c2b: db "Select Storage Bank",0
prom_c4: db "Settings",0
prom_m4:   db "Debug & Breakpoints On/Off",0
prom_m4b:   db "Monitor",0
prom_c1: db "Hardware Diags",0


prom_notav:    db "Feature not available",0
prom_empty:    db "",0

; eof

