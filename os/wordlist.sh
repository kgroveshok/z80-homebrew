#!/bin/sh

echo "# Forth Language Reference"
echo
echo "Also refer to the auto start list examples as these contain extra words created at runtime as needed"
cat forth_words_*.asm | grep "|"  | cut -f2- -d'|'

echo "# Words Ready To Use"
echo
cat forth_words_*.asm | grep -v "; | | " | grep "|" | cut -f2- -d'|' | grep DONE 

echo "# Words Still Left To Do"
echo
cat forth_words_*.asm | grep -v "; | | " | grep "|" | cut -f2- -d'|' | grep DONE -v

