# shellcheck shell=bash

OS_IMAGE_URL=https://ftp.halifax.rwth-aachen.de/fedora/linux/releases/29/Server/x86_64/iso/Fedora-Server-netinst-x86_64-29-1.2.iso
OS_IMAGE_SHA256=aa7fb0e6e5b71774ebdaab0dae76bdd9246a5bc7aedc28b7f1103aaaf9750654
DISK_LABEL="Fedora-S-dvd-x86_64-29"

KICKSTART_CFG_FILE=$THIS_DIR/ks.cfg
ISOLINUX_CFG_FILE=$THIS_DIR/isolinux.cfg
GRUB_CFG_FILE=$THIS_DIR/grub.cfg

INIT_DISK=sda
INIT_HOSTNAME=vagrant

# INIT_ROOTPW=vagrant
INIT_ROOTPW=
INIT_CRYPTED_ROOTPW='$6$LHJgKlWK.cQFOVXz$roDfEbg.2xg0HnRFEbwS6UWA8v0KtfYqPtgVN5rGyYQxanjp0dOZSUG5bAi5NiTEKPu88XxxiqaaFYN9BZ8Gx0'

INIT_USER=vagrant
INIT_USER_FULLNAME="Vagrant User"
# INIT_USERPW=vagrant
INIT_USERPW=
INIT_CRYPTED_USERPW='$6$LHJgKlWK.cQFOVXz$roDfEbg.2xg0HnRFEbwS6UWA8v0KtfYqPtgVN5rGyYQxanjp0dOZSUG5bAi5NiTEKPu88XxxiqaaFYN9BZ8Gx0'


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

before-build() {
    # Sanity checks
    if [[ -n "$INIT_CRYPTED_ROOTPW" && -n "$INIT_ROOTPW" ]]; then
        fatal "Both INIT_CRYPTED_ROOTPW and INIT_ROOTPW variables are defined and are not empty"
    fi
    if [[ -n "$INIT_USERPW" && -n "$INIT_CRYPTED_USERPW" ]]; then
        fatal "Both INIT_USERPW and INIT_CRYPTED_USERPW variables are defined and are not empty"
    fi
}
