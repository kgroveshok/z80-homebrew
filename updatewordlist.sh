#!/bin/sh

cd os
./wordlist.sh | sed 's/$/\n\n/g'>../WORD-LIST.md

