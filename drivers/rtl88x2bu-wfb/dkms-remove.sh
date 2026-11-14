#!/bin/sh
# Remove the wfb-ng RTL88x2BU driver.
set -e

if [ "$(id -u)" != "0" ]; then
    echo "Run as root: sudo $0"
    exit 1
fi

DRV_NAME=rtl88x2bu-wfb
DRV_VERSION=5.13.1.wfb1

modprobe -r 88x2bu_wfb 2>/dev/null || true
dkms remove -m ${DRV_NAME} -v ${DRV_VERSION} --all || true
rm -rf /usr/src/${DRV_NAME}-${DRV_VERSION}
rm -f /etc/modprobe.d/rtl88x2bu-wfb.conf

echo "Removed ${DRV_NAME} ${DRV_VERSION}."
