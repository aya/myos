#!/bin/sh
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-alpine.in

export PATH="/usr/sbin:/usr/bin:/sbin:/bin"

ALPINE_VERSION="${ALPINE_VERSION:-3.10}"
APKREPOSOPTS="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community"
BOOT_SIZE="32"
DISKOPTS="-s 0 -m sys /dev/vda"
DNSOPTS="-n 8.8.8.8"
HOSTNAME="${HOSTNAME:-alpine}"
HOSTNAMEOPTS="-n ${HOSTNAME}"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet dhcp
"
KEYMAPOPTS="fr fr"
NTPOPTS="-c openntpd"
PROXYOPTS="none"
SSHDOPTS="-c none"
TIMEZONEOPTS="-z Europe/Paris"
export MIRRORS="http://dl-cdn.alpinelinux.org/alpine/
http://dl-2.alpinelinux.org/alpine/
http://dl-3.alpinelinux.org/alpine/
http://dl-4.alpinelinux.org/alpine/
http://dl-5.alpinelinux.org/alpine/
http://dl-8.alpinelinux.org/alpine/"

/sbin/setup-keymap ${KEYMAPOPTS}
/sbin/setup-hostname ${HOSTNAMEOPTS}
echo "${INTERFACESOPTS}" | /sbin/setup-interfaces -i
# /etc/init.d/networking --quiet start >/dev/null
# /sbin/setup-dns ${DNSOPTS}
/sbin/setup-timezone ${TIMEZONEOPTS}
/sbin/setup-proxy -q ${PROXYOPTS}
/sbin/setup-apkrepos ${APKREPOSOPTS}
/sbin/setup-ntp ${NTPOPTS}
/sbin/setup-sshd ${SSHDOPTS}
rc-update --quiet add networking boot
rc-update --quiet add urandom boot
/etc/init.d/hostname --quiet restart
killall ntpd
sed -i 's/constraints/# constraints/' /etc/ntpd.conf
sed -i 's/^#NTPD_OPTS=$/NTPD_OPTS=-s/' /etc/conf.d/openntpd
openrc boot
openrc default

echo "y" | BOOT_SIZE="${BOOT_SIZE}" DEFAULT_DISK="none" /sbin/setup-disk -q ${DISKOPTS} || exit
