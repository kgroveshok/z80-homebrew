
z80asm -l $1.asm  
./bin2hex.py -b a.bin -o $1.hex -A $2

#objcopy --input-target=binary --output-target=ihex a.bin $1.hex
#cat $1.asm

