#!/bin/bash

echo "Make sure bridge-utils and openvswitch-switch are installed."
echo "apt-get update && apt-get install -y bridge-utils openvswitch-switch"
echo 

# Find the last octet of the IP address
HOST_IP=`ip route get 1 | awk '{print $NF;exit}'`
LAST="${HOST_IP##*.}"

# The subnet for all Docker containers on this host
BRIDGE_ADDRESS=10.244.$LAST.1/24

DOCKER_BRIDGE=kbr0
OVS_SWITCH=obr0
DOCKER_OVS_TUN=tun0
TUNNEL_BASE=gre

# create new docker bridge
ip link set dev ${DOCKER_BRIDGE} down || true
brctl delbr ${DOCKER_BRIDGE} || true
brctl addbr ${DOCKER_BRIDGE}
ip link set dev ${DOCKER_BRIDGE} up
#ifconfig ${DOCKER_BRIDGE} ${CONTAINER_ADDR} netmask ${CONTAINER_NETMASK} up
ip a add $BRIDGE_ADDRESS dev $DOCKER_BRIDGE

# add ovs bridge
ovs-vsctl del-br ${OVS_SWITCH} || true
ovs-vsctl add-br ${OVS_SWITCH} -- set Bridge ${OVS_SWITCH} fail-mode=secure
ovs-vsctl set bridge ${OVS_SWITCH} protocols=OpenFlow13
ovs-vsctl del-port ${OVS_SWITCH} ${TUNNEL_BASE}0 || true
ovs-vsctl add-port ${OVS_SWITCH} ${TUNNEL_BASE}0 -- set Interface ${TUNNEL_BASE}0 type=${TUNNEL_BASE} options:remote_ip="flow" options:key="flow" ofport_request=10

# add tun device
ovs-vsctl del-port ${OVS_SWITCH} ${DOCKER_OVS_TUN} || true
ovs-vsctl add-port ${OVS_SWITCH} ${DOCKER_OVS_TUN} -- set Interface ${DOCKER_OVS_TUN} type=internal ofport_request=9
brctl addif ${DOCKER_BRIDGE} ${DOCKER_OVS_TUN}
ip link set ${DOCKER_OVS_TUN} up

# add ip route rules such that all pod traffic flows through docker bridge and consequently to the gre tunnels
ip route add 10.244.0.0/16 dev ${DOCKER_BRIDGE} scope link src ${HOST_IP}

# add oflow rules, because we do not want to use stp
ovs-ofctl -O OpenFlow13 del-flows ${OVS_SWITCH}

# all flows are done with ovs-sync.sh

./ovs-show.sh
