#!/bin/bash

set -e

echo login reg.zerodoc.dev...
sudo podman login reg.zerodoc.dev

echo running...
sudo podman run \
    --rm \
    -it \
    --network container:vpn \
    --name=nettools \
    --pull=newer \
    reg.zerodoc.dev/zerodoc/nettools

echo done.