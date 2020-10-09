#!/bin/bash

echo 'Only start pebble-1'
nohup python3 ./run-dev.py -e localhost -p 1884 -id device/pebble-1/data -pf ../data/sample.txt &
