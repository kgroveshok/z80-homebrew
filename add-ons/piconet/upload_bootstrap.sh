#!/bin/sh


rshell --buffer-size=30 -p /dev/ttyACM0  -a "cp deploy/prod/* /pyboard"



