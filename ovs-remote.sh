#!/bin/bash

OVS_BRIDGE=obr0
echo "OVS_BRIDGE=$OVS_BRIDGE"

REMOTE_IP=$1
if [ -z "$REMOTE_IP" ]
then
  echo "REMOTE_IP is not set. Will not create tunnel."
else
  echo "REMOTE_IP=$REMOTE_IP"

  # Use last octet of remote to create gre port name
  GRE="gre${REMOTE_IP##*.}"
  echo "GRE=$GRE" 

  # Create the tunnel to the other host and attach it to the OVS_BRIDGE bridge
  ovs-vsctl add-port $OVS_BRIDGE $GRE -- set interface $GRE type=gre options:remote_ip=$REMOTE_IP

  CMD="ovs-vsctl show" && echo -e "\n$CMD" && eval $CMD
fi
