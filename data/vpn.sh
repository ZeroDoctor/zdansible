#!/bin/bash

set -e

echo login reg.zerodoc.dev...
sudo podman login reg.zerodoc.dev

echo cleanup...
sudo podman stop vpn && sleep 5

echo running vpn...
sudo podman run \
    --rm \
    --env=ACTIVATION_CODE=EMFTYY2X8VYZWGL25TPTW58 \
    --env=SERVER=smart \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    --privileged \
    --dns 10.0.0.6 \
    -p 8040:8112 \
    -p 8041:6881 \
    -p 8042:9117 \
    -p 8043:9696 \
    -p 8044:58846 \
    -p 8045:8045 \
    -p 8046:8046 \
    -p 8047:8047 \
    --detach=true \
    --tty=true \
    --name=vpn \
    --pull=newer \
    reg.zerodoc.dev/zerodoc/vpn:latest \
    /bin/bash

echo done.