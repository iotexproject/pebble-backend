#!/bin/bash

for i in `seq 1 50`;do
    nohup python3 ./run-dev.py -e localhost -p 1884 -id device/pebble-$i/data -pf data/sample.txt &
done
