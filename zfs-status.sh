#!/bin/bash -x

rm -r /var/lib/docker

zfs create -o mountpoint=/var/lib/docker zroot/docker
zfs create -o mountpoint=/var/lib/kubelet zroot/kubelet

zfs list -t all
zfs get compressratio
zpool get dedupratio
zpool status -D zroot
