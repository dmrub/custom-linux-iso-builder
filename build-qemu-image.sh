#!/bin/bash

set -eo pipefail

THIS_DIR=$( (cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) )

error() {
    echo >&2 "* Error: $*"
}

fatal() {
    error "$@"
    exit 1
}

message() {
    echo "$*"
}

usage() {
    echo "Build QEMU image from custom ISO configuration or installation ISO 9660 image"
    echo
    echo "$0 [options] [--] [configuration-file configuration-file ...]"
    echo "options:"
    echo "  -q, --qemu=QEMU_TOOL         Specify qemu executable"
    echo "                               (default: $QEMU_TOOL)"
    echo "  -m, --ram-size=RAM_SIZE      RAM size of a VM"
    echo "                               (default: $RAM_SIZE)"
    echo "  -s, --image-size=IMAGE_SIZE  Size of a QEMU image"
    echo "                               (default: $IMAGE_SIZE)"
    echo "  -i, --iso=ISO_FILE           Specify the ISO file with the ISO9660 filesystem image."
    echo "                               (default: $ISO_FILE)"
    echo "                               This file is output if configuration files are specified"
    echo "      --no-iso                 Don't use or build ISO, just run existing QEMU image"
    echo "  -f, --image-format=IMAGE_FORMAT"
    echo "                               QEMU image format"
    echo "                               (default: $IMAGE_FORMAT)"
    echo "  -n, --image-name=IMAGE_NAME"
    echo "                               QEMU image name prefix"
    echo "                               (default: $IMAGE_NAME)"
    echo "  -o, --output=IMAGE_FILE      QEMU image file"
    echo "      --image-file=IMAGE_FILE"
    echo "                               (default: $IMAGE_FILE)"
    echo "  -w, --overwrite              Overwrite QEMU image file if it already exists"
    echo "  -c, --cache=CACHE_DIR        Directory in which the downloaded ISO files are stored"
    echo "                               (default: $CACHE_DIR)"
    echo "  -e,--eval=EXPR               Evaluate expression after all configuration files are loaded"
    echo "  -d, --debug                  Enable debug mode"
    echo "      --help                   Display this help and exit"
    echo "      --                       End of options"
}

# Detect qemu
QEMU_TOOL=
if [[ -x /usr/libexec/qemu-kvm ]]; then
    # We are likely on CentOS
    QEMU_TOOL=/usr/libexec/qemu-kvm
elif command -v qemu-system-x86_64 >/dev/null 2>&1; then
    QEMU_TOOL=$(command -v qemu-system-x86_64)
elif command -v qemu-kvm >/dev/null 2>&1; then
    QEMU_TOOL=$(command -v qemu-kvm)
fi

CACHE_DIR=$THIS_DIR/cache
ISO_FILE=$THIS_DIR/install.iso
RAM_SIZE=2048
IMAGE_SIZE=40G
IMAGE_FORMAT=qcow2
IMAGE_FILE=
IMAGE_NAME=
OVERWRITE=
DEBUG=

while [[ $# -gt 0 ]]; do
    case "$1" in
        -q|--qemu)
            QEMU_TOOL="$2"
            shift 2
            ;;
        --qemu=*)
            QEMU_TOOL="${1#*=}"
            shift
            ;;
        -m|--ram-size)
            RAM_SIZE="$2"
            shift 2
            ;;
        --ram-size=*)
            RAM_SIZE="${1#*=}"
            shift
            ;;
        -s|--image-size)
            IMAGE_SIZE="$2"
            shift 2
            ;;
        --image-size=*)
            IMAGE_SIZE="${1#*=}"
            shift
            ;;
        -i|--iso)
            ISO_FILE="$2"
            shift 2
            ;;
        --iso=*)
            ISO_FILE="${1#*=}"
            shift
            ;;
        --no-iso)
            ISO_FILE=
            shift
            ;;
        -f|--image-format)
            IMAGE_FORMAT="$2"
            shift 2
            ;;
        --image-format=*)
            IMAGE_FORMAT="${1#*=}"
            shift
            ;;
        -n|--image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --image-name=*)
            IMAGE_NAME="${1#*=}"
            shift
            ;;
        -o|--output|--image-file)
            IMAGE_FILE="$2"
            shift 2
            ;;
        --output=*)
            IMAGE_FILE="${1#*=}"
            shift
            ;;
        --image-file=*)
            IMAGE_FILE="${1#*=}"
            shift
            ;;
        -w|--overwrite)
            OVERWRITE=true
            shift
            ;;
        -c|--cache)
            CACHE_DIR="$2"
            shift 2
            ;;
        --cache=*)
            CACHE_DIR="${1#*=}"
            shift
            ;;
        -e|--eval)
            EVAL+=("$2")
            shift 2
            ;;
        --eval=*)
            EVAL+=("${1#*=}")
            shift
            ;;
        -d|--debug)
            DEBUG=true
            shift
            ;;
        --help)
            usage
            exit
            ;;
        --)
            shift
            break
            ;;
        -*)
            fatal "Unknown option $1"
            ;;
        *)
            break
            ;;
    esac
done

if [[ -z "$ISO_FILE" && $# -gt 0 ]]; then
    fatal "ISO file generation is disabled, but build configuration files are specified"
fi
BUILD_CONFIG_FILES=()
while [[ $# -gt 0 ]]; do
    BUILD_CONFIG_FILES+=("$1")
    shift
done

if [[ -z "$IMAGE_NAME" && -n "$ISO_FILE" ]]; then
    IMAGE_NAME=$(basename -- "$ISO_FILE")
    IMAGE_NAME=${IMAGE_NAME%.iso}
fi

if [[ -z "$IMAGE_FILE" ]]; then
    if [[ -z "$IMAGE_NAME" ]]; then
        fatal "Specify QEMU image name or QEMU image file"
    fi
    IMAGE_FILE=$THIS_DIR/$IMAGE_NAME-$RAM_SIZE-$IMAGE_SIZE.$IMAGE_FORMAT
fi

if [[ -z "$IMAGE_NAME" ]]; then
    IMAGE_NAME=$(basename -- "$IMAGE_FILE")
    IMAGE_NAME=${IMAGE_NAME%.qcow2}
fi

echo "Configuration:"
echo "QEMU_TOOL:    $QEMU_TOOL"
echo "RAM_SIZE:     $RAM_SIZE"
echo "IMAGE_SIZE:   $IMAGE_SIZE"
echo "ISO_FILE:     $ISO_FILE"
echo "IMAGE_FORMAT: $IMAGE_FORMAT"
echo "IMAGE_NAME:   $IMAGE_NAME"
echo "IMAGE_FILE:   $IMAGE_FILE"
echo "CACHE_DIR:    $CACHE_DIR"
echo "EVAL:         ${EVAL[*]}"
echo "BUILD_CONFIG_FILES: ${BUILD_CONFIG_FILES[*]}"
echo

if [[ "${#BUILD_CONFIG_FILES}" -gt 0 ]]; then
    echo "Configuration files specified, building ISO file $ISO_FILE ..."
    (
        set -xe;
        "$THIS_DIR"/build-custom-iso.sh \
            "${EVAL[@]}" \
            -e "INIT_DISK=vda" \
            "--cache=$CACHE_DIR" \
            "--output=$ISO_FILE" \
            "${BUILD_CONFIG_FILES[@]}"
    )
fi

create-image-file() {
    echo "Create QEMU image $IMAGE_FILE"
    (
        set -xe;
        qemu-img create "$IMAGE_FILE" -f "$IMAGE_FORMAT" "$IMAGE_SIZE";
    )
}


if [[ -e "$IMAGE_FILE" ]]; then
    if [[ "$OVERWRITE" = "true" ]]; then
        echo "Warning: QEMU image file exists, overwriting !"
        create-image-file
    else
        echo "QEMU image file exists !"
        if [[ "${#BUILD_CONFIG_FILES}" -gt 0 ]]; then
            error "New ISO file is created, but QEMU image file already exists"
            fatal "Specify a different QEMU image file, or remove QEMU image file, or pass --overwrite parameter to overwrite QEMU image file"
        fi
    fi
else
    create-image-file
fi

echo "Start QEMU image $IMAGE_FILE"
echo "Connect to it via VNC: vncviewer localhost:59"
(
    set -xe;
    "$QEMU_TOOL" \
        -m "$RAM_SIZE" \
        -name "$IMAGE_NAME" \
        -netdev user,id=user.0,hostfwd=tcp::5940-:22 \
        -device virtio-net,netdev=user.0 \
        -drive file="$IMAGE_FILE",if=virtio,cache=writeback,discard=ignore,format=qcow2 \
        -machine type=pc,accel=kvm \
        ${ISO_FILE:+"-cdrom"} ${ISO_FILE:+"$ISO_FILE"} \
        -smp cpus=2,maxcpus=16,cores=4 \
        -vnc 127.0.0.1:59 \
        -boot once=d;
)
echo "Done"
