#!/bin/bash -x

rm -r /var/lib/docker
rm -r /var/lib/kubelet

zfs create -o mountpoint=/var/lib/docker zroot/docker
zfs create -o mountpoint=/var/lib/kubelet zroot/kubelet
zfs mount -a

./zfs-status.sh
