#!/bin/bash -x

zfs list -t all
zfs get compressratio
zpool get dedupratio
zpool status -D zroot
