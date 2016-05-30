#!/bin/bash
set -e

LOCAL=`ovs-vsctl list interface|grep options|grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|sort`
CURL=`curl --fail -s -L $ETCD_HOST:4001/v2/keys/registry/minions`
REMOTE=`echo $CURL|jq .node.nodes[].key | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|sort`

echo "LOCAL=$LOCAL"
echo "REMOTE=$REMOTE"

diff --unchanged-line-format= --old-line-format='%L' --new-line-format= <(echo -e "$LOCAL") <(echo -e "$REMOTE") | xargs -L 1 ./ovs-remote.sh del
diff --unchanged-line-format= --old-line-format= --new-line-format='%L' <(echo -e "$LOCAL") <(echo -e "$REMOTE") | xargs -L 1 ./ovs-remote.sh add 
