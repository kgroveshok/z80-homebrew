#!/bin/sh

# Make OS versions for various hardware configs

./tohex.sh os_mini 0
./tohex.sh os_mega 0

./tohex.sh os_mini_sc114 8000
./tohex.sh os_mega_sc114 8000

# TODO fix up CPM
#./tohex.sh os_mini_cpm 100
./tohex.sh os_mega_cpm 100
