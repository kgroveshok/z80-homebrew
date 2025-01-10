#!/bin/bash

z80asm  -l $1.asm   --label=$1.sym

if [[ $? -eq 0 ]] ; then
./bin2hex.py -b a.bin -o $1.hex -A $2
fi
cp a.bin $1.bin


#objcopy --input-target=binary --output-target=ihex a.bin $1.hex
#cat $1.asm

