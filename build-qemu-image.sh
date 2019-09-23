#!/bin/bash

THIS_DIR=$( (cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) )

set -eo pipefail

"$THIS_DIR"/build-custom-iso.sh -e "INIT_DISK=vda" "$THIS_DIR/ubuntu-18.04-server-amd64/config.sh"

RAM_SIZE=2048
IMAGE_SIZE=40G
IMAGE_FORMAT=qcow2
IMAGE_FILE=$THIS_DIR/ubuntu-18.04-amd64-$RAM_SIZE-$IMAGE_SIZE.$IMAGE_FORMAT

echo "Create QEMU image $IMAGE_FILE"
qemu-img create "$IMAGE_FILE" -f "$IMAGE_FORMAT" "$IMAGE_SIZE"
echo "Start QEMU image $IMAGE_FILE"
echo "Connect to it via VNC: vncviewer localhost:59"
qemu-system-x86_64 \
    -m "$RAM_SIZE" \
    -name ubuntu-18.04-amd64 \
    -netdev user,id=user.0,hostfwd=tcp::5940-:22 \
    -device virtio-net,netdev=user.0 \
    -drive file="$IMAGE_FILE",if=virtio,cache=writeback,discard=ignore,format=qcow2 \
    -machine type=pc,accel=kvm \
    -cdrom "$THIS_DIR/install.iso" \
    -smp cpus=2,maxcpus=16,cores=4 \
    -vnc 127.0.0.1:59 \
    -boot once=d
echo "Done"
