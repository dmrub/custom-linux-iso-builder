# shellcheck shell=bash

OS_IMAGE_URL=http://mirror.ratiokontakt.de/mirror/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1810.iso
OS_IMAGE_SHA256=38d5d51d9d100fd73df031ffd6bd8b1297ce24660dc8c13a3b8b4534a4bd291c
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

if [[ "$INIT_USER" = "root" ]]; then
    INIT_USER_HOME=/root
else
    INIT_USER_HOME=/home/$INIT_USER
fi