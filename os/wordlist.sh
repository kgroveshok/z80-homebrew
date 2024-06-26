#!/bin/sh

echo "# Forth Language Reference"
echo
cat forth_words_*.asm | grep "|"  | cut -f2- -d'|'| sed 's/^ /* /g' | sed 's/^* |//g' 

echo "# Words Ready To Use"
echo
cat forth_words_*.asm | grep -v "; | | " | grep "|" | cut -f2- -d'|' | grep DONE | sed 's/^ /* /g' | sed 's/^* |//g' 

echo "# Words Still Left To Do"
echo
cat forth_words_*.asm | grep -v "; | | " | grep "|" | cut -f2- -d'|' | grep DONE -v | sed 's/^ /* /g' | sed 's/^* |//g' 

