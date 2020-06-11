#!/bin/bash

if [ "A$1"  == "A" ];
then
docker run --name alpine-hadoop -d -t aktechthoughts/alpine-hadoop:1
else
docker exec alpine-linux \
      python $1
fi




