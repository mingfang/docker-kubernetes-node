# get all the IPs from existing flows
LOCAL=`ovs-ofctl -O OpenFlow13 dump-flows obr0|grep arp|sed -n -e 's/^.*set_field://p'|grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|sort`

# get all the IPs from etcd
REMOTE=`curl -s -L $ETCD_HOST:4001/v2/keys/registry/minions|jq .node.nodes[].key | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|sort`

echo "LOCAL=$LOCAL"
echo "REMOTE=$REMOTE"

# delete flows that are no long in etcd
diff --unchanged-line-format= --old-line-format='%L' --new-line-format= <(echo -e "$LOCAL") <(echo -e "$REMOTE") | xargs -L 1 ./ovs-remote.sh del

# add IPs from etcd that is missing in flows
diff --unchanged-line-format= --old-line-format= --new-line-format='%L' <(echo -e "$LOCAL") <(echo -e "$REMOTE") | xargs -L 1 ./ovs-remote.sh add 
