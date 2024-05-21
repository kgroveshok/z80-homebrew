#!/bin/sh

echo "Words List"
echo "------------------"
cat forth_words_*.asm | grep "|"  | cut -f2- -d'|'

echo "Words ready to use"
echo "------------------"
cat forth_words_*.asm | grep "|" | cut -f2- -d'|' | grep DONE

echo "Words still left to do"
echo "----------------------"
cat forth_words_*.asm | grep "|" | cut -f2- -d'|' | grep DONE -v

