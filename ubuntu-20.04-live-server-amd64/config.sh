# shellcheck shell=bash

# Ubuntu 20.04 autoinstall documentation
# https://ubuntu.com/server/docs/install/autoinstall-reference
# https://utcc.utoronto.ca/~cks/space/blog/linux/Ubuntu2004AutoinstFormat
# https://medium.com/@tlhakhan/ubuntu-server-20-04-autoinstall-2e5f772b655a


# shellcheck disable=SC2034
OS_IMAGE_URL=https://releases.ubuntu.com/20.04/ubuntu-20.04.1-live-server-amd64.iso
OS_IMAGE_SHA256=443511f6bf12402c12503733059269a2e10dec602916c0a75263e5d990f6bb93

#OS_IMAGE_URL=https://ftp.halifax.rwth-aachen.de/ubuntu-releases/20.04/ubuntu-20.04-live-server-amd64.iso
#OS_IMAGE_SHA256=caf3fd69c77c439f162e2ba6040e9c320c4ff0d69aad1340a514319a9264df9f

#OS_IMAGE_URL=http://cdimage.ubuntu.com/ubuntu-server/focal/daily-live/current/focal-live-server-amd64.iso
#OS_IMAGE_SHA256=ff90c880737b36d61c5059e07d987236144958b7144aae34a4da994a881d8103

DISK_LABEL="CustomUbuntu"

CUSTOM_CFG_FILES=(
    "$THIS_DIR/user-data"
    "$THIS_DIR/meta-data"
    "$THIS_DIR/user-data.bios"
    "$THIS_DIR/user-data.uefi"
)
DEST_ISO_INIT_DIR=autoinstall
ISOLINUX_CFG_FILE=$THIS_DIR/isolinux.cfg
GRUB_CFG_FILE=$THIS_DIR/grub.cfg

INIT_DISK=sda
INIT_HOSTNAME=vagrant

INIT_USER=vagrant
INIT_USER_FULLNAME="Vagrant User"
INIT_USERPW=vagrant
INIT_CRYPTED_USERPW=
#INIT_CRYPTED_USERPW='$6$LHJgKlWK.cQFOVXz$roDfEbg.2xg0HnRFEbwS6UWA8v0KtfYqPtgVN5rGyYQxanjp0dOZSUG5bAi5NiTEKPu88XxxiqaaFYN9BZ8Gx0'

INIT_AUTHORIZED_KEYS=(
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
)

INIT_USER_HOME() {
    if [[ "$INIT_USER" = "root" ]]; then
        echo "/root"
    else
        echo "/home/$INIT_USER"
    fi
}

# Timezone (e.g.: UTC, "Europe/Berlin", see /usr/share/zoneinfo/ for more)
INIT_TZ=Europe/Berlin

# Partitioning mode (PART_LVM = true | false)
PART_LVM=false
PART_DEFAULT_FS=ext4 # ext4 | btrfs

before-build() {
    # Sanity checks
    if [[ -n "$INIT_CRYPTED_ROOTPW" && -n "$INIT_ROOTPW" ]]; then
        fatal "Both INIT_CRYPTED_ROOTPW and INIT_ROOTPW variables are defined and are not empty"
    fi
    if [[ -n "$INIT_USERPW" && -n "$INIT_CRYPTED_USERPW" ]]; then
        fatal "Both INIT_USERPW and INIT_CRYPTED_USERPW variables are defined and are not empty"
    fi

    if [[ -n "$INIT_USERPW" ]]; then
        if command -v mkpasswd &> /dev/null; then
            INIT_CRYPTED_USERPW=$(mkpasswd -m sha-512 "$INIT_USERPW" | sed 's/\n$//')
        elif command -v python3 &> /dev/null; then
            INIT_CRYPTED_USERPW=$(python3 -c 'import sys,crypt,getpass; sys.stdout.write(crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA512)))' "$INIT_USERPW")
        else
            fatal "Could not encrypt password, neither mkpasswd nor python3 tool is available"
        fi
    fi
}
