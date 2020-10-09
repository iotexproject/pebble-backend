#!/bin/bash

for i in `seq 1 50`;do
    nohup python3 ./run.py -e a11homvea4zo8t-ats.iot.us-east-1.amazonaws.com -p 443 -r ${PWD}/../keys/AmazonRootCA1.pem -c ${PWD}/../keys/efa1728ea8-certificate.pem.crt -k ${PWD}/../keys/efa1728ea8-private.pem.key -id device/pebble-$i/data -pf ../data/sample.txt &
done
