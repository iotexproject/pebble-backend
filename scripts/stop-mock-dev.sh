#!/bin/bash

kill `ps -ef|grep './run-dev.py' | grep -v grep | awk '{print $2}'`
