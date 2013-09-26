#!/bin/bash

cd ../multiply
make
cd ../avdark-cache
#8388608
./pin-avdc.sh -s 262144 -l 64 -a 2 -o multiply.out -- ../multiply/multiply -v

