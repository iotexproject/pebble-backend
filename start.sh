#!/bin/bash

for i in `seq 1 50`;do
    nohup python3 ./run.py -e a11homvea4zo8t-ats.iot.us-east-1.amazonaws.com -p 443 -r ${PWD}/keys/AmazonRootCA1.pem -c ${PWD}/keys/efa1728ea8-certificate.pem.crt -k ${PWD}/keys/efa1728ea8-private.pem.key -id pebble-$i -pb '{"message":{"SNR":2,"VBAT":4.0750732421875,"latitude":3050.69225,"longitude":11448.65815,"gas_resistance":1166811,"temperature":36.23188400268555,"pressure":1003.82000732421885,"humidity":55.755001068115234,"gyroscope":[-12,11,14],"accelerometer":[-711,-231,8260],"timestamp":"3443547577"},"signature":"D7797968EAA3FFE5F8057C9D97F707A4A96CBFC250115FE6293EBA5E90327174643A8CB823110376A5D30201463CF69CDF8CBF1C050EB85B023CABFB589C3222"}' &
done
