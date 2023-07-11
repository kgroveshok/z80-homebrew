;10/7/20
;Add CPM3 boot command
;Add command to save cpm3 loader in CF
; EPROM monitor for SSIO, Z80 with SIO2
; program copied from SSIO_selfboot v0.4
; 7/2/19
SIOAData	equ 0		;location of SIO chan A data
SIOACmd	equ 1		;location of SIO A command/status reg
SIOBData	equ 2		;location of SIO chan B data
SIOBCmd	equ 3		;location of SIO B command/status reg
CFdata   	equ 90h    	;CF data register
CFerr    	equ 91h    	;CF error reg
CFsectcnt equ 92h    	;CF sector count reg
CF07     	equ 93h   	;CF LA0-7
CF815    	equ 94h       	;CF LA8-15
CF1623   	equ 95h       	;CF LA16-23
CF2427   	equ 96h       	;CF LA24-27
CFstat   	equ 97h       	;CF status/command reg

	org 0
start:
	jp mainjmp

	org 0b100h
;move some messages to free up program memory below $C000
copywarn$ db 10,13,"Program will be overwritten, enter Y to prceed ",0
xwarn$	db 10,13,"Drive will be formatted, enter Y to proceed ",0
copycf$	db "opy to CF disk",10,13
	db "0--boot,",10,13
;	db "1--User Apps,",10,13
	db "2--CP/M2.2,",10,13
	db "3--CP/M3: "
	db 0
clrdir$	db " clear disk directories",10,13
	db "A -- drive A,",10,13
	db "B -- drive B,",10,13
	db "C -- drive C,",10,13
	db "D -- drive D: "	
	db 0
bootcpm$	db "oot CP/M",10,13
;	db "1--User Apps,",10,13
	db "2--CP/M2.2,",10,13
	db "3--CP/M3: "
	db 0
HELP$	db "elp",13,10
	db "G <addr> CR",13,10
	db "D <start addr> <end addr>",13,10
	db "I <port>",13,10
	db "O <value> <port>",13,10
	db "L <start addr> <end addr>",13,10
	db "Z CR",13,10
	db "F CR",13,10
	db "T CR",13,10
	db "E <addr>",13,10,0
HELPCF$	db "R <track> <sector>",13,10
	db "X <options> CR",13,10
	db "B <options> CR",13,10
	db "C <options> CR",13,10
	db 0
track$	db " track:0x",0
sector$	db " sector:0x",0
read$	db "ead CF disk",0
RDmore$	db 10,13,"carriage return for next sector, any other key for command prompt",10,13,0
notsame$	db 10,13,"Data NOT same as previous read",10,13,0
issame$	db 10,13,"Data same as previous read",10,13,0
; variable area
	org 0b400h
mainjmp:
	jp main
	jp clrRx		;warm boot starting point
	jp cin		;console input
	jp cout		;console output
testseed: ds 2		; RAM test seed value
addr3116	ds 2		; high address for Intel Hex format 4
RDsector	ds 1		; current RAM disk sector
RDtrack	ds 1		; current RAM disk track 
RDaddr	ds 2		; current RAM disk address 
sectoff	ds 2		; offset from a track & sector
fCFRdy	ds 1		;flag indicate CF disk is present
main:
;if R16 is grounded (this is an engineering change up to ver1.2 pcb)
;  copy to lower 64K of RAM 
;otherwise this is copy to upper 64K of RAM
	ld hl,0		;copy EPROM into RAM
	ld de,0
	ld bc,100h	;copy page 0 
	ldir
	ld hl,0b100h	;copy program starting from 0xb100
	ld de,0b100h
	ld bc,1000h	;copy 4K of program
	ldir
	ld hl,0ff00h	;copy program at top of memory (shadow mover)
	ld de,0ff00h
	ld bc,0100h	;copy page $FF
	ldir
;if R16 is grounded (this is an engineering change up to ver1.2 pcb)
;  copy to upper 64K of RAM 
;otherwise this is duplicated copy to upper 64K of RAM
	ld a,18h
	out (SIOBCmd),a	;reset Wr0 
	ld a,11h		;Wr0 point to reg1 + reset ex st int
	out (SIOBCmd),a
	ld a,40h
	out (SIOBCmd),a	;Wr1 No Tx interrupts, set READY high
	ld hl,0		;copy EPROM into RAM
	ld de,0
	ld bc,100h	;copy page 0 
	ldir
	ld hl,0b100h	;copy program starting from 0xb100
	ld de,0b100h
	ld bc,1000h	;copy 4K of program
	ldir
	ld hl,0ff00h	;copy program at top of memory (shadow mover)
	ld de,0ff00h
	ld bc,0100h	;copy page $FF
	ldir

	ld c,SIOACmd	;initialize SIO chan A
          ld hl,SIOAIni     	;Point to initialisation data
          ld b,9	 	;Length of ini data
          otir                ;Write data to output port C
          ld c,SIOBCmd      ;initialize SIO chan B
          ld hl,SIOBIni      ;Point to initialization data
          ld b,9            ;length of init data
          otir
; memory is now all RAM
	ld sp,0b400h	;set up stack below monitor
	ld hl,signon
	call strout
	call chkCFRdy	;check for CF present, fCFRdy set and Z flag not set if CF present
	jr z,seedRAM	;skip over CF initialization if CF not present
	ld hl,CFpresent	;note that CF disk is detected
	call strout
	ld a,0e0h		;;8 set up LBA mode
	out (CF2427),a	;;8
	ld a,1		;;8 set feature to 8-bit interface
	out (CFerr),a	;;8
	ld a,0efh		;;8 set feature command
	out (CFstat),a	;;8
	call readbsy	;;8 wait until busy flag is cleared
seedRAM:
	ld hl,251		; initialize RAM test seed value
	ld (testseed),hl	; save it
clrRx:  
        	IN A,(SIOACmd)	; read on-chip UART receive status
        	AND 1		; data available?
        	jr z,CMD
        	IN A,(SIOAData)	; read clear the input buffer
	jr clrRx
CMD:
	ld hl,prompt$
	call strout
CMDLP1:
	call cinq
	cp ':'		; Is this Intel load file?
	jr z,initload
	cp 0ah		; ignore line feed
	jr z,CMDLP1
	cp 0dh		; carriage return get a new prompt
	jr z,CMD
	CALL cout		; echo character
        	AND 5Fh
	cp 'H'		; help command
	jp z,HELP
        	CP A,'D'
        	JP Z,MEMDMP
        	CP A,'E'
        	JP Z,EDMEM
	cp a,'I'		; read data from specified I/O port in page 0
	jp z,INPORT
	cp a,'O'		; write data to specified I/O port in page 0
	jp z,OUTPORT
	cp a,'L'		; list memory as Intel Hex format
	jp z,LISTHEX
        	CP A,'G'
        	JP Z,go
	cp a,'R'		;read a CF sector
	jp z,READCF
	cp a,'Z'		; fill memory with zeros
	jp z,fillZ
	cp a,'F'		; fill memory with ff
	jp z,fillF
	cp a,'T'		; testing RAM 
	jp z,TESTRAM
	cp a,'X'		;initialize CF drives
	jp z,format
	cp a,'C'
	jp z,COPYCF	;copy memory into CF disk
	cp a,'B'
	jp z,BootCPM	;boot CP/M 
what:
        	LD HL, what$
        	CALL strout
        	jr CMD
abort:
	ld hl,abort$	; print command not executed
	call strout
	jr CMD
; initialize for file load operation
initload:
	ld hl,0		; clear the high address in preparation for file load
	ld (addr3116),hl	; addr3116 modified with Intel Hex format 4 
; load Intel file
fileload:
	call GETHEXQ	; get two ASCII char (byte count) into hex byte in reg A
	ld d,a		; save byte count to reg D
	ld c,a		; save copy of byte count to reg C
	ld b,a		; initialize the checksum
	call GETHEXQ	; get MSB of address
	ld h,a		; HL points to memory to be loaded
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
	call GETHEXQ	; get LSB of address
	ld l,a
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
	call GETHEXQ	; get the record type, 0 is data, 1 is end
	cp 0
	jp z,filesave
	cp 1		; end of file transfer?
	jr z,fileend
	cp 4		; Extended linear address?
	jp nz,unknown	; if not, print a 'U'
; Extended linear address for greater than 64K
; this is where addr3116 is modified
	add a,b		; accumulating checksum of record type
	ld b,a		; checksum is kept in reg B
	ld a,d		; byte count should always be 2
	cp 2
	jr nz,unknown
	call GETHEXQ	; get first byte (MSB) of high address
	ld (addr3116+1),a	; save to addr3116+1
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
; Little Endian format.  MSB in addr3116+1, LSB in addr3116
	call GETHEXQ	; get the 2nd byte (LSB) of of high address
	ld (addr3116),a	; save to addr3116
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
	call GETHEXQ	; get the checksum
	neg a		; 2's complement
	cp b		; compare to checksum accumulated in reg B
	jr nz,badload	; checksum not match, put '?'
	ld a,'E'		; denote a successful Extended linear addr update
	jr filesav2
; end of the file load
fileend:
	call GETHEXQ	; flush the line, get the last byte
	ld a,'X'		; mark the end with 'X'
	call cout
	ld a,10			; carriage return and line feed
	call cout
	ld a,13
	call cout
	jp CMD
; the assumption is the data is good and will be saved to the destination memory
filesave:
	add a,b		; accumulating checksum of record type
	ld b,a		; checksum is kept in reg B
	ld ix,0c000h	; 0c000h is buffer for incoming data
filesavx:
	call GETHEXQ	; get a byte
	ld (hl),a		;Z80SBC save data to destination
	add a,b		; accumulating checksum
	ld b,a		; checksum is kept in reg B
	inc ix
	inc hl		;Z80SBC 
	dec d
	jr nz,filesavx
	call GETHEXQ	; get the checksum
	neg a		; 2's complement
	cp b		; compare to checksum accumulated in reg B
	jr nz,badload	; checksum not match, put '?'

	ld a,'.'		; checksum match, put '.'
filesav2:
	call cout
	jr flushln	; repeat until record end
badload:
	ld a,'?'		; checksum not match, put '?'
	jr filesav2
unknown:
	ld a,'U'		; put out a 'U' and wait for next record
	call cout
flushln:
	call cinq		; keep on reading until ':' is encountered
	cp ':'
	jr nz,flushln
	jp fileload
INPORT:
; read data from specified I/O port in page 0
; command format is "I port#"
; 
	ld hl,inport$	; print command 'I' prompt
	call strout
	call GETHEX	; get port # into reg A
	jp c,CMD		;abort for non-hexdecimal input
	jp z,CMD	
	push bc		; save register
	ld c,a		; load port # in reg C
	in b,(c)		; get data from port # into reg B
	ld hl,invalue$
	call strout
	ld a,b
	call HEXOUT
	pop bc		; restore reg
	jp CMD
OUTPORT:
; write data to specified I/O port in page 0
; command format is "O value port#"
	ld hl,outport$	; print command 'O' prompt
	call strout
	call GETHEX	; get value to be output
	jp c,CMD		;abort for non-hexdecimal input
	jp z,CMD	
	push bc		; save register
	ld b,a		; load value in reg B
	ld hl,outport2$	; print additional prompt for command 'O'
	call strout
	call GETHEX	; get port number into reg A
	jr c,OUTPORT9	;abort for non-hexdecimal input
	jr z,OUTPORT9	
	ld c,a
	out (c),b		; output data in regB to port in reg C
OUTPORT9:
	pop bc
	jp CMD
LISTHEX:
; list memory as Intel Hex format
; the purpose of command is to save memory as Intel Hex format to console
	ld hl,listhex$	; print command 'L' prompt
	call strout
	call ADRIN	; get address word into reg DE
	jp z,CMD		;return to command prompt if illegal input
	push de		; save for later use
	ld hl,listhex1$	; print second part of 'L' command prompt
	call strout
	call ADRIN	; get end address into reg DE
	jp z,CMD		;return to command prompt if illegal input
listhex1:
	ld hl,CRLF$	; put out a CR, LF	
	call strout
	ld c,10h		; each line contains 16 bytes
	ld b,c		; reg B is the running checksum
	ld a,':'		; start of Intel Hex record
	call cout
	ld a,c		; byte count
	call HEXOUT
	pop hl		; start address in HL
	call ADROUT	; output start address
	ld a,b		; get the checksum
	add a,h		; accumulate checksum
	add a,l		; accumulate checksum
	ld b,a		; checksum is kept in reg B
	xor a		
	call HEXOUT	; record type is 00 (data)
listhex2:
	ld a,(hl)		; get memory pointed by hl
	call HEXOUT	; output the memory value in hex
	ld a,(hl)		; get memory again
	add a,b		; accumulate checksum
	ld b,a		; checksum is kept in reg B
	inc hl
	dec c
	jp nz,listhex2
	ld a,b		; get the checksum
	neg a
	call HEXOUT	; output the checksum
; output 16 memory location, check if reached the end address (saved in reg DE)
; unsign compare: if reg A < reg N, C flag set, if reg A > reg N, C flag clear
	push hl		; save current address pointer
	ld a,h		; get MSB of current address
	cp d		; reg DE contain the end address
;	jp nc,hexend	; if greater, output end-of-file record
	jp c,listhex1	; if less, output more record
	jp nz,hexend	;if greater (no carry and not equal), output end-of-file record
; if equal, compare the LSB value of the current address pointer
	ld a,l		; now compare the LSB of current address
	cp e
	jp c,listhex1	; if less, output another line of Intel Hex
hexend:
; end-of-record is :00000001FF
	ld hl,CRLF$
	call strout
	ld a,':'		; start of Intel Hex record
	call cout
	xor a
	call HEXOUT	; output "00"
	xor a
	call HEXOUT	; output "00"
	xor a
	call HEXOUT	; output "00"
	ld a,1
	call HEXOUT	; output "01"
	ld a,0ffh
	call HEXOUT	; output "FF"

	pop hl		; clear up the stack

	jp CMD

; print help message
HELP:
	ld hl,HELP$	; print help message
	call strout
	ld a,(fCFRdy)	;check CF present flag before print CF related helps
	cp 0
	jp z,CMD
	ld hl,HELPCF$	;print CF related help commands 
	call strout
	jp CMD
fillZ:
	ld hl,fill0$	; print fill memory with 0 message
	call strout
	ld b,0		; fill memory with 0
	jp dofill
fillF:
	ld hl,fillf$	; print fill memory with F message
	call strout
	ld b,0ffh		; fill memory with ff
dofill:
	ld hl,confirm$	; get confirmation before executing
	call strout
	call tstCRLF	; check for carriage return
	jp nz,abort
	ld hl,PROGEND	; start from end of this program
;	ld a,0ffh		; end address in reg A
filla:
	ld (hl),b		; write memory location
	inc hl
	cp h		; reached 0xFF00?
	jp nz,filla	; continue til done
	cp l		; reached 0xFFFF?
	jp nz,filla
	ld hl,0b000h	; fill value from 0xB000 down to 0x0100
fillb:
	dec hl
	ld a,h		;do until h=0
	cp 0
	jp z,CMD
	ld (hl),b		; write memory location with desired value
	jr fillb
TESTRAM:
; test memory from top of this program to 0xFFFE 
	ld hl,testram$	; print test ram message
	call strout
	ld hl,confirm$	; get confirmation before executing
	call strout
	call tstCRLF	; check for carriage return
	jp nz,abort
	ld iy,(testseed)	; a prime number seed, another good prime number is 211
TRagain:
	ld hl,PROGEND	; start testing from the end of this program
	ld de,137		; increment by prime number
TRLOOP:
	push iy		; bounce off stack
	pop bc
	ld (hl),c		; write a pattern to memory
	inc hl
	ld (hl),b
	inc hl
	add iy,de		; add a prime number
	ld a,0ffh		; compare h to 0xff
	cp h
	jp nz,TRLOOP	; continue until reaching 0xFFFE
	ld a,0feh		; compare l to 0xFE
	cp l
	jp nz,TRLOOP
	ld hl,0b000h	; test memory from 0xAFFF down to 0x0000
TR1LOOP:
	push iy
	pop bc		; bounce off stack
	dec hl
	ld (hl),b		; write MSB
	dec hl
	ld (hl),c		; write LSB
	add iy,de		; add a prime number
	ld a,h		; check h=l=0
	or l
	jp nz,TR1LOOP
	ld hl,PROGEND	; verify starting from the end of this program
	ld iy,(testseed)	; starting seed value
TRVER:
	push iy		; bounce off stack
	pop bc
	ld a,(hl)		; get LSB
	cp c		; verify
	jp nz,TRERROR
	inc hl
	ld a,(hl)		; get MSB
	cp b
	jp nz,TRERROR
	inc hl
	add iy,de		; next reference value
	ld a,0ffh		; compare h to 0xff
	cp h
	jp nz,TRVER	; continue verifying til end of memory
	ld a,0feh		; compare l to 0xFE
	cp l
	jp nz,TRVER
	ld hl,0b000h	; verify memory from 0xB000 down to 0x0000
TR1VER:
	push iy		; bounce off stack
	pop bc
	dec hl
	ld a,(hl)		; get MSB from memory
	cp b		; verify
	jp nz,TRERROR
	dec hl
	ld a,(hl)		; get LSB from memory
	cp c
	jp nz,TRERROR
	add iy,de
	ld a,h		; check h=l=0
	or l
	jp nz,TR1VER
	call SPCOUT	; a space delimiter
	ld a,'O'		; put out 'OK' message
	call cout
	ld a,'K'
	call cout
	ld (testseed),iy	; save seed value

	IN A,(SIOACmd)	; read on-chip UART receive status
        	AND 1				;;Z data available?
        	JP Z,TRagain	; no char, do another iteration of memory test
	ld a,0c3h		;restore 'jp mainjmp' instruction in 0x00
	ld (0),a		;instruction in binary is 0xc3, 0x00, 0xb4
	xor a
	ld (1),a
	ld a,0b4h
	ld (2),a
	jp clrRx		; clear the UART receive buffer and return to CMD
TRERROR:
	call SPCOUT	; a space char to separate the 'r' command
	ld a,'H'		; display content of HL reg
	call cout		; print the HL label
	ld a,'L'
	call cout
	call SPCOUT	
	call ADROUT	; output the content of HL 	
	jp CMD

;Get an address and jump to it
go:
	ld hl,go$		; print go command message
	call strout
        	CALL ADRIN
	jp z,CMD		;return to command prompt if illegal input
        	LD H,D
        	LD L,E
	push hl		; save go address
	ld hl,confirm$	; get confirmation before executing
	call strout
	call tstCRLF	; check for carriage return
	pop hl
	jp nz,abort
	jp (hl)		; jump to address if CRLF
;test for 'Y'. Echo back, set Z flag if 'Y' received
tstY:
	call cin		; get a character					
	cp 'Y'
	ret

; test for CR or LF.  Echo back. return 0
tstCRLF:
	call cin		; get a character					
	cp 0dh		; if carriage return, output LF
	jp z,tstCRLF1
	cp 0ah		; if line feed, output CR 
	jp z,tstCRLF2
	ret
tstCRLF1:
	ld a,0ah		; put out a LF
	call cout
	xor a		; set Z flag
	ret
tstCRLF2:
	ld a,0dh		; put out a CR
	call cout
	xor a		; set Z flag
	ret
; Read CF disk
; data buffer is at 0x1000
; previous data is at 0x2000 for comparison to current data
READCF:
	ld hl,read$	; put out read command message
	call strout
	ld hl,track$	; enter track in hex value
	call strout
	call GETHEX	; get a byte of hex value as track
	jp c,CMD		;abort for non-hexdecimal input
	jp z,CMD	
	ld (RDtrack),a	; save it 
	ld hl,sector$	; enter sector in hex value
	call strout
	call GETHEX	; get a byte of hex value as sector
	jp c,CMD		;abort for non-hexdecimal input
	jp z,CMD	
	ld (RDsector),a	; save it
READRD1:
	ld hl,1000h	; copy previous block to 2000h
	ld de,2000h
	ld bc,200h	; copy 512 bytes
	ldir		; block copy

	ld a,0e0h		; set Logical Address addressing mode
	out (CF2427),a
	ld a,1		; read 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,0		; read first sector
	out (CF1623),a	; high byte of track is always 0
	ld a,(RDsector)	;Z80SBC get sector value
	out (CF07),a	; write sector
	ld a,(RDtrack)
	out (CF815),a
	ld a,20h		; read sector command
	out (CFstat),a	; issue the read sector command
	call chkdrq	; check data request bit set before write CF data
	ld hl,1000h	; store CF data starting from 1000h
	ld c,CFdata	; reg C points to CF data reg
	ld b,0h		; sector has 256 16-bit data
	inir		;Z80SBC
	ld b,0h		;Z80SBC 2nd half of 512-byte sector
	inir

dumpdata:
	ld d,32		; 32 lines of data
	ld hl,1000h	; display 512 bytes of data
dmpdata1:
	push hl		; save hl
	ld hl,CRLF$	; add a CRLF per line
	call strout
	pop hl		; hl is the next address to display
	call DMP16TS	; display 16 bytes per line
	dec d
	jp nz,dmpdata1

	ld hl,1000h	; compare with data block in 2000h
	ld bc,200h
	ld de,2000h
blkcmp:
	ld a,(de)		; get a byte from block in 2000h
	inc de
	cpi		; compare with corresponding data in 1000h
	jp po,blkcmp1	; exit at end of block compare
	jp z,blkcmp	; exit if data not compare
	ld hl,notsame$	; send out message that data not same as previous read
	call strout
	jp chkRDmore
blkcmp1:	
	ld hl,issame$	; send out message that data read is same as before
	call strout

chkRDmore:
	ld hl,0		;clear sector offset value
	ld (sectoff),hl
	ld hl,RDmore$	; carriage return for next sector of data
	call strout
	call tstCRLF	; look for CRLF
	jp nz,CMD		; 
	ld hl,(RDsector)	; load track & sector as 16-bit value
	inc hl		; increment by 1
	ld (RDsector),hl	; save updated values
	ld hl,track$	; print track & sector value
	call strout
	ld a,(RDtrack)
	call HEXOUT
	ld hl,sector$
	call strout
	ld a,(RDsector)
	call HEXOUT
	jp READRD1
chkCFRdy:
;check CF disk is present
;set fCFRdy if present
;return 
	ld hl,0
	ld b,5		;pass count of 5 is about 1 seconds
	xor a
	ld (fCFRdy),a	;clear CF present flag
	call waitBsy	;wait up to 1 second
	ret nz
	ld hl,waitCF$	;waiting on CF
	call strout
	ld hl,0
	ld b,15		;pass count of 15 is about 3 seconds
	call waitBsy	;wait 3 more seconds
	ret nz
	ld hl,timeoutCF$
	call strout
	xor a		;set Z flag
	ret		;return with Z set and fCFRdy = 0
waitBsy:			;inner loop is 48 clocks or 200mS per inner loop
	in a,(CFstat)	;(11) read CF status 
	and 80h		;(7) mask off all except busy bit
	jr z,CFfound	;(10)
	inc hl		;(6)
	cp h		;(4) regA is 80h for this comparison
	jr nz,waitBsy	;(10)
	ld hl,0		;(10)
	dec b		;(4) decrease loop count until zero
	jr nz,waitBsy	;(10)
	ret
CFfound:
	inc a		;regA is now not zero
	ld (fCFRdy),a	;CF present flag is set
	ret		
readbsy:
; spin on CF status busy bit
	in a,(CFstat)	; read CF status 
	and 80h		; mask off all except busy bit
	jr nz,readbsy
	ret
chkdrq:
	in a,(CFstat)	; check data request bit set before write CF data
	and 8		; bit 3 is DRQ, wait for it to set
	jr z,chkdrq
	ret
; format CF drives directories 
; drive A directory is track 1, sectors 0-0x1F
; drive B directory is track 0x40, sectors 0-0x1F
; drive C directory is track 0x80, sectors 0-0x1F
; drive D directory is track 0xC0, sectors 0-0x1F
format:
	ld hl,clrdir$	; command message
	call strout
	call cin
	cp 'A'
	jr z,formatA	; fill track 1 sectors 0-0x1F with 0xE5
	cp 'B'
	jr z,formatB	; fill track 0x40 sectors 0-0x1F with 0xE5
	cp 'C'
	jr z,formatC	; fill track 0x80 sectors 0-0x1F with 0xE5
	cp 'D'
	jr z,formatD	; fill track 0xC0 sectors 0-0x1F with 0xE5
	jp abort		; abort command if not in the list of options
formatA:
	ld de,100h	; start with track 1 sector 0
	jr doformat
formatB:
	ld de,4000h	; start with track 0x40 sector 0
	jr doformat
formatC:
	ld de,8000h	; start with track 0x80 sector 0
	jr doformat
formatD:
	ld de,0c000h	; start with track 0xC0 sector 0
doformat:
;	ld hl,confirm$	; confirm command execution
	ld hl,xwarn$
	call strout
	call tstY
;	call tstCRLF
	jp nz,abort	; abort command if not CRLF
	ld a,0e0h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; MSB track is 0
	ld a,d		; reg D contains the track info
	out (CF815),a
	ld c,CFdata	; reg C points to CF data reg
	ld hl,0e5e5h	; value for empty directories
wrCFf:
	ld a,1		; write 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,e		; write CPM sector
	cp 20h		; format sector 0-0x1F
	jp z,wrCFdonef	; done formatting
	out (CF07),a	; 
	ld a,30h		; write sector command
	out (CFstat),a	; issue the write sector command
	call chkdrq	; check data request bit set before write CF data

	ld b,0h		; sector has 256 16-bit data
loopf:
	out (c),h		;z80 writes 2 bytes to CF
	out (c),h	
	inc b
	jp nz,loopf
	call readbsy	;wait on CF status busy bit

	inc e		; write next sector
	jp wrCFf
wrCFdonef:
	ld hl,done$
	call strout
	jp CMD
; boot CPM
; copy program from LA9-LA26 (9K) to 0xDC00
; jump to 0xF200 after copy is completed.
BootCPM:
	ld hl,bootcpm$	; print command message
	call strout
	call cin		; get input
;	cp '1'		; '1' is user apps
;	jp z,bootApps
	cp '2'		; '2' is cpm2.2
	jp z,boot22
	cp '3'		; '3' is cpm3, not implemented
	jp z,boot3
	jp what
boot3:
	ld hl,confirm$	; CRLF to execute the command
	call strout
	call tstCRLF
	jp nz,abort	; abort command if no CRLF
	ld a,0e0h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; track 0
	out (CF815),a
	ld hl,1100h	; CPM3LDR starts from 0x1100
	ld c,CFdata	; reg C points to CF data reg
	ld d,1h		; read from LA 1 to LA 0x0f, 7K--much bigger than needed
readCPM3:
	ld a,1		; read 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,d		; read CPM sector
	cp 10h		; between LA1 and LA0fh
	jp z,goCPM3	; done copying, execute CPM
	out (CF07),a	; 
	ld a,20h		; read sector command
	out (CFstat),a	; issue the read sector command
	call chkdrq	;check data request bit set before write CF data
	ld b,0h		; sector has 256 16-bit data
	inir		;z80 read 256 bytes
	ld b,0h		;z80
	inir		;z80 read 256 bytes

	inc d		; read next sector
	jp readCPM3
goCPM3:
	jp 01100h		; BIOS starting address of CP/M

boot22:
	ld hl,confirm$	; CRLF to execute the command
	call strout
	call tstCRLF
	jp nz,abort	; abort command if no CRLF
	ld a,0e0h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; track 0
	out (CF815),a
	ld hl,0dc00h	; CPM starts from 0xDC00 to 0xFFFF
	ld c,CFdata	; reg C points to CF data reg
	ld d,80h		; read from LA 0x80 to LA 0x92
readCPM1:
	ld a,1		; read 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,d		; read CPM sector
	cp 92h		; between LA80h and LA91h
	jp z,goCPM	; done copying, execute CPM
	out (CF07),a	; 
	ld a,20h		; read sector command
	out (CFstat),a	; issue the read sector command
	call chkdrq	; check data request bit set before write CF data
	ld b,0h		; sector has 256 16-bit data
	inir		;z80 read 256 bytes
	ld b,0h		;z80
	inir		;z80 read 256 bytes

	inc d		; read next sector
	jp readCPM1
goCPM:
	jp 0f200h		; BIOS starting address of CP/M

;bootApps:
;copy user application from page 0 0x4000-0x7FFF to common area
;then copy from common area to normal 0x0-0x3FFF
;common area is 4K, 0xA000-0xAFFF
;jump into 0x0 when done
;	ld hl,confirm$	; CRLF to execute the command
;	call strout
;	call tstCRLF
;	jp nz,abort	; abort command if no CRLF
;
;	ld de,0		;copy 4K from bootstrap page 0x4000
;	ld hl,4000h	;to normal page 0x0
;	call copy2norm
;	ld de,1000h	;copy 4K from bootstrap page 0x5000
;	ld hl,5000h	;to normal page 0x1000
;	call copy2norm
;	ld de,2000h	;copy 4K from bootstrap page 0x6000
;	ld hl,6000h	;to normal page 0x2000
;	call copy2norm
;	ld de,3000h	;copy 4K from bootstrap page 0x7000
;	ld hl,7000h	;to normal page 0x3000
;	call copy2norm

;	jp 0		;start execution of user apps

	; Write CF
;  allowable parameters are '0' for boot sector & ZZMon, '1' for 32K apps, 
;   '2' for CPM2.2, '3' for CPM3
; Set page I/O to 0, afterward set it back to 0FEh
COPYCF:
	ld hl,copycf$	; print copy message
	call strout
	call cin		; get write parameters
;	cp '0'
;	jp z,cpboot
;	cp '1'
;	jp z,cpAPPS
	cp '2'
	jp z,CopyCPM2
	cp '3'
	jp z,CopyCPM3
	jp what		; error, abort command

	jp CMD

; write CPM to CF
; write data from 0xDC00 to 0xFFFF to CF LA128-LA146 (9K)
CopyCPM2:
	ld hl,0dc00h	; CPM starts from 0xDC00 to 0xFFFF
	ld de,8092h	; reg DE contains beginning sector and end sector values
	jp wrCF
CopyCPM3:
	ld hl,1100h	; CPMLDR starts from 0x1100
	ld de,0110h	; reg DE contains beginning sector and end sector values
	jp wrCF
;cpAPPS:
; 16K of user application such as SCMonitor is stored in page 0, 0x4000 to 0x7FFF
; This assuiming the user application is already loaded from 0x0 to 0x3FFF
;copy 4K to common area, 0xA000-0xAFFF and then copy into page 0
;	ld hl,confirm$	; carriage return to execute the program
;	call strout
;	call tstCRLF
;	jp nz,CMD		; abort command if not CR or LF
;	ld hl,0		;copy 4K from normal page 0x0
;	ld de,4000h	;to bootstrap page 0x4000		
;	call copy2boot
;	ld hl,1000h	;copy 4K from normal page 0x1000
;	ld de,5000h	;to bootstrap page 0x5000
;	call copy2boot
;	ld hl,2000h	;copy 4K from normal page 0x2000
;	ld de,6000h	;to bootstrap page 0x6000
;	call copy2boot
;	ld hl,3000h	;copy 4K from normal page 0x3000
;	ld de,7000h	;to bootstrap page 0x7000
;	call copy2boot
;	xor a		; set to normal page to protect the bootstrap area
;	out (bankReg),a	; 
;	jp CMD		; jump back to command handler


wrCF:
	push hl		; save value
;	ld hl,confirm$	; carriage return to execute the program
	ld hl,copywarn$	;warning file will be overwritten
	call strout
	pop hl
;	call tstCRLF
	call tstY
	jp nz,abort	;abort command if not 'Y'
	ld a,0e0h		; set Logical Address addressing mode
	out (CF2427),a
	xor a		; clear reg A
	out (CF1623),a	; track 0
	out (CF815),a
	ld c,CFdata	; reg C points to CF data reg
wrCF1:
	ld a,1		; write 1 sector
	out (CFsectcnt),a	; write to sector count with 1
	ld a,d		; write CPM sector
	cp e		; reg E contains end sector value
	jp z,wrCFdone	; done copying, execute CPM
	out (CF07),a	; 
	ld a,30h		; write sector command
	out (CFstat),a	; issue the write sector command
	call chkdrq	; check data request bit set before write CF data
	ld b,0h		; sector has 256 16-bit data
	otir		;z80 write 256 bytes
	ld b,0h		;z80
	otir		;z80 wrute 256 bytes

	call readbsy	;wait until busy flag is cleared

	inc d		; write next sector
	jp wrCF1
wrCFdone:
	ld hl,done$	;command completed message
	call strout
	jp CMD

;Edit memory from a starting address until X is
;pressed. Display mem loc, contents, and results
;of write.
EDMEM:  	CALL SPCOUT
        	CALL ADRIN
	jp z,CMD		;abort command if illegal input
        	LD H,D
        	LD L,E
EDMEM1:    	
	LD A,13
        	CALL cout
        	LD A,10
        	CALL cout
        	CALL ADROUT
        	CALL SPCOUT
        	LD A,':'
        	CALL cout
        	CALL SPCOUT
        	CALL DMPLOC
        	CALL SPCOUT
        	CALL GETHEX
	jp c,CMD		;abort for illegal input
 	jp z,EDMEM2	;handle CR, -, x inputs
        	LD (HL),A
        	CALL SPCOUT
        	CALL DMPLOC
        	INC HL
        	JP EDMEM1
EDMEM2:
;handle non-hexdecimal input of CR, -, x or X
	cp '-'		;go to previous location
	jp nz,EDMEM3
	dec hl
	jp EDMEM1
EDMEM3:
	cp 0dh		;go to next location
	jp nz,CMD		;abort command for all other non-hex input
	inc hl
	jp EDMEM1

;Dump memory between two address locations
MEMDMP: 	CALL SPCOUT
        	CALL ADRIN
	jp z,CMD		;abort command if illegal input
	ld h,d
	ld l,e		;starting location is in HL
        	ld c,10h
        	CALL SPCOUT
        	CALL ADRIN	;end location is in DE
	jp z,CMD		;abort command if illegal input
MD1:    	LD A,13
        	CALL cout
        	LD A,10
        	CALL cout
        	CALL DMP16
;HL is advanced by $10 after DMP16
;HL = $000x is special case because it means a 64K rollover has occurred
; stop displaying if HL=$000x
	ld a,h
	cp 0		;check for H=0
	jp nz,not000x
	ld a,l		;check for HL=000x
	and 0f0h		;ignore lowest nibble
	cp 0
	jp z,CMD
not000x:
        	LD A,D
        	CP H
;        	JP M,CMD
	jp c,CMD
	jp nz,MD1		;if equal, compare LSB byte
        	LD A,E
        	CP L
;	jp m,CMD
	jp c,CMD
;        	JP M,MD2
        	JP MD1
MD2:    	LD A,D
        	CP H
        	JP NZ,MD1
        	JP CMD

DMP16TS:
; dump memory pointed by HL, 
; print offset from the given track & sector values
;  as the address field
	push hl		; save reg
	ld a,'+'		;print offset symbol
	call cout
	ld hl,(sectoff)	;get offset from track&sector base
	call ADROUT	; output A23..A8
	push bc		;save reg
	ld bc,10h		;add 16 to offset
	add hl,bc
	pop bc
	ld (sectoff),hl	;save it
	pop hl		; restore reg
	jp DMP16D		; display the 16 data field

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DMP16 -- Dump 16 consecutive memory locations
;
;pre: HL pair contains starting memory address
;post: memory from HL to HL + 16 printed
;post: HL incremented to HL + 16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DMP16:  	CALL ADROUT
DMP16D:			; 16 consecutive data
        	CALL SPCOUT
        	LD A,':'
        	CALL cout
        	LD C,10h
	push hl		; save location for later use
DM1:    	CALL SPCOUT
        	CALL DMPLOC
        	INC HL		
        	DEC C
	jp nz,DM1

; display the ASCII equivalent of the hex values
	pop hl		; retrieve the saved location
	ld c,10h		; print 16 characters
	call SPCOUT	; insert two space
	call SPCOUT	; 
dm2:
	ld a,(hl)		; read the memory location
	cp ' '
	jp m,printdot	; if lesser than 0x20, print a dot
	cp 7fh
	jp m,printchar
printdot:
; for value lesser than 0x20 or 0x7f and greater, print '.'
	ld a,'.'
printchar:
; output printable character
	call cout
	inc hl
	dec c
	ret z
	jp dm2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DMPLOC -- Print a byte at HL to console
;
;pre: HL pair contains address of byte
;post: byte at HL printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DMPLOC: 	LD A,(HL)
        	CALL HEXOUT
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HEXOUT -- Output byte to console as hex
;
;pre: A register contains byte to be output
;post: byte is output to console as hex
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HEXOUT: 	PUSH BC
        	LD B,A
        	RRCA
        	RRCA
        	RRCA
        	RRCA
        	AND 0Fh
        	CALL HEXASC
        	CALL cout
        	LD A,B
        	AND 0Fh
        	CALL HEXASC
        	CALL cout
        	POP BC
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;HEXASC -- Convert nybble to ASCII char
;
;pre: A register contains nybble
;post: A register contains ASCII char
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HEXASC: 	ADD 90h
        	DAA
        	ADC A,40h
        	DAA
        	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ADROUT -- Print an address to the console
;
;pre: HL pair contains address to print
;post: HL printed to console as hex
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ADROUT: 	LD A,H
        	CALL HEXOUT
        	LD A,L
        	CALL HEXOUT
        	RET

;ADRIN -- Get up to 4 bytes address from console in reg DE
; if illegal address, set Z flag
;
;pre: none
;post: DE contains address from console
ADRIN:
	ld de,0		
	call cin
	call ASCHEX	;get a hex value
; none hex value will end command
	jr z,exit0
	ld e,a		;save
backup1:		
	call cin
	cp 8		;backspace?
	jr z,ADRIN	;start over
  	call ASCHEX
;possible options here are 
; backspace
; space to advance command
; other none hex to terminate command
	jr z,exit123
	sla e
	sla e
	sla e
	sla e
	or e
	ld e,a		;save to reg E
getChar3:
	call cin
	cp 8
	jr z,backupE
	call ASCHEX
	jr z,exit123
	call addChar
	call cin
	cp 8
	jr z,delChar
	call ASCHEX
	jr z,exit123	;exit with 3 characters entered
	call addChar
	cp 0		;force clear Z flag 
	ret nz		;return with Zflag cleared
	cp 1
	ret		;return with Z flag cleared
backupE:
;shift regE back a nibble
	srl e
	srl e
	srl e
	srl e
	jr backup1
delChar:
;shift DE back a nibble
	sra d
	rr e
	sra d
	rr e
	sra d
	rr e
	sra d
	rr e
	ld d,0
	jr getChar3
addChar:
;shift DE forward a nibble and add reg A
	sla e
	rl d
	sla e
	rl d
	sla e
	rl d
	sla e
	rl d
	or e
	ld e,a
	ret
exit123
;if space or CR, return with Z flag cleared and valid data in DE
	cp ' '
	jr z,exitGood
	cp 0dh
	jr z,exitGood
exit0:
	xor a		;set Z flag
	ret
exitGood:
	or a		;regA is either space or CR, so this will clear Z flag
	ret

;Get hex in regA
; set C flag to abort the operation <-expect calling routine to chk C flag first
; set Z flag to signal different action for calling routine:
;  x terminate command
;  - go back to previous memory location
;  CR next memory location
GETHEX0:
	call cout		;echo back
	pop de		;start over but first undo the regDE push
GETHEX:
        	CALL cin
        	CALL ASCHEX
;valid first character are:
; hexdecimal value
;  CR,x,-  to be handled by calling routine
;  
	ret z		;not valid hex
	push de
        	LD D,A		;save to combine with 2nd input
        	CALL cinq		;don't automatic echo back on 2nd character
			;supress echo back of CR
;valid second character are:
; hexdecimal value,
; CR: one digit input
; BS: go back to beginning
; otherwise abort the command using C flag for signalling
	cp 8		;back space?
	jr z,GETHEX0	;start over
	cp 0dh		;no echo back for CR
	jr nz,GE0
	or a		;clear Z flag
	ld a,d		;restore the one digit result
	pop de
	ret
GE0:
	call cout		;echo back
	call ASCHEX
	jp z,GE2
	sla d		;shift first hex input to high nibble
	sla d
	sla d
	sla d
        	or d		;combine with 2nd hex input
        	                  ;be careful, this operation may set Z flag is result is zero
        	ld d,1            ;take care of the case when result is 0 and Z flag set
	inc d		;this will clear the Z flag
GE1:    	pop de
	ret
GE2:    	scf
	pop de
	ret

; get hex without echo back
GETHEXQ:
	push de		; save register 
        	CALL cinq
        	CALL ASCHEX
        	RLCA
        	RLCA
        	RLCA
        	RLCA
        	LD D,A
        	CALL cinq
        	CALL ASCHEX
        	OR D 
  	pop de			;restore register
        	RET

;ASCHEX, convert ASCII to low nibble
;return Z flag set if not 0-9, A-F
; original value in regA returned if not hexdecimal character
ASCHEX: 	
	sub 30h		;ascii 0 is 0x30
	jp m,illegalx
	cp 0ah		;0-9?
	ret m
	sub 11h		;ascii A is 0x41
	jp m,illegaly
	add 0ah		;return values from 0xA to 0xF
	cp 10h		;A-F?
	ret m
	sub 2ah		;ascii a is 0x61
	jp m,illegalz
	add 0ah		;return values from 0xA to 0xF
	cp 10h		;a-f?
	ret m
illegalz
	add 20h-0ah	;return reg A to original value
illegaly
	add 11h
illegalx
	add 30h
	cp a		;set Z flag
	ret		;return with original regA and Z flag set

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GOBYT -- Push a two-byte instruction and RET
;         and jump to it
;
;pre: B register contains operand
;pre: C register contains opcode
;post: code executed, returns to caller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GOBYT:  	LD HL,0000
        	ADD HL,SP
        	DEC HL
        	LD (HL),0C9h
        	DEC HL
        	LD (HL),B
        	DEC HL
        	LD (HL),C
        	JP (HL)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SPCOUT -- Print a space to the console
;
;pre: none
;post: 0x20 printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SPCOUT: 	LD A,' '
        	CALL cout
        	RET

; send null terminated string pointed by HL
strout:
	ld a,(hl)		;get the character
	cp 0		;null terminator?
	ret z
	call cout		;output the character
	inc hl		;next character
	jp strout

; SIO channel initialisation data
SIOAIni:    DB  18h     ; Wr0 Channel reset

            DB  14h    ; Wr0 Pointer R4 + reset ex st int
            DB  0c4h     ; Wr4 /64, async mode, no parity
            DB  3     ; Wr0 Pointer R3
            DB  0c1h     ; Wr3 Receive enable, 8 bit 
            DB  5     ; Wr0 Pointer R5
            DB  0eah     ; Wr5 Transmit enable, 8 bit, flow ctrl
            DB  11h     ; Wr0 Pointer R1 + reset ex st int
;            DB  0     ; Wr1 No Tx interrupts, set READY low (lower 64K RAM bank)
            DB  40h     ; Wr1 No Tx interrupts, set READY high
; SIO channel initialisation data
SIOBIni:    DB  18h     ; Wr0 Channel reset

            DB  14h    ; Wr0 Pointer R4 + reset ex st int
            DB  0c4h     ; Wr4 /64, async mode, no parity
            DB  3     ; Wr0 Pointer R3
            DB  0c1h     ; Wr3 Receive enable, 8 bit 
            DB  5     ; Wr0 Pointer R5
            DB  0eah     ; Wr5 Transmit enable, 8 bit, flow ctrl
            DB  11h     ; Wr0 Pointer R1 + reset ex st int
            DB  0     ; Wr1 No Tx interrupts, set READY low (lower 64K RAM bank)
;            DB  40h     ; Wr1 No Tx interrupts, set READY high
cin:
	in a,(SIOACmd)	;check data ready
	bit 0,a
	jr z,cin
	in a,(SIOAData)	;get data in reg A
	call cout		;echo character
	ret
cinq:
; no echo back
	in a,(SIOACmd)	;check data ready
	bit 0,a
	jr z,cinq
	in a,(SIOAData)	;get data in reg A
	ret	
cout:
	push af		;save register
cout1:
	in a,(SIOACmd)	;get status
	bit 2,a		;transmit reg full?
	jr z,cout1
	pop af		;restore reg
	out (SIOAData),a	;transmit the character
	ret

copydone: db 0ah,0dh,"Boot completed",0ah,0dh,0
signon:	db "Simple80 Monitor v0.81 5/30/23",0ah,0dh,0
prompt$:	db 13, 10, 10, ">", 0
what$:   	db 13, 10, "?", 0
CRLF$	db 13,10,0
CFpresent	db "CF disk detected",0ah,0dh,0
waitCF$	db "Waiting for CF ready... ",0
timeoutCF$ db "CF not present",0ah,0dh,0
confirm$	db " press Return to execute command",0
done$	db " done",0
abort$	db 13,10,"command aborted",0
go$	db "o to address: 0x",0
inport$	db "nput from port ",0
invalue$	db 10,13,"Value=",0
outport$	db "utput ",0
outport2$	db " to port ",0
listhex$	db "ist memory as Intel Hex, start address=",0
listhex1$	db " end address=",0
fillf$	db "ill memory with 0xFF",10,13,0
fill0$	db "ero memory",10,13,0
testram$	db "est memory",10,13,0
;move some message to 0b100 to free up memory below 0c000
PROGEND:	equ 0c000h
	org 0ff00h
;shadow mover of SC108 is implemented here
;;	jp 07f06h
;;	jp 07f12h
;7f06h:
;get high RAM pointed by (DE) into regA
;;	ld a,80h
;;	out (38h),a
;;	ld a,(de)
;;	ld c,a
;;	ld a,0
;;	out (38h),a
;;	ld a,c
;;	ret
;7f12h:
;put reg A into high RAM pointed by (DE)
;;	ld c,a
;;	ld a,80h
;;	out (38h),a
;;	ld a,c
;;	ld (de),a
;;	ld a,0
;;	out (38h),a
;;	ret

	jp getHiRAM
putHiRAM:
;put regA into high RAM pointed by (DE)
	ld c,a		;save regA
	ld a,11h		;Wr0 points to reg1 + reset ex st int
	out (SIOBCmd),a
	ld a,40h		;Wr1 No Tx interrupts, set READY high
	out (SIOBCmd),a
	ld a,c
	ld (de),a
	ld a,11h		;Wr0 points to reg 1 + reset ex st int
	out (SIOBCmd),a
	ld a,0		;Wr1 No Tx interrupts, set READY low
	out (SIOBCmd),a
	ret 
getHiRAM:
;get high RAM pointed by (DE) into regA
	ld a,11h		;Wr0 points to reg1 + reset ex st int
	out (SIOBCmd),a
	ld a,40h		;Wr1 No Tx interrupts, set READY high
	out (SIOBCmd),a
	ld a,(de)
	ld c,a
	ld a,11h		;Wr0 points to reg 1 + reset ex st int
	out (SIOBCmd),a
	ld a,0		;Wr1 No Tx interrupts, set READY low
	out (SIOBCmd),a
	ld a,c
	ret

	end
