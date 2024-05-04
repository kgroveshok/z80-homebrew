#!/bin/sh

echo "Words List"
echo "------------------"
grep "|" <forth_wordsv4.asm   | cut -f2- -d'|'

echo "Words ready to use"
echo "------------------"
grep "|" <forth_wordsv4.asm   | cut -f2- -d'|' | grep DONE

echo "Words still left to do"
echo "----------------------"
grep "|" <forth_wordsv4.asm   | cut -f2- -d'|' | grep DONE -v

