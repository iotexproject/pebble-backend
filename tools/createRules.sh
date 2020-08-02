#!/bin/bash

for i in `seq 1 50`;do sed "s/_ID_/$i/" templates/rule_template.json > current.json;aws iot create-topic-rule --rule-name pebble_$i --topic-rule-payload file://current.json;done
