LOCAL=`ovs-vsctl list interface|grep options|grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|sort`
REMOTE=`curl -s -L minux:4001/v2/keys/registry/minions|jq .node.nodes[].key | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|sort`

#echo "LOCAL=$LOCAL"
#echo "REMOTE=$REMOTE"

diff --unchanged-line-format= --old-line-format='%L' --new-line-format= <(echo -e "$LOCAL") <(echo -e "$REMOTE") | xargs -L 1 ./ovs-remote.sh del
diff --unchanged-line-format= --old-line-format= --new-line-format='%L' <(echo -e "$LOCAL") <(echo -e "$REMOTE") | xargs -L 1 ./ovs-remote.sh add 
