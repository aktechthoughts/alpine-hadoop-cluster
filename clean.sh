#!/bin/bash

docker rmi $(docker images -f "dangling=true" -q) -f > /dev/null 2&>1
docker rm $(docker ps -a -f status=exited -q) -f > /dev/null 2&>1
