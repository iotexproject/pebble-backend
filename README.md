# pebble-backend

![](backend_arch.png)

## Quick start.
### Prerequisites
####
```
sudo apt-get update
sudo apt install python3-pip
```

#### Install SDK for mqtt
```
pip3 install AWSIoTPythonSDK
```

#### startup
- start.sh   Start 50 clients to send messages to mqtt in the background.
- stop.sh    Stop all running clients.

## More explanation
run.py is a command to start a client, accepting parameters:
```
-e | --endpoint: Your AWS IoT custom endpoint
-r | --rootCA: Root CA file path
-c | --cert: Certificate file path
-k | --key: Private key file path
-p | --port: Port number override
-w | --websocket: Use MQTT over WebSocket
-id | --clientId: Targeted client id
-pb | --publish: Publish payload
-pf | --publish-file: Publish payload with file
```

run.p will send a message every 30 seconds

The message will be stored in the 'pebble-store' bucket in s3, like:
```
pebble-store/pebble-(1,2,3...50)/<timestamp>
```

## Install and configure thingsboard with gateway
The [Architecture](https://thingsboard.io/images/gateway/python-gateway-animd-ff.svg)
### Our data flow is
```
Device(SDK) --> aws iot --> s3
                       |
                       + --> thingsboard gateway --> thingsboard
```

### Prerequisites
- [Install Docker CE](https://docs.docker.com/engine/installation/)
- [Install Docker Compose](https://docs.docker.com/compose/install/)

### Start
Use the file configs/docker-compose/docker-compose.yml
docker-compose up -d

### Configure gateway
Login Thingsboard as tenant and create a gateway
Copy it's token
Set it to configs/tb-gateway/tb_gateway.yaml:
```
thingsboard.security.accessToken=<token>
```
Restart the thingsboard gateway
