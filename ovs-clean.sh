# Name of the bridge (should match /etc/default/docker).
if [ -z "$DOCKER_BRIDGE" ]
then
  DOCKER_BRIDGE=kbr0
fi

# bridges

# Deactivate the DOCKER_BRIDGE bridge
ip link set $DOCKER_BRIDGE down
# Remove the DOCKER_BRIDGE bridge
brctl delbr $DOCKER_BRIDGE

OVS_BRIDGE=obr0
echo "OVS_BRIDGE=$OVS_BRIDGE"

# Delete the Open vSwitch bridge
ovs-vsctl del-br $OVS_BRIDGE

ip link set tep0 down
ip link set gre0 down

./ovs-show.sh
