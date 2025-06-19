#!/bin/bash

echo "Cross compile"
mkdir -p deploy/prod
mkdir -p deploy/debug
rm -v deploy/prod/*
rm -v deploy/debug/*
for f in core ; do

	echo $f
    # production code
    grep -v "print.*# STRIP" <src/$f.py >/dev/shm/$f.py
	mpy-cross /dev/shm/$f.py -o deploy/prod/$f.mpy
	
    # debug code
	mpy-cross src/$f.py -o deploy/debug/$f.mpy
done

#cp -v boot.py packaging/boot.upd2
cp -v src/main.py deploy/prod/main.py
cp -v src/main.py deploy/debug/main.py

# eof
