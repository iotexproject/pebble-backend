#!/usr/bin/env python3

from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient
import logging
import time
import json
import argparse

# Read in command-line parameters
parser = argparse.ArgumentParser()
parser.add_argument("-e", "--endpoint", action="store", required=True, dest="host", help="Your AWS IoT custom endpoint")
parser.add_argument("-r", "--rootCA", action="store", required=True, dest="rootCAPath", help="Root CA file path")
parser.add_argument("-c", "--cert", action="store", dest="certificatePath", help="Certificate file path")
parser.add_argument("-k", "--key", action="store", dest="privateKeyPath", help="Private key file path")
parser.add_argument("-p", "--port", action="store", dest="port", type=int, help="Port number override")
parser.add_argument("-w", "--websocket", action="store_true", dest="useWebsocket", default=False,
                    help="Use MQTT over WebSocket")
parser.add_argument("-id", "--clientId", action="store", dest="clientId",
                    help="Targeted client id")
parser.add_argument("-pb", "--publish", action="store", dest="publish",
                    help="Publish payload")
parser.add_argument("-pf", "--publish-file", action="store", dest="publishFile",
                    help="Publish payload")

args = parser.parse_args()
host = args.host
rootCAPath = args.rootCAPath
certificatePath = args.certificatePath
privateKeyPath = args.privateKeyPath
port = args.port
useWebsocket = args.useWebsocket
clientId = args.clientId
publish = args.publish
publishFile = args.publishFile

if not args.clientId:
    parser.error("clientId is required.")
    exit(2)

if args.useWebsocket and args.certificatePath and args.privateKeyPath:
    parser.error("X.509 cert authentication and WebSocket are mutual exclusive. Please pick one.")
    exit(2)

if not args.useWebsocket and (not args.certificatePath or not args.privateKeyPath):
    parser.error("Missing credentials for authentication.")
    exit(2)

# Port defaults
if args.useWebsocket and not args.port:  # When no port override for WebSocket, default to 443
    port = 443
if not args.useWebsocket and not args.port:  # When no port override for non-WebSocket, default to 8883
    port = 8883

# Configure logging
#logger = logging.getLogger("AWSIoTPythonSDK.core")
#logger.setLevel(logging.DEBUG)
#streamHandler = logging.StreamHandler()
#formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
#streamHandler.setFormatter(formatter)
#logger.addHandler(streamHandler)

# Init AWSIoTMQTTShadowClient
myMQTTClient = None
if useWebsocket:
    myMQTTClient = AWSIoTMQTTClient(clientId, useWebsocket=True)
    myMQTTClient.configureEndpoint(host, port)
    myMQTTClient.configureCredentials(rootCAPath)
else:
    myMQTTClient = AWSIoTMQTTClient(clientId)
    myMQTTClient.configureEndpoint(host, port)
    myMQTTClient.configureCredentials(rootCAPath, privateKeyPath, certificatePath)

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
