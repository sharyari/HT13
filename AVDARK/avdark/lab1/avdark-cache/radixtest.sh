#!/bin/bash


s=([1]=16384 [2]=32768 [3]=65536)
b=([1]=16 [2]=32 [3]=64)

for i in `seq 1 2`;
do
	for j in `seq 1 3`;
	do
		for k in `seq 1 3`;
		do
			echo "Size: " ${s[$j]} "   BlockSize:" ${b[$k]}
			./pin-avdc.sh -s ${s[$j]} -l ${b[$k]} -a ${i} -o radixdata/ra${s[$j]}.${b[$k]}.$i.out -- ../radix/radix -n 100000
		done
	done
done
