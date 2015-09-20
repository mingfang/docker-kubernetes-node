# Show bridges
CMD="ip a s" && echo -e "\n$CMD" && eval $CMD
CMD="ip r s" && echo -e "\n$CMD" && eval $CMD
CMD="route -n" && echo -e "\n$CMD" && eval $CMD
CMD="brctl show" && echo -e "\n$CMD" && eval $CMD
CMD="ovs-vsctl show" && echo -e "\n$CMD" && eval $CMD
CMD="ovs-ofctl -O OpenFlow13 dump-ports-desc obr0" && echo -e "\n$CMD" && eval $CMD
CMD="ovs-ofctl -O OpenFlow13 dump-flows obr0" && echo -e "\n$CMD" && eval $CMD

