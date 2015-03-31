#!/bin/bash

HOST_IP=`ip route get 1 | awk '{print $NF;exit}'`
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
let CPU=$CORES*1000

cat <<END | kubectl create -f -
{
  "id": "$HOST_IP",
  "kind": "Node",
  "apiVersion": "v1beta2",
  "resources": {
    "capacity": {
      "cpu": "$CPU",
      "memory": `free -b|grep Mem|awk '{print $2}'` 
    }
  },
  "labels": {
    "hostname": "`hostname`"
  },
  "externalId": "`hostname`"
}
END
