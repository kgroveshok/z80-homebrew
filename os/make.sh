#!/bin/bash


# generate assemble timestamp for rom

now=$(date "+%F %H:%M")
echo "db '$now'" >romtimestamp.asm

# Make OS versions for various hardware configs

#./tohex.sh os_mini 0
./tohex.sh os_mega 0

#./tohex.sh os_mini_sc114 8000
./tohex.sh os_mega_sc114 8000

# TODO fix up CPM
#./tohex.sh os_mini_cpm 100
./tohex.sh os_mega_cpm 100

cp os_mega_cpm-dl0.bin OS0.COM
cp os_mega_cpm-dl1.bin OS1.COM
cp os_mega_cpm-dl2.bin OS2.COM
cp OS0.COM ../../../Retro-Projects/RunCPM/go/A/0/
cp OS1.COM ../../../Retro-Projects/RunCPM/go/A/0/
cp OS2.COM ../../../Retro-Projects/RunCPM/go/A/0/
cp os_mega-dl0.hex ~/Desktop
cp os_mega-dl1.hex ~/Desktop
cp os_mega-dl2.hex ~/Desktop
