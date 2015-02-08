#!/bin/bash

# Originally from https://gist.github.com/noteed/8656989#file-shared-docker-network-sh
# This article was the most useful I found on the topic http://translate.google.com/translate?hl=en&sl=zh-CN&tl=en&u=http%3A%2F%2Faresy.blog.51cto.com%2F5100031%2F1600956

echo "Make sure bridge-utils and openvswitch-switch are installed."
echo "apt-get update && apt-get install -y bridge-utils openvswitch-switch"
echo 

# Find the last octet of the IP address
HOST_IP=`ip route get 1 | awk '{print $NF;exit}'`
echo "HOST_IP=$HOST_IP"
LAST="${HOST_IP##*.}"
echo "LAST=$LAST"

# The subnet for all Docker containers on this host
if [ -z "$BRIDGE_ADDRESS" ]
then
  BRIDGE_ADDRESS=10.244.$LAST.1/24
fi
echo "BRIDGE_ADDRESS=$BRIDGE_ADDRESS"

# Name of the bridge (should match /etc/default/docker).
if [ -z "$DOCKER_BRIDGE" ]
then
  DOCKER_BRIDGE=kbr0
fi
echo "DOCKER_BRIDGE=$DOCKER_BRIDGE"

# Docker bridge

# Deactivate the DOCKER_BRIDGE bridge
ip link set $DOCKER_BRIDGE down
# Remove the DOCKER_BRIDGE bridge
brctl delbr $DOCKER_BRIDGE

# Add the DOCKER_BRIDGE bridge
brctl addbr $DOCKER_BRIDGE
# Set up the IP for the DOCKER_BRIDGE bridge
ip a add $BRIDGE_ADDRESS dev $DOCKER_BRIDGE
# Activate the bridge
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
ip route add 10.244.0.0/16 dev tep0 

# Add Remote End Point for GRE, need one for each host, will use etcd for this
if [ -z "$REMOTE_IP" ]
then
  echo "REMOTE_IP is not set. Will not create tunnel."
else
  echo "REMOTE_IP=$REMOTE_IP"
  # Create the tunnel to the other host and attach it to the
  # OVS_BRIDGE bridge
  ovs-vsctl add-port $OVS_BRIDGE gre0 -- set interface gre0 type=gre options:remote_ip=$REMOTE_IP
fi

#don't know what to do with iptable yet
# iptables rules

# Enable NAT
#iptables -t nat -A POSTROUTING -s 10.244.0.0/16 ! -d 10.244.0.0/16 -j MASQUERADE
# Accept incoming packets for existing connections
#iptables -A FORWARD -o $DOCKER_BRIDGE -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Accept all non-intercontainer outgoing packets
#iptables -A FORWARD -i $DOCKER_BRIDGE ! -o $DOCKER_BRIDGE -j ACCEPT
# By default allow all outgoing traffic
#iptables -A FORWARD -i $DOCKER_BRIDGE -o $DOCKER_BRIDGE -j ACCEPT

./ovs-show.sh

# Restart Docker daemon to use the new DOCKER_BRIDGE
echo -e "\nUse the OVS bridge by setting DOCKER_OPTS=\"--bridge=$DOCKER_BRIDGE --mtu=1420\" in file /etc/defaults/docker."
echo "Then restart Docker e.g. service docker restart"
