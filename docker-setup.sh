#!/bin/bash

echo "Stopping Docker..."
systemctl stop docker

rm -r /var/lib/docker/network/files/local-kv.db

# Restart Docker daemon to use the new DOCKER_BRIDGE
ZFS=$([ `df --output=fstype /var/lib/docker|tail -1` == "zfs" ] && echo "--storage-driver=zfs" || echo  "")
DOCKER_OPTS="--mtu=1450 --iptables=true --insecure-registry=0.0.0.0/0 $ZFS"

#/etc/systemd/system/docker.service.d/docker.conf
mkdir -p /etc/systemd/system/docker.service.d
printf "[Service]\nExecStart=\nExecStart=/usr/bin/dockerd $DOCKER_OPTS" > /etc/systemd/system/docker.service.d/docker.conf

echo "Restarting Docker..."
systemctl daemon-reload
systemctl restart docker --ignore-dependencies

echo "DOCKER_OPTS=$DOCKER_OPTS"
