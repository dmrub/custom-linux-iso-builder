# shellcheck shell=bash

OS_IMAGE_URL=http://cdimage.ubuntu.com/ubuntu/releases/bionic/release/ubuntu-18.04.2-server-amd64.iso
OS_IMAGE_SHA256=a2cb36dc010d98ad9253ea5ad5a07fd6b409e3412c48f1860536970b073c98f5
DISK_LABEL="CustomUbuntu"

PRESEED_CFG_FILE=$THIS_DIR/preseed.cfg
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

PRESEED_KERNEL_OPTIONS="auto=true \
priority=critical \
console-setup/ask_detect=false \
console-setup/layoutcode=us \
console-setup/modelcode=pc105 \
debconf/frontend=noninteractive \
debian-installer=en_US \
fb=false \
debian-installer/locale=en_US \
localechooser/translation/warn-light=true \
localechooser/translation/warn-severe=true \
keyboard-configuration/layout=USA \
keyboard-configuration/variant=USA \
locale=en_US \
netcfg/get_domain=vm \
netcfg/get_hostname=${INIT_HOSTNAME} \
grub-installer/bootdev=/dev/${INIT_DISK} \
DEBCONF_DEBUG=5"

#mirror/http/mirror=http://ftp.halifax.rwth-aachen.de/ubuntu/ \
#partman/unmount_active=true \

before-build() {
    # Sanity checks
    if [[ -n "$INIT_CRYPTED_ROOTPW" && -n "$INIT_ROOTPW" ]]; then
        fatal "Both INIT_CRYPTED_ROOTPW and INIT_ROOTPW variables are defined and are not empty"
    fi
    if [[ -n "$INIT_USERPW" && -n "$INIT_CRYPTED_USERPW" ]]; then
        fatal "Both INIT_USERPW and INIT_CRYPTED_USERPW variables are defined and are not empty"
    fi
}
