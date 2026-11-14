#!/bin/sh
# Install the wfb-ng RTL88x2BU driver through DKMS.
set -e

if [ "$(id -u)" != "0" ]; then
    echo "Run as root: sudo $0"
    exit 1
fi

DRV_NAME=rtl88x2bu-wfb
DRV_VERSION=5.13.1.wfb1
SRC_DIR=$(cd "$(dirname "$0")" && pwd)
DST_DIR=/usr/src/${DRV_NAME}-${DRV_VERSION}

if dkms status -m ${DRV_NAME} -v ${DRV_VERSION} 2>/dev/null | grep -q .; then
    dkms remove -m ${DRV_NAME} -v ${DRV_VERSION} --all
fi
rm -rf "${DST_DIR}"
cp -r "${SRC_DIR}" "${DST_DIR}"

dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
dkms build -m ${DRV_NAME} -v ${DRV_VERSION}
dkms install -m ${DRV_NAME} -v ${DRV_VERSION}

install -m 644 "${SRC_DIR}/rtl88x2bu-wfb.conf" /etc/modprobe.d/rtl88x2bu-wfb.conf

echo "Installed ${DRV_NAME} ${DRV_VERSION}. Unplug and replug the card, or reboot."
