#!/bin/bash

# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

function main() {
    if [ ! -f ~/.pebble_docker_compose ];then
        echo -e "${RED} You must setup pebble first. ${NC}"
        exit 0
    fi

    checkDockerPermissions
    checkDockerCompose

    pushd $(dirname $(cat ~/.pebble_docker_compose))
    docker-compose up -d
    popd
}

main $@
