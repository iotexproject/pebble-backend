# pebble-backend

![](images/backend_arch.png)

## Quick Start
### Prerequisites
####

- [Install Docker CE](https://docs.docker.com/engine/installation/)
- [Install Docker Compose](https://docs.docker.com/compose/install/)

TIPS:

Add the 'ubuntu' user group to the 'docker' group, then command 'sudo' is not needed when running docker

/etc/group

```
docker:x:999:ubuntu
```


#### Install SDK for MQTT

```
sudo apt-get update
sudo apt install python3-pip
pip3 install AWSIoTPythonSDK
```

#### Config `git`
Config your `git` with correct SSH key to make sure `git clone` will work properly.

### Install and start backend service

```
./setup-dev.sh
./start-dev.sh
```

- Create Thingsboard Gateway
Login thingsboard UI, Default username/password: tenant@thingsboard.org/tenant
![](images/create-gateway-1.jpg)

![](images/create-gateway-2.jpg)

![](images/create-gateway-3.jpg)

![](images/create-gateway-4.jpg)

- Modify config of the gateway
```
sudo vim ~/pebble-var/conf/tb-gateway/conf/tb_gateway.yaml
```
Replace accessToken: xxxxxxxxxxxxx with the newly copied token 
```
thingsboard:
  host: thingsboard
  port: 1883
  security:
    accessToken: xxxxxxxxxxxxx
storage:
  type: memory
  read_records_count: 100
  max_records_count: 100000

connectors:
  - name: MQTT Broker Connector
    type: mqtt
    configuration: mqtt.json
```

- Restart the gateway service
```
docker restart docker-compose_thingsboard-gateway_1
```

### Start mock data
```
cd scripts
./mock-dev.sh
```

## Setup Thingsboard UI
### Import Dashboard
![](images/import-dashboard-1.jpg)

drop example/dashboard/pebble_1.json to the box
![](images/import-dashboard-2.jpg)

![](images/import-dashboard-3.jpg)

Modify
![](images/import-dashboard-4.jpg)

Set to pebble-1
![](images/import-dashboard-5.jpg)

### Import RULE CHAIN
![](images/import-rule-1.jpg)

drop example/thingsboard-rule/pebble.json to the box
![](images/import-rule-2.jpg)

Apply
![](images/import-rule-3.jpg)

Back to here and make it to the root
![](images/import-rule-4.jpg)


## Other tool description
### Mock tool
- scripts/mock.sh         Start 50 clients to send messages to mqtt in the background.
- scripts/stop-mock.sh    Stop all running clients.

#### Run With More Options
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

run.py will send a message every 30 seconds

The message will be stored in the 'pebble-store' bucket in s3, like:
```
pebble-store/pebble-(1,2,3...50)/<timestamp>
```

## Setup MQTT + Storage Backends
https://iotex.larksuite.com/docs/docuswsC2fyQNSH4fwdahKka5Rr#hbyvmo

## Integration with Thingsboard
[![](https://thingsboard.io/images/gateway/python-gateway-animd-ff.svg)](https://thingsboard.io/docs/iot-gateway/what-is-iot-gateway/)

### Our data flow is
```
Device(SDK) --> aws iot --> s3
                       |
                       + --> thingsboard gateway --> thingsboard
                                                         |
                                                         +--> iotex blockchain
```


### Start
Make directories for start thingsboard and thingsboard gateway
```
mkdir ~/{data,logs}
mkdir -p ~/conf/keys
mdkir -p ~/conf/tb-gateway/{conf,extensions,logs}
```

Use the file configs/docker-compose/docker-compose.yml
```
cd configs/docker-compose/
docker-compose up -d
```

### Configure gateway
Login Thingsboard as tenant and create a gateway

Copy it &lsquo;s token

Set it to configs/tb-gateway/tb_gateway.yaml:
```
thingsboard.security.accessToken=<token>
```

Restart the thingsboard gateway
```
cd configs/docker-compose/
docker-compose restart
```

(Optional)

After startup, some default configuration files will be generated

If you need to modify more, you can refer to the [official document](https://thingsboard.io/docs/iot-gateway/configuration/)

## Integration with IoTeX blockchain
In Thingsboard, we use "rule of thingsboard" to send messages to the blockchain.
As shown

![](images/rule.jpg)

- First, switch with "message type":

A message enters the chain from "input" and then into the node named "message type CommonData". If the "message type" is "Post Telemetry", it will be transmitted to the "Script FilterGateway" node. The "post telemetry" type includes device telemetry data.

![](images/messageType.jpg)

- Then, swicth with device type:

A message enters the "script FilterGateway" from "message type CommonData". If the "deviceType" is not "Gateway"(Because the data entering thingsboard comes through thingsboard gateway, there is data of type "Gateway", which needs to be filtered out), it will be transmitted to the "rest api call Push Blockchain" node. The "not Gateway" and the "post telemetry" are equivalent to all devices.

![](images/deviceType.jpg)

- Last, Push data to the blockchain:
A message enters the "rest api call Push Blockchain" from upstream. There are all of devices' post telemetries in the node.Then it will use the url to call the api server, and the variable "deviceType" is a metadata field. It comes from the configuration of Thingsboard Gateway.

![](images/apiCurl.jpg)

The Api server is a proxy for rpc-call the IOTEX server. Finally put the data on the blockchain.

The request:

```
HTTP 1.1 POST /api/v1/topic/{topic}/data
body is json containing device telemetry data
```

will be sent to a deployed contract address, and then executed by the contract to do more...
The important code is [iotexproject/pebble-data-container](https://github.com/iotexproject/pebble-data-container/blob/master/blockchain/put.go#L68)
