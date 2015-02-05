# Show bridges
CMD="ip a s" && echo -e "\n$CMD" && eval $CMD
CMD="ip r s" && echo -e "\n$CMD" && eval $CMD
CMD="route -n" && echo -e "\n$CMD" && eval $CMD
CMD="brctl show" && echo -e "\n$CMD" && eval $CMD
CMD="ovs-vsctl show" && echo -e "\n$CMD" && eval $CMD

