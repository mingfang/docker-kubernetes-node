# Originally from https://gist.github.com/noteed/8656989#file-shared-docker-network-sh

echo "Make sure bridge-utils and openvswitch-switch are installed."
echo "apt-get update && apt-get install -y bridge-utils openvswitch-switch"
echo 

# Edit this variable: the bridge address on 'this' host.
if [ -z "$BRIDGE_ADDRESS" ]
then
  BRIDGE_ADDRESS=10.244.1.1/16
fi
echo "BRIDGE_ADDRESS=$BRIDGE_ADDRESS"

# Name of the bridge (should match /etc/default/docker).
if [ -z "$DOCKER_BRIDGE" ]
then
  DOCKER_BRIDGE=kbr0
fi
echo "DOCKER_BRIDGE=$DOCKER_BRIDGE"

# bridges

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

# Edit this variable: the 'other' host.
#REMOTE_IP=188.226.138.185
if [ -z "$REMOTE_IP" ]
then
  echo "REMOTE_IP is not set. Will not create tunnel."
else
  echo "REMOTE_IP=$REMOTE_IP"
  # Create the tunnel to the other host and attach it to the
  # OVS_BRIDGE bridge
  ovs-vsctl add-port $OVS_BRIDGE gre0 -- set interface gre0 type=gre options:remote_ip=$REMOTE_IP
fi


# iptables rules

# Enable NAT
iptables -t nat -A POSTROUTING -s 10.244.0.0/16 ! -d 10.244.0.0/16 -j MASQUERADE
# Accept incoming packets for existing connections
iptables -A FORWARD -o $DOCKER_BRIDGE -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Accept all non-intercontainer outgoing packets
iptables -A FORWARD -i $DOCKER_BRIDGE ! -o $DOCKER_BRIDGE -j ACCEPT
# By default allow all outgoing traffic
iptables -A FORWARD -i $DOCKER_BRIDGE -o $DOCKER_BRIDGE -j ACCEPT

# Show bridges
CMD="ip r s" && echo -e "\n$CMD" && eval $CMD
CMD="route -n" && echo -e "\n$CMD" && eval $CMD
CMD="brctl show" && echo -e "\n$CMD" && eval $CMD
CMD="ovs-vsctl show" && echo -e "\n$CMD" && eval $CMD

# Restart Docker daemon to use the new DOCKER_BRIDGE
echo -e "\nUse the OVS bridge by setting DOCKER_OPTS=\"--bridge=$DOCKER_BRIDGE\" in file /etc/defaults/docker."
echo "Then restart Docker e.g. service docker restart"
