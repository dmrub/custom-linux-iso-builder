# shellcheck shell=bash

#OS_IMAGE_URL=http://archive.kernel.org/centos-vault/7.6.1810/isos/x86_64/CentOS-7-x86_64-Minimal-1810.iso
#OS_IMAGE_SHA256=38d5d51d9d100fd73df031ffd6bd8b1297ce24660dc8c13a3b8b4534a4bd291c

OS_IMAGE_URL=http://mirror.ratiokontakt.de/mirror/centos/7.7.1908/isos/x86_64/CentOS-7-x86_64-Minimal-1908.iso
OS_IMAGE_SHA256=9a2c47d97b9975452f7d582264e9fc16d108ed8252ac6816239a3b58cef5c53d

DISK_LABEL="CentOS 7 x86_64"

KICKSTART_CFG_FILE=$THIS_DIR/ks.cfg
ISOLINUX_CFG_FILE=$THIS_DIR/isolinux.cfg
GRUB_CFG_FILE=$THIS_DIR/grub.cfg

INIT_DISK=sda
INIT_HOSTNAME=vagrant

# INIT_ROOTPW=vagrant
INIT_CRYPTED_ROOTPW='$6$LHJgKlWK.cQFOVXz$roDfEbg.2xg0HnRFEbwS6UWA8v0KtfYqPtgVN5rGyYQxanjp0dOZSUG5bAi5NiTEKPu88XxxiqaaFYN9BZ8Gx0'

INIT_USER=vagrant
INIT_USER_FULLNAME="Vagrant User"
# INIT_USERPW=vagrant
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
