#!/bin/bash

OVS_SWITCH=obr0
echo "OVS_SWITCH=$OVS_SWITCH"

REMOTE_IP=$2
echo "REMOTE_IP=$REMOTE_IP"

if [ -z "$REMOTE_IP" ]
then
  echo "REMOTE_IP is not set."
  exit
fi

# Prevent adding own IP
HOST_IP=`ip route get 1 | awk '{print $NF;exit}'`
if [ $HOST_IP = $REMOTE_IP ]
then
  echo "REMOTE_IP can not be same as HOST_IP($HOST_IP)"
  exit
fi

# Use last octet of remote to create gre port name
GRE="10.244.${REMOTE_IP##*.}.0/24"
echo "GRE=$GRE" 

# cookie
COOKIE=${REMOTE_IP//./}

if [ "add" = "$1" ]
then
  # Create the tunnel to the other host and attach it to the OVS_SWITCH bridge
  ovs-ofctl -O OpenFlow13 add-flow ${OVS_SWITCH} "cookie=$COOKIE,table=0,in_port=9,ip,nw_dst=${GRE},actions=set_field:${REMOTE_IP}->tun_dst,output:10"
  ovs-ofctl -O OpenFlow13 add-flow ${OVS_SWITCH} "cookie=$COOKIE,table=0,in_port=9,arp,nw_dst=${GRE},actions=set_field:${REMOTE_IP}->tun_dst,output:10"
fi

if [ "del" = "$1" ]
then
  # Delete flow using cookie, note wierd /-1 syntax
  ovs-ofctl -O OpenFlow13 del-flows ${OVS_SWITCH} cookie=${COOKIE}/-1
fi

CMD="ovs-ofctl -O OpenFlow13 dump-ports-desc obr0" && echo -e "\n$CMD" && eval $CMD
CMD="ovs-ofctl -O OpenFlow13 dump-flows obr0" && echo -e "\n$CMD" && eval $CMD

