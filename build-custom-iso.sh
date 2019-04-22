#!/bin/bash

THIS_DIR=$( (cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) )

#### Reset configuration variables ####

# OS_IMAGE_URL : URL of the ISO file to customize
OS_IMAGE_URL=
# OS_IMAGE_FILE : file name with the downloaded ISO
OS_IMAGE_FILE=
# OS_IMAGE_SHA256 : SHA-256 sum of the ISO file
OS_IMAGE_SHA256=
# DISK_LABEL : new disk label
DISK_LABEL=
# KICKSTART_CFG_FILE : path to kickstart configuration file (for RHEL / CentOS / Fedora - OS family)
KICKSTART_CFG_FILE=
# PRESEED_CFG_FILE : path to preseed configuration file (for Debian / Ubuntu - OS family)
PRESEED_CFG_FILE=
# ISOLINUX_CFG_FILE : path to isolinux configuration file
ISOLINUX_CFG_FILE=
# GRUB_CFG_FILE : path to GRUB configuration file
GRUB_CFG_FILE=

##################

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

CACHE_DIR=$THIS_DIR/cache
DEBUG=
EVAL=()

usage() {
    echo "Build custom installation ISO"
    echo
    echo "$0 [options] [--] configuration-file"
    echo "options:"
    echo "  -d, --debug                Enable debug mode"
    echo "      --help                 Display this help and exit"
    echo "  -c, --cache=CACHE_DIR      Directory in which the downloaded ISO files are stored"
    echo "                             (default: $CACHE_DIR)"
    echo "  -e,--eval=EXPR             Evaluate expression after configuration file is loaded"
    echo "      --                     End of options"
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--debug)
            DEBUG=true
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
    fatal "No configuration file specified"
fi

if [[ ! -r "$1" ]]; then
    fatal "File $1 is not readable"
fi
CONFIG_FILE=$1

# CFG_MODE : kickstart | preseed
CFG_MODE=
# DEST_ISO_INIT_DIR : directory with init file (kickstart/preseed) relative to disk root
DEST_ISO_INIT_DIR=
# DEST_EFIBOOT_IMAGE_FILE : Path to EFI boot image file relative to disk root
DEST_EFIBOOT_IMAGE_FILE=
# DEST_ISOLINUX_CFG_FILE : Path to isolinux.cfg relative to disk root
DEST_ISOLINUX_CFG_FILE=
# DEST_GRUB_CFG_FILE : Path to grub.cfg relative to disk root
DEST_GRUB_CFG_FILE=
# DEST_ELTORITO_BOOT_FILE : Path to El Torito boot image relative to disk root
DEST_ELTORITO_BOOT_FILE=
# DEST_ELTORITO_CATALOG_FILE : Path to El Torito catalog file relative to disk root
DEST_ELTORITO_CATALOG_FILE=

loadconfig() {
    local THIS_DIR
    local CONFIG_FILE=$1
    THIS_DIR=$( (cd "$(dirname -- "$CONFIG_FILE")" && pwd -P) )

    if [[ -r "$CONFIG_FILE" ]]; then
        message "Loading $CONFIG_FILE"

        unset \
            CFG_MODE \
            DEST_ISO_INIT_DIR \
            DEST_EFIBOOT_IMAGE_FILE \
            DEST_ISOLINUX_CFG_FILE \
            DEST_GRUB_CFG_FILE \
            DEST_ELTORITO_BOOT_FILE \
            DEST_ELTORITO_CATALOG_FILE \
            \
            OS_IMAGE_URL \
            OS_IMAGE_FILE \
            OS_IMAGE_SHA256 \
            DISK_LABEL \
            KICKSTART_CFG_FILE \
            PRESEED_CFG_FILE \
            ISOLINUX_CFG_FILE \
            GRUB_CFG_FILE \

        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    fi

    # Check configuration
    if [[ -z "$KICKSTART_CFG_FILE" && -z "$PRESEED_CFG_FILE" ]]; then
        fatal "Neither KICKSTART_CFG_FILE nor PRESEED_CFG_FILE variable is set"
    fi

    if [[ -n "$KICKSTART_CFG_FILE" && -n "$PRESEED_CFG_FILE" ]]; then
        fatal "Either KICKSTART_CFG_FILE or PRESEED_CFG_FILE variable should be set, but not both"
    fi

    if [[ -n "$KICKSTART_CFG_FILE" ]]; then
        CFG_MODE=kickstart
        if [[ -z "$DEST_ISO_INIT_DIR" ]]; then
            DEST_ISO_INIT_DIR=ks
        fi
        #DEST_EFIBOOT_IMAGE_FILE=images/efiboot.img
        #DEST_ISOLINUX_CFG_FILE=isolinux/isolinux.cfg
        #DEST_GRUB_CFG_FILE=EFI/BOOT/grub.cfg
    fi

    if [[ -n "$PRESEED_CFG_FILE" ]]; then
        CFG_MODE=preseed
        if [[ -z "$DEST_ISO_INIT_DIR" ]]; then
            DEST_ISO_INIT_DIR=preseed
        fi
        #DEST_EFIBOOT_IMAGE_FILE=boot/grub/efi.img
        #DEST_ISOLINUX_CFG_FILE=isolinux.cfg
        #DEST_GRUB_CFG_FILE=boot/grub/grub.cfg
    fi

    if [[ -z "$OS_IMAGE_FILE" ]]; then
        OS_IMAGE_FILE=$(basename "$OS_IMAGE_URL")
    fi
}

# shellcheck source=mo
source "$THIS_DIR/mo"

loadconfig "$1"

for expr in "${EVAL[@]}"; do
    eval "${expr}"
done

for cmd in mkisofs isohybrid; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fatal "$cmd command is missing"
    fi
done

# Define download function
define-download-func() {
    if command -v curl >/dev/null 2>&1; then
        download() {
            local url=$1
            local dest=$2

            if [[ ! -f "$dest" ]]; then
                message "Download $url"
                curl --progress-bar --fail --location --output "$dest" "$url" || \
                    fatal "Could not load $url to $dest"
            else
                message "File $dest exists, skipping download"
            fi
        }
    elif command -v wget >/dev/null 2>&1; then
        download() {
            local url=$1
            local dest=$2

            if [[ ! -f "$dest" ]]; then
                message "Download $url"
                wget -O "$dest" "$url" || \
                    fatal "Could not load $url to $dest"
            else
                message "File $dest exists, skipping download"
            fi
        }
    else
        fatal "No download tool detected (checked: curl, wget)"
    fi
}

# Define sha256hash
define-sha256hash-func() {
    if command -v sha256sum >/dev/null 2>&1 && command -v cut >/dev/null 2>&1; then
        sha256hash() {
            sha256sum -b "$1" | cut -d' ' -f1
        }
    elif command -v openssl >/dev/null 2>&1 && command -v cut >/dev/null 2>&1; then
        sha256hash() {
            openssl sha256 -r "$1" | cut -d' ' -f1
        }
    elif command -v python >/dev/null 2>&1; then
        sha256hash() {
            python -c "
from __future__ import print_function
import hashlib
import sys
h = hashlib.sha256()
fd = open(sys.argv[1], 'rb')
h.update(fd.read())
fd.close()
print(h.hexdigest())" "$1"
        }
    else
        fatal "No SHA-256 tool detected (checked: sha256sum, openssl, python)"
    fi
}

download-and-check-sha256-hash() {
    local url=$1
    local dest=$2
    local hash=$3
    local dest_hash
    if [[ -f "$dest" ]]; then
        message "Verify sha256 hash of file $dest ..."
        dest_hash=$(sha256hash "$dest")
        if [[ "$dest_hash" = "$hash" ]]; then
            message "sha256 hash verified ($hash) !"
            return 0
        else
            error "sha256 hash verification failed: hash is $dest_hash, but should be $hash"
            rm "$dest"
        fi
    fi
    download "$1" "$2"
    dest_hash=$(sha256hash "$dest")
    if [[ "$dest_hash" = "$hash" ]]; then
        message "sha256 hash verified ($hash) !"
    else
        fatal "sha256 hash verification failed: hash is $dest_hash, but should be $hash"
    fi
    return 0
}

# Check common file locations
detect-files() {
    local var_name=$1
    local var_descr=$2
    local f
    shift 2
    if [[ -z "${!var_name}" ]]; then
        for f in "$@"; do
            if [[ -e "$DISK_DIR/$f" ]]; then
                echo "Detected $var_descr: $f"
                printf -v "$var_name" "%s" "$f"
                break
            fi
        done
        if [[ -z "${!var_name}" ]]; then
            fatal "Could not detect $var_descr on disk"
        fi
    fi
}

# mount_iso () {
#     local mounted_on mount_path

#     if ! mounted_on=$(sudo "$UDISKSCTL" loop-setup --file "$1"); then
# 	error  "Mount of $1 failed"
#         return 1
#     fi

#     mounted_on=$(echo "$mounted_on" | awk 'NF-1{print $NF}')
#     mount_path=$(grep "$mounted_on" /proc/mounts | awk '{print $2}')
#     echo "$mount_path"
# }

define-download-func
define-sha256hash-func

mkdir -p "$CACHE_DIR"

if ! download-and-check-sha256-hash "$OS_IMAGE_URL" "$CACHE_DIR/$OS_IMAGE_FILE" "$OS_IMAGE_SHA256"; then
    rm -f "$CACHE_DIR/$OS_IMAGE_FILE"
    fatal "Download failed"
fi

# if ! command -v udisksctl >/dev/null 2>&1; then
#     fatal "Missing udisksctl tool"
# else
#     UDISKSCTL=$(type -p udisksctl)
# fi

ISO_MOUNT_PATH=
DISK_DIR=
EFIBOOT_MOUNT_PATH=

cleanup() {
    if [[ "$DEBUG" == "true" ]]; then
        (
            set +x
            echo >&2 "Debug mode is active, type 'exit' and <ENTER> to continue"
            $SHELL -i
        )
    fi
    if [[ -n "$ISO_MOUNT_PATH" ]]; then
        echo "Unmounting $ISO_MOUNT_PATH"
        sudo umount "$ISO_MOUNT_PATH" || true;
        rmdir "$ISO_MOUNT_PATH" || true;
    fi
    if [[ -n "$EFIBOOT_MOUNT_PATH" ]]; then
        echo "Unmounting $EFIBOOT_MOUNT_PATH"
        sudo umount "$EFIBOOT_MOUNT_PATH" || true;
        rmdir "$EFIBOOT_MOUNT_PATH" || true;
    fi
    if [[ -n "$DISK_DIR" ]]; then
        echo "Deleting $DISK_DIR"
        { chmod -R u+rw "$DISK_DIR" && rm -rf "$DISK_DIR"; } || true;
    fi
}

trap cleanup INT EXIT TERM

if [[ "$DEBUG" == "true" ]]; then
    set -x
fi

MDIR=$THIS_DIR/iso
MFILE=$CACHE_DIR/$OS_IMAGE_FILE
mkdir -p "$MDIR"
if ! sudo mount -o loop,ro -t auto "$MFILE" "$MDIR"; then
    fatal "Could not mount file $MFILE"
fi
ISO_MOUNT_PATH="$MDIR"

DISK_DIR="$THIS_DIR/disk"
mkdir -p "$DISK_DIR"

if command -v rsync >/dev/null 2>&1; then
    sudo rsync --progress -av "$ISO_MOUNT_PATH/" "$DISK_DIR/"
else
    sudo cp -pR "$ISO_MOUNT_PATH"/* "$DISK_DIR"
fi

sudo chown "$(id -u):$(id -g)" -R "$DISK_DIR"

detect-files DEST_EFIBOOT_IMAGE_FILE "EFI boot file" images/efiboot.img boot/grub/efi.img

if [[ -n "$DEST_EFIBOOT_IMAGE_FILE" ]]; then
    echo "Original EFI boot file $DEST_EFIBOOT_IMAGE_FILE: $(md5sum -b "$DISK_DIR/$DEST_EFIBOOT_IMAGE_FILE")"

    MDIR=$THIS_DIR/efiboot
    MFILE=$DISK_DIR/$DEST_EFIBOOT_IMAGE_FILE
    mkdir -p "$MDIR"
    if ! sudo mount -o loop -t auto "$MFILE" "$MDIR"; then
        fatal "Could not mount file $MFILE"
    fi
    EFIBOOT_MOUNT_PATH=$MDIR
else
    echo "No EFI boot file location in this configuration"
fi

chmod u+rw "$DISK_DIR"
mkdir -p "$DISK_DIR/$DEST_ISO_INIT_DIR"

TIMESTAMP=$(date +"%Y-%m-%d@%H:%M:%S")

if [[ -n "$KICKSTART_CFG_FILE" ]]; then
    mo < "$KICKSTART_CFG_FILE" | tee "ks.cfg.${TIMESTAMP}" > "$DISK_DIR/$DEST_ISO_INIT_DIR/ks.cfg"

    if command -v ksvalidator >/dev/null 2>&1; then
        echo "Checking ks.cfg with ksvalidator"
        echo
        ksvalidator "$DISK_DIR/ks/ks.cfg" || true;
        echo
    fi
fi

if [[ -n "$PRESEED_CFG_FILE" ]]; then
    chmod u+rwx "$DISK_DIR/$DEST_ISO_INIT_DIR"
    mo < "$PRESEED_CFG_FILE" | tee "preseed.cfg.${TIMESTAMP}" > "$DISK_DIR/$DEST_ISO_INIT_DIR/preseed.cfg"
fi

detect-files DEST_ISOLINUX_CFG_FILE "ISOLINUX config file" isolinux/isolinux.cfg isolinux.cfg
detect-files DEST_GRUB_CFG_FILE "GRUB config file" EFI/BOOT/grub.cfg boot/grub/grub.cfg

(
    # set -x
    if [[ -e "$DISK_DIR/$DEST_ISOLINUX_CFG_FILE" ]]; then
        chmod u+rw "$DISK_DIR/$DEST_ISOLINUX_CFG_FILE"
    fi
    mo < "$ISOLINUX_CFG_FILE" | tee "isolinux.cfg.${TIMESTAMP}" > "$DISK_DIR/$DEST_ISOLINUX_CFG_FILE"
    if [[ -e "$DISK_DIR/$DEST_GRUB_CFG_FILE" ]]; then
        chmod u+rw "$DISK_DIR/$DEST_GRUB_CFG_FILE"
    fi
    mo < "$GRUB_CFG_FILE" | tee "grub.cfg.${TIMESTAMP}" > "$DISK_DIR/$DEST_GRUB_CFG_FILE"
    if [[ -n "$EFIBOOT_MOUNT_PATH" ]]; then
        if [[ -e "$EFIBOOT_MOUNT_PATH/$DEST_GRUB_CFG_FILE" ]]; then
            echo "Original grub.cfg $(md5sum "$EFIBOOT_MOUNT_PATH/$DEST_GRUB_CFG_FILE")"
            sudo cp "$DISK_DIR/$DEST_GRUB_CFG_FILE" "$EFIBOOT_MOUNT_PATH/$DEST_GRUB_CFG_FILE"
            echo "Modified grub.cfg $(md5sum "$EFIBOOT_MOUNT_PATH/$DEST_GRUB_CFG_FILE")"
        else
            echo "No $DEST_GRUB_CFG_FILE in EFI boot file"
        fi
        sudo umount "$EFIBOOT_MOUNT_PATH"
        echo "Modified EFI boot file $DEST_EFIBOOT_IMAGE_FILE $(md5sum "$DISK_DIR/$DEST_EFIBOOT_IMAGE_FILE")"
        sudo rmdir "$EFIBOOT_MOUNT_PATH"
    fi
)

EFIBOOT_MOUNT_PATH=

ls -la "$DISK_DIR"

detect-files DEST_ELTORITO_BOOT_FILE "El Torito boot file" isolinux/isolinux.bin isolinux.bin
detect-files DEST_ELTORITO_CATALOG_FILE "El Torito catalog file" isolinux/boot.cat boot.cat

chmod -R u+rw "$DISK_DIR"

mkisofs -U -r -v -T -J -joliet-long \
        -cache-inodes \
        -V "$DISK_LABEL" -volset "$DISK_LABEL" -A "$DISK_LABEL" \
        -b "$DEST_ELTORITO_BOOT_FILE" -c "$DEST_ELTORITO_CATALOG_FILE" \
        -no-emul-boot -boot-load-size 4 \
        -boot-info-table -eltorito-alt-boot -e "$DEST_EFIBOOT_IMAGE_FILE" \
        -no-emul-boot -o install.iso "$DISK_DIR/"

# Setup UEFI boot for ISO disk
isohybrid --uefi install.iso

echo "* Created boot image in $PWD/install.so"
echo "* Image Source: $OS_IMAGE_URL"
if [[ -n "$KICKSTART_CFG_FILE" ]]; then
    echo "* Kickstart Config File: $KICKSTART_CFG_FILE"
fi
if [[ -n "$PRESEED_CFG_FILE" ]]; then
    echo "* Preseed Config File: $PRESEED_CFG_FILE"
fi
echo "Done"
