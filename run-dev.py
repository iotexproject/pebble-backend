#!/usr/bin/env python3

from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient
import logging
import time
import json
import argparse

# Read in command-line parameters
parser = argparse.ArgumentParser()
parser.add_argument("-e", "--endpoint", action="store", required=True, dest="host", help="Your AWS IoT custom endpoint")
parser.add_argument("-p", "--port", action="store", dest="port", type=int, help="Port number override")
parser.add_argument("-id", "--clientId", action="store", dest="clientId",
                    help="Targeted client id")
parser.add_argument("-pb", "--publish", action="store", dest="publish",
                    help="Publish payload")
parser.add_argument("-pf", "--publish-file", action="store", dest="publishFile",
                    help="Publish payload")

args = parser.parse_args()
host = args.host
port = args.port
clientId = args.clientId
publish = args.publish
publishFile = args.publishFile

if not args.clientId:
    parser.error("clientId is required.")
    exit(2)

# Configure logging
#logger = logging.getLogger("AWSIoTPythonSDK.core")
#logger.setLevel(logging.DEBUG)
#streamHandler = logging.StreamHandler()
#formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
#streamHandler.setFormatter(formatter)
#logger.addHandler(streamHandler)

# Init AWSIoTMQTTShadowClient
myMQTTClient = AWSIoTMQTTClient(clientId)
myMQTTClient.configureEndpoint(host, port)

# AWSIoTMQTTShadowClient configuration
myMQTTClient.configureOfflinePublishQueueing(-1)
myMQTTClient.configureDrainingFrequency(2)
myMQTTClient.configureConnectDisconnectTimeout(10)  # 10 sec
myMQTTClient.configureMQTTOperationTimeout(5)  # 5 sec

# Connect to AWS IoT
myMQTTClient.connect()
time.sleep(2)

publish = args.publish
publishFile = args.publishFile
# Publish payload to mqtt.
while True:
    if args.publish:
        myMQTTClient.publish(clientId, publish, 0)
    elif args.publishFile:
        with open(publishFile, 'r') as f:
            for line in f.readlines():
                myMQTTClient.publish(clientId, line, 0)
                time.sleep(30)
    else:
        parser.error("Publish data is missing. Must be provided with -pb or -pf")
        exit(2)
        
    time.sleep(30)
