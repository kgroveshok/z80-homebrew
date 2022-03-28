#!/bin/sh

cat a.bin  |hexdump -v -e '"x" 1/1 "%02X" " "'| sed 's/ /,/g'|sed 's/x/0x/g'

