#!/bin/sh

cd os
./wordlist.sh | sed 's/$/\n\n/g'| sed 's/^ /* /g' | sed 's/^* |//g' >../WORD-LIST.md

