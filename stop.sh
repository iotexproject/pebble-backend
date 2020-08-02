#!/bin/bash

kill `ps -ef|grep './run.py' | grep -v grep`
