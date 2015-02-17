#!/bin/bash

OVS_BRIDGE=obr0
echo "OVS_BRIDGE=$OVS_BRIDGE"

REMOTE_IP=$2
if [ -z "$REMOTE_IP" ]
then
  echo "REMOTE_IP is not set."
else
  echo "REMOTE_IP=$REMOTE_IP"

  # Use last octet of remote to create gre port name
  GRE="gre${REMOTE_IP##*.}"
  echo "GRE=$GRE" 

  if [ "add" = "$1" ]
  then
    # Create the tunnel to the other host and attach it to the OVS_BRIDGE bridge
    CMD="ovs-vsctl add-port $OVS_BRIDGE $GRE -- set interface $GRE type=gre options:remote_ip=$REMOTE_IP" && echo -e "\n$CMD" && eval $CMD
  fi

  if [ "del" = "$1" ]
  then
    # Delete port
    CMD="ovs-vsctl del-port $OVS_BRIDGE $GRE" && echo -e "\n$CMD" && eval $CMD
  fi

  CMD="ovs-vsctl show" && echo -e "\n$CMD" && eval $CMD
fi
