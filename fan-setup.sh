#!/bin/bash

echo "Make sure Fan Networking is installed."
echo "apt-get update && apt-get install -y ubuntu-fan"
echo 

# Find primary interface 
PRIMARY=`route|grep default|awk '{print $8}'`
UNDERLAY="${PRIMARY}/16"
OVERLAY="250.0.0.0/8"

# Name of the bridge (should match /etc/default/docker).
DOCKER_BRIDGE=kbr0

echo "PRIMARY=$PRIMARY"
echo "UNDERLAY=$UNDERLAY"
echo "OVERLAY=$OVERLAY"
echo "DOCKER_BRIDGE=$DOCKER_BRIDGE"

# Fan bridge
fanctl down -e
fanctl up -u $UNDERLAY -o $OVERLAY --bridge=$DOCKER_BRIDGE --dhcp
fanctl show

# Restart Docker daemon to use the new DOCKER_BRIDGE
echo -e "\nUse the Fan bridge by setting DOCKER_OPTS=\"--bridge=$DOCKER_BRIDGE --mtu=1480\" in file /etc/default/docker."
echo "
#/etc/systemd/system/docker.service
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --bridge=kbr0 --mtu=1480 --insecure-registry=0.0.0.0/0  --iptables=false --storage-driver=zfs
"
echo "Then restart Docker e.g. service docker restart or systemctl daemon-reload && systemctl start docker"
