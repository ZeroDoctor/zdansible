#!/bin/bash

set -e

echo ensure vdrive exists...
mkdir /mnt/vdrive || true

echo ensure vdrive is not mounted...
(sudo umount vdrive && sleep 5) || true

echo mounting...
sudo mount -t nfs4 vp0dune.node.dc1.consul:/mnt/vdrive /mnt/vdrive
# sudo mount -t cifs //vp0dune.node.dc1.consul/v1drive /home/zdune/v1drive \
#     -o user=ddune,uid=8000,gid=8000,forceuid,forcegid,file_mode=0777,dir_mode=0777

echo done.