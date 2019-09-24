#!/bin/bash

set -eo pipefail

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

VIRSH_CONNECTION=
VIRSH_POOL=default
VIRSH_VOLUME_NAME=
VIRSH_DEBUG=
DELETE_VOLUME_FIRST=false

usage() {
    echo "Upload image to virsh pool"
    echo
    echo "$0 [options] [--] image-file-name"
    echo "options:"
    echo "  -c, --connect=URI          hypervisor connection URI"
    echo "                             (default: '$VIRSH_CONNECTION')"
    echo "      --pool=NAME            pool name (default: '$VIRSH_POOL')"
    echo "      --name=NAME            new volume name"
    echo "                             (default: input image file name)"
    echo "      --delete-first         delete volume before creation"
    echo "                             (default: $DELETE_VOLUME_FIRST)"
    echo "  -d, --debug=NUM            debug level [0-4]"
    echo "      --help                 Display this help and exit"
    echo "      --                     End of options"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--connect)
            VIRSH_CONNECTION=$2
            shift 2
            ;;
        --connect=*)
            VIRSH_CONNECTION=${1#*=}
            shift
            ;;
        --pool)
            VIRSH_POOL=$2
            shift 2
            ;;
        --pool=*)
            VIRSH_POOL=${1#*=}
            shift
            ;;
        --name)
            VIRSH_VOLUME_NAME=$2
            shift 2
            ;;
        --name=*)
            VIRSH_VOLUME_NAME=${1#*=}
            shift
            ;;
        --delete-first)
            DELETE_VOLUME_FIRST=true
            shift
            ;;
        -d|--debug)
            VIRSH_DEBUG=$2
            shift
            ;;
        --debug=*)
            VIRSH_DEBUG=${1#*=}
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

if [[ "$#" -ne 1 ]]; then
    usage
    fatal "No image file or too many image files specified"
fi

VIRSH_OPTS=()

if [[ -z "$VIRSH_VOLUME_NAME" ]]; then
    VIRSH_VOLUME_NAME=$(basename "$1")
fi

if [[ -n "$VIRSH_CONNECTION" ]]; then
    VIRSH_OPTS=("--connect=$VIRSH_CONNECTION")
fi

if [[ "$DELETE_VOLUME_FIRST" = "true" ]]; then
    message "* Delete virsh volume $VIRSH_VOLUME_NAME in pool $VIRSH_POOL"
    if ! ERR=$(virsh "${VIRSH_OPTS[@]}" vol-delete "$VIRSH_VOLUME_NAME" --pool "$VIRSH_POOL" 2>&1); then
        if ! grep -q "Storage volume not found" <<<"$ERR"; then
            echo >&2 "$ERR"
            exit 1
        else
            message "* No volume $VIRSH_VOLUME_NAME in pool $VIRSH_POOL"
        fi
    fi
fi

FILE_SIZE=$(stat -Lc%s "$1")
message "* Create virsh volume $VIRSH_VOLUME_NAME in pool $VIRSH_POOL"
virsh "${VIRSH_OPTS[@]}" vol-create-as "$VIRSH_POOL" "$VIRSH_VOLUME_NAME" "$FILE_SIZE" --format raw
echo "* Upload file $1 to volume $VIRSH_VOLUME_NAME in pool $VIRSH_POOL"
virsh "${VIRSH_OPTS[@]}" vol-upload --pool "$VIRSH_POOL" "$VIRSH_VOLUME_NAME" "$1"
