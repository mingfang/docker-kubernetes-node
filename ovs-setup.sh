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
BRIDGE_ADDRESS=172.27.$LAST.1/24

# Name of the bridge (should match /etc/default/docker).
DOCKER_BRIDGE=kbr0

echo "HOST_IP=$HOST_IP"
echo "LAST=$LAST"
echo "BRIDGE_ADDRESS=$BRIDGE_ADDRESS"
echo "DOCKER_BRIDGE=$DOCKER_BRIDGE"

# Docker bridge

# Deactivate the DOCKER_BRIDGE bridge
ip link set $DOCKER_BRIDGE down
brctl delbr $DOCKER_BRIDGE

# Add the DOCKER_BRIDGE bridge
brctl addbr $DOCKER_BRIDGE
ip a add $BRIDGE_ADDRESS dev $DOCKER_BRIDGE
ip link set $DOCKER_BRIDGE up

# OVS Bridge

OVS_BRIDGE=obr0
echo "OVS_BRIDGE=$OVS_BRIDGE"

# Delete the Open vSwitch bridge
ovs-vsctl del-br $OVS_BRIDGE
# Add the OVS_BRIDGE Open vSwitch bridge
ovs-vsctl add-br $OVS_BRIDGE
# Enable STP
ovs-vsctl set bridge $OVS_BRIDGE stp_enable=true
# Add the OVS_BRIDGE bridge to DOCKER_BRIDGE bridge
brctl addif $DOCKER_BRIDGE $OVS_BRIDGE

# Create GRE
ovs-vsctl add-port $OVS_BRIDGE tep0 -- set interface tep0 type=internal

# Tunnel End Point, connects to the host and MUST have IP to work
ip addr add 192.168.11.$LAST/24 dev tep0
ip link set dev tep0 up

# Enables routing to other hosts, critical
ip route add 172.27.0.0/16 dev tep0 

./ovs-show.sh

# Restart Docker daemon to use the new DOCKER_BRIDGE
echo -e "\nUse the OVS bridge by setting DOCKER_OPTS=\"--bridge=$DOCKER_BRIDGE --mtu=1420\" in file /etc/default/docker."
echo "
#/etc/systemd/system/docker.service
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --bridge=kbr0 --mtu=1420 --insecure-registry=0.0.0.0/0  --iptables=true --storage-driver=overlay
"
echo "Then restart Docker e.g. service docker restart or systemctl daemon-reload && systemctl start docker"
