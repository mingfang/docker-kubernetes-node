#!/bin/bash

HOST_IP=`ip route get 1 | awk '{print $NF;exit}'`
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
let CPU=$CORES*1000

cat <<END | kubectl create -f -
{
  "kind": "Node",
  "apiVersion": "v1beta3",
  "metadata":{
    "name": "$HOST_IP"
  }
}
END
