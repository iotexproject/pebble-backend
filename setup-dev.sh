#!/bin/bash
#
# Images
#     - thingsboard thingsboard/tb-postgres - official
#     - thingsboard-gateway thingsboard/tb-gateway - official
#     - api-server iotex-blockchain-data - build self
#     - minio minio/minio - official
#     - hmq iotex-hmq:local - build self
#
# Mounted dir
#     - thingsboard - data log
#     - thingsboard-gateway - config extensions keys
#     - hmq - config plugin
#
# Prepared data
#     - thingsboard-gateway certificate - in the keys dir
#     - api-server IO_ENDPOINT CONTRACT_ADDRESS VAULT_ADDRESS VAULT_PASSWORD - in the apiEnv file
#     - minio MINIO_ACCESS_KEY MINIO_SECRET_KEY - in the docker-compose.yml
#     - hmq MINIO_ACCESS_KEY MINIO_SECRET_KEY - plugin config file, Keep the same value as above
#
# Configs
#     - thingsboard-gateway tb_gateway mqtt
#     - api-server apiEnv
#     - hmq config minio
#
# This script is used to setup all servers in one host for develop.
# Usage:
#    ./setup.sh                     - setup the develop env 
#    ./setup.sh -c                  - Clean the environmen
#    ./setup.sh -q                  - quick setup, skip the pull and build stage.

# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

WHITE_LINE="echo"

SKIP_PULL_BUILD_IMAGE=0
WANT_CLEAN=0

function usage () {
    echo ' Usage:
    ./setup.sh                     - setup the develop env 
    ./setup.sh -c                  - Clean the environmen
    ./setup.sh -q                  - quick setup, skip the pull stage.
'
    exit 2
}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function checkDockerPermissions() {
    docker ps > /dev/null
    if [ $? = 1 ];then
        echo -e "your $RED [$USER] $NC not privilege docker" 
        echo -e "please run $RED [sudo bash] $NC first"
        echo -e "Or docker not install "
        exit 1
    fi
}

function checkDockerCompose() {
    docker-compose --version > /dev/null 2>&1
    if [ $? -eq 127 ];then
        echo -e "$RED docker-compose command not found $NC"
        echo -e "Please install it first"
        exit 1
    fi
}

function setImagesVar4Official() {
    IMGAE_THINGSBOARD=thingsboard/tb-postgres:latest
    IMAGE_THINGSBOARD_GATEWAY=thingsboard/tb-gateway:latest
    IMAGE_MINIO=minio/minio:latest
}

function setImagesVar4Build() {
    IMAGE_BLOCKCHAIN_DATA=iotex-blockchain-data:local
    IMAGE_HMQ=iotex-hmq:local
}

function setVar() {
    # Some useful directories
    if [ ! $PEBBLE_VAR ];then
        PEBBLE_VAR="$HOME/pebble-var"
    fi
    
    PROJECT_ABS_DIR=$(cd "$(dirname "$0")";pwd)

    DOCKER_COMPOSE_DIR=$PEBBLE_VAR/docker-compose

    PEBBLE_VAR_CONF_DIR=$PEBBLE_VAR/conf

    PEBBLE_VAR_CONF_TB_GATEWAY_DIR=$PEBBLE_VAR_CONF_DIR/tb-gateway
    PEBBLE_VAR_CONF_TB_GATEWAY_CONF_DIR=$PEBBLE_VAR_CONF_TB_GATEWAY_DIR/conf
    PEBBLE_VAR_CONF_TB_GATEWAY_EXTENSIONS_DIR=$PEBBLE_VAR_CONF_TB_GATEWAY_DIR/extensions
    PEBBLE_VAR_CONF_TB_GATEWAY_LOGS_DIR=$PEBBLE_VAR_CONF_TB_GATEWAY_DIR/logs
    PEBBLE_VAR_CONF_TB_GATEWAY_KEYS_DIR=$PEBBLE_VAR_CONF_TB_GATEWAY_DIR/keys

    PEBBLE_VAR_CONF_API_SERVER_DIR=$PEBBLE_VAR_CONF_DIR/api-server
    
    PEBBLE_VAR_CONF_HMQ_DIR=$PEBBLE_VAR_CONF_DIR/hmq
    PEBBLE_VAR_CONF_HMQ_MINIO_DIR=$PEBBLE_VAR_CONF_HMQ_DIR/minio
    
    PEBBLE_VAR_DATA_DIR=$PEBBLE_VAR/data
    PEBBLE_VAR_LOGS_DIR=$PEBBLE_VAR/logs
    PEBBLE_VAR_CODE_DIR=$PEBBLE_VAR/code

    # Code var and directories
    PEBBLE_API_SERVER_CODE_URL=https://github.com/iotexproject/pebble-data-container.git
    PEBBLE_API_SERVER_CODE_BRANCH=master
    PEBBLE_API_SERVER_CODE=$PEBBLE_VAR_CODE_DIR/pebble-data-container
    PEBBLE_HMQ_CODE_URL=https://github.com/iotexproject/hmq.git
    PEBBLE_HMQ_CODE_BRANCH=add-plugin-minio
    PEBBLE_HMQ_CODE=$PEBBLE_VAR_CODE_DIR/hmq

    # Some commands
    MKDIR="mkdir -p"
    COPY="cp -vf"
    SUCOPY="sudo cp -vf"
    RM="sudo rm -rf"
    CHOWN="sudo chown -R 799:799"
    DOCKER_PULL_CMD="docker pull"
    DOCKER_BUILD_CMD="docker build . -t"
    DOCKER_COMPOSE_CMD="docker-compose"
    FETCH_CODE_CMD="git clone"
    CHECKOUT_CODE_BRANCH="git checkout"

    # Image names
    setImagesVar4Official
    setImagesVar4Build
}

function makeServerDir() {
    $MKDIR $PEBBLE_VAR \
           $DOCKER_COMPOSE_DIR \
           $PEBBLE_VAR_CONF_DIR \
           $PEBBLE_VAR_CONF_TB_GATEWAY_DIR \
           $PEBBLE_VAR_CONF_TB_GATEWAY_CONF_DIR \
           $PEBBLE_VAR_CONF_TB_GATEWAY_EXTENSIONS_DIR \
           $PEBBLE_VAR_CONF_TB_GATEWAY_LOGS_DIR \
           $PEBBLE_VAR_CONF_TB_GATEWAY_KEYS_DIR \
           $PEBBLE_VAR_CONF_API_SERVER_DIR \
           $PEBBLE_VAR_CONF_HMQ_DIR \
           $PEBBLE_VAR_CONF_HMQ_MINIO_DIR \
           $PEBBLE_VAR_DATA_DIR \
           $PEBBLE_VAR_LOGS_DIR \
           $PEBBLE_VAR_CODE_DIR
}

function pullCodes() {
    pushd $PEBBLE_VAR_CODE_DIR
    # fecth api server code
    $FETCH_CODE_CMD $PEBBLE_API_SERVER_CODE_URL $PEBBLE_API_SERVER_CODE
    pushd $PEBBLE_API_SERVER_CODE
    $CHECKOUT_CODE_BRANCH $PEBBLE_API_SERVER_CODE_BRANCH
    popd

    # fetch hmq code
    $FETCH_CODE_CMD $PEBBLE_HMQ_CODE_URL $PEBBLE_HMQ_CODE
    pushd $PEBBLE_HMQ_CODE
    $CHECKOUT_CODE_BRANCH $PEBBLE_HMQ_CODE_BRANCH
    popd
    popd
}

function pullImages() {
    $DOCKER_PULL_CMD $IMGAE_THINGSBOARD
    $DOCKER_PULL_CMD $IMAGE_THINGSBOARD_GATEWAY
    $DOCKER_PULL_CMD $IMAGE_MINIO
}

function buildImages() {
    # Build api server
    pushd $PEBBLE_API_SERVER_CODE
    $DOCKER_BUILD_CMD $IMAGE_BLOCKCHAIN_DATA
    popd

    # Build hmq server
    pushd $PEBBLE_HMQ_CODE
    $DOCKER_BUILD_CMD $IMAGE_HMQ
    popd
}

function copyConfig() {
    echo -e "$YELLOW Copy the configure files... $NC"

    # Copy docker-compose
    $COPY $PROJECT_ABS_DIR/configs/docker-compose/docker-compose-dev.yml $DOCKER_COMPOSE_DIR/docker-compose.yml

    # Copy apiEnv
    $COPY $PROJECT_ABS_DIR/configs/docker-compose/apiEnv-dev $PEBBLE_VAR_CONF_API_SERVER_DIR/apiEnv

    # Cpoy Hmq
    $COPY $PROJECT_ABS_DIR/configs/conf/hmq/config.json $PEBBLE_VAR_CONF_HMQ_DIR/config.json
    $COPY $PROJECT_ABS_DIR/configs/conf/hmq/minio/minio.json $PEBBLE_VAR_CONF_HMQ_MINIO_DIR/minio.json
    echo -e "$YELLOW Copy done. $NC"

    $WHITE_LINE
}

function overTBGDefault() {
    # Copy thingsboard gateway
    $SUCOPY $PROJECT_ABS_DIR/configs/conf/tb-gateway/tb_gateway.yaml $PEBBLE_VAR_CONF_TB_GATEWAY_CONF_DIR/tb_gateway.yaml
    $SUCOPY $PROJECT_ABS_DIR/configs/conf/tb-gateway/mqtt-dev.json $PEBBLE_VAR_CONF_TB_GATEWAY_CONF_DIR/mqtt.json

}

function exportAll() {
    export PEBBLE_VAR \
           PEBBLE_VAR_CONF_DIR \
           IMGAE_THINGSBOARD \
           IMAGE_THINGSBOARD_GATEWAY \
           IMAGE_MINIO \
           IMAGE_BLOCKCHAIN_DATA \
           IMAGE_HMQ \
           PEBBLE_VAR_DATA_DIR \
           PEBBLE_VAR_LOGS_DIR \
           PEBBLE_VAR_CONF_TB_GATEWAY_DIR \
           PEBBLE_VAR_CONF_TB_GATEWAY_CONF_DIR \
           PEBBLE_VAR_CONF_TB_GATEWAY_EXTENSIONS_DIR \
           PEBBLE_VAR_CONF_TB_GATEWAY_LOGS_DIR \
           PEBBLE_VAR_CONF_TB_GATEWAY_KEYS_DIR \
           PEBBLE_VAR_CONF_API_SERVER_DIR\
           PEBBLE_VAR_CONF_HMQ_DIR \
           PEBBLE_VAR_CONF_HMQ_MINIO_DIR
}

function makeEnvFile() {
    sudo echo "PEBBLE_VAR=$HOME/pebble-var
PEBBLE_VAR_CONF_DIR=$PEBBLE_VAR/conf

IMGAE_THINGSBOARD=thingsboard/tb-postgres:latest
IMAGE_THINGSBOARD_GATEWAY=thingsboard/tb-gateway:latest
IMAGE_MINIO=minio/minio:latest

IMAGE_BLOCKCHAIN_DATA=iotex-blockchain-data:local
IMAGE_HMQ=iotex-hmq:local

PEBBLE_VAR_DATA_DIR=$PEBBLE_VAR/data
PEBBLE_VAR_LOGS_DIR=$PEBBLE_VAR/logs

PEBBLE_VAR_CONF_TB_GATEWAY_DIR=$PEBBLE_VAR_CONF_DIR/tb-gateway
PEBBLE_VAR_CONF_TB_GATEWAY_CONF_DIR=$PEBBLE_VAR_CONF_TB_GATEWAY_DIR/conf
PEBBLE_VAR_CONF_TB_GATEWAY_EXTENSIONS_DIR=$PEBBLE_VAR_CONF_TB_GATEWAY_DIR/extensions
PEBBLE_VAR_CONF_TB_GATEWAY_LOGS_DIR=$PEBBLE_VAR_CONF_TB_GATEWAY_DIR/logs
PEBBLE_VAR_CONF_TB_GATEWAY_KEYS_DIR=$PEBBLE_VAR_CONF_TB_GATEWAY_DIR/keys

PEBBLE_VAR_CONF_API_SERVER_DIR=$PEBBLE_VAR_CONF_DIR/api-server

PEBBLE_VAR_CONF_HMQ_DIR=$PEBBLE_VAR_CONF_DIR/hmq
PEBBLE_VAR_CONF_HMQ_MINIO_DIR=$PEBBLE_VAR_CONF_HMQ_DIR/minio
" > $DOCKER_COMPOSE_DIR/.env
}

function cleanAll() {
    echo -e "$YELLOW Starting clean all containers... $NC"
    pushd $DOCKER_COMPOSE_DIR
    docker-compose rm -s -f -v
    popd
    echo -e "${YELLOW} Done. ${NC}"

    echo -e "${YELLOW} Starting delete all files... ${NC}"
    if [ "${PEBBLE_VAR}X" = "X" ] || [ "${PEBBLE_VAR}X" = "/X" ];then
        echo -e "${RED} \$PEBBLE_VAR: ${PEBBLE_VAR} is wrong. ${NC}"
        ## For safe.
        exit 1
    fi
    
    $RM $PEBBLE_VAR
    echo -e "${YELLOW} Done. ${NC}"
}

function main() {
    while getopts 'cqh' c
    do
        case $c in
            c)
                WANT_CLEAN=1 ;;
            q)
                SKIP_PULL_BUILD_IMAGE=1 ;;
            h|*)
                usage ;;
        esac
    done

    checkDockerPermissions
    checkDockerCompose

    setVar

    if [ $WANT_CLEAN -eq 1 ];then
        if [ -d $PEBBLE_VAR ];then
            cleanAll
        else
            echo -e "${RED} There is no dir $PEBBLE_VAR, ignore deletion and exit ${NC}"
        fi
        exit 0
    fi
    
    makeServerDir

    if [ $SKIP_PULL_BUILD_IMAGE -eq 0 ];then
        pullImages || exit 2
        pullCodes || exit 2
        buildImages || exit 2
    fi

    copyConfig || exit 2
    makeEnvFile || exit 2
    exportAll
    
    $CHOWN $PEBBLE_VAR

    echo "$DOCKER_COMPOSE_DIR/.env" > ~/.pebble_docker_compose

    # start thingsboard, it will make some default configs
    echo -e "${YELLOW} Now start the service just to let ${NC}"
    echo -e "${YELLOW} thingsboard-gateway generate the default configurations ${NC}"
    echo -e "${YELLOW} file, and then overwrite them with our configurations ${NC}"
    echo -e "${YELLOW} it need about 20s ${NC}"
    pushd $DOCKER_COMPOSE_DIR
    docker-compose up -d thingsboard-gateway
    echo -e "${YELLOW} Starting...${NC}"
    sleep 20
    echo -e "${YELLOW} Stop... ${NC}"
    docker-compose stop
    docker rm docker-compose_thingsboard-gateway_1
    popd

    echo -e "${YELLOW} Overwrite the default configurations ${NC}"
    overTBGDefault || exit 2
    echo -e "${YELLOW} Done. ${NC}"
    $CHOWN $PEBBLE_VAR
}

main $@
echo -e "${YELLOW} After the first startup, you need to create ${NC}"
echo -e "${YELLOW} a gateway in the device chapter of thingsboard, ${NC}"
echo -e "${YELLOW} and then use the token configuration of this ${NC}"
echo -e "${YELLOW} gateway to modify the ${NC}"
echo -e "${RED} thingsboard.security.accessToken ${NC}"
echo -e "${YELLOW} in the configuration file ${NC}"
echo -e "${RED} $PEBBLE_VAR_CONF_TB_GATEWAY_CONF_DIR/tb_gateway.yaml, ${NC}"
echo -e "${YELLOW} Compile the deployment contract and complete ${NC}"
echo -e "${RED} $PEBBLE_VAR_CONF_API_SERVER_DIR/apiEnv ${NC}"
echo -e "${YELLOW} and then restart the service. ${NC}"
