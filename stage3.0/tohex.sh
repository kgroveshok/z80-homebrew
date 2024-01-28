
z80asm -l $1.asm 
objcopy --input-target=binary --output-target=ihex a.bin $1.hex
cat $1.asm

