#!/bin/bash

HOST_IP=`ip route get 1 | awk '{print $NF;exit}'`
cat <<END | kubectl create -f -
{
  "id": "$HOST_IP",
  "kind": "Minion",
  "apiVersion": "v1beta2",
  "resources": {
    "capacity": {
      "cpu": "1000",
      "memory": 1073741824
    }
  }
}
END
