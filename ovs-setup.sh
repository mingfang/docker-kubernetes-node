#!/bin/bash

# Originally from https://gist.github.com/noteed/8656989#file-shared-docker-network-sh
# This article was the most useful I found on the topic http://translate.google.com/translate?hl=en&sl=zh-CN&tl=en&u=http%3A%2F%2Faresy.blog.51cto.com%2F5100031%2F1600956

echo "Make sure bridge-utils and openvswitch-switch are installed."
echo "apt-get update && apt-get install -y bridge-utils openvswitch-switch"
echo 

# Find the last octet of the IP address
HOST_IP=`ip route get 1 | awk '{print $NF;exit}'`
LAST="${HOST_IP##*.}"

# The subnet for all Docker containers on this host
BRIDGE_ADDRESS=10.244.$LAST.1

# Name of the bridge (should match /etc/default/docker).
DOCKER_BRIDGE=kbr0

echo "HOST_IP=$HOST_IP"
echo "LAST=$LAST"
echo "BRIDGE_ADDRESS=$BRIDGE_ADDRESS"
echo "DOCKER_BRIDGE=$DOCKER_BRIDGE"

# Docker bridge

ip link set $DOCKER_BRIDGE down
brctl delbr $DOCKER_BRIDGE
brctl addbr $DOCKER_BRIDGE
ip addr add ${BRIDGE_ADDRESS}/24 dev $DOCKER_BRIDGE
ip link set $DOCKER_BRIDGE up

# OVS Bridge

OVS_BRIDGE=obr0
echo "OVS_BRIDGE=$OVS_BRIDGE"

ovs-vsctl del-br $OVS_BRIDGE
ovs-vsctl add-br $OVS_BRIDGE
ovs-vsctl set bridge $OVS_BRIDGE stp_enable=true
brctl addif $DOCKER_BRIDGE $OVS_BRIDGE
ip link set $OVS_BRIDGE up

# Enables routing to other hosts, critical
ip route add 10.244.0.0/16 dev $DOCKER_BRIDGE scope link src $BRIDGE_ADDRESS

./ovs-show.sh

# Restart Docker daemon to use the new DOCKER_BRIDGE
echo -e "\nUse the OVS bridge by setting DOCKER_OPTS=\"--bridge=$DOCKER_BRIDGE --mtu=1420\" in file /etc/default/docker."
echo "
#/etc/systemd/system/docker.service
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --bridge=kbr0 --mtu=1420 --insecure-registry=0.0.0.0/0  --iptables=true --storage-driver=zfs
"
echo "Then restart Docker e.g. service docker restart or systemctl daemon-reload && systemctl start docker"
