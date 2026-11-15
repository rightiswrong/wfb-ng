#!/bin/sh
# Prepare a checkout of svpcom/rtl8812au (branch v5.2.20) to build with
# RTL8814AU support. Run it inside that checkout, before dkms-install.sh or
# the manual DKMS steps:
#
#   git clone -b v5.2.20 https://github.com/svpcom/rtl8812au.git
#   cd rtl8812au
#   sh /path/to/wfb-ng/drivers/rtl8812au-8814/enable-8814.sh
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
TESTED=3577999972f350a2213e7509ae1f371b99fc96ab

if [ ! -f Makefile ] || [ ! -f hal/phydm/phydm_phystatus.c ]; then
    echo "Run this inside an svpcom/rtl8812au checkout." >&2
    exit 1
fi

if command -v git >/dev/null 2>&1 && git rev-parse HEAD >/dev/null 2>&1; then
    HEAD=$(git rev-parse HEAD)
    if [ "$HEAD" != "$TESTED" ]; then
        echo "Note: checkout is $HEAD; the patch was tested on $TESTED."
    fi
fi

# 1. Backport the RTL8814AU RSSI function (the driver stops the build without it)
if grep -q 'FIXME: Need to backport phydm_get_rssi_8814_ofdm' hal/phydm/phydm_phystatus.c; then
    patch -p1 --forward < "$HERE/0001-phydm-backport-phydm_get_rssi_8814_ofdm.patch"
else
    echo "phydm_get_rssi_8814_ofdm already present; patch skipped."
fi

# 2. Build RTL8814AU support into 88XXau_wfb
sed -i 's/^CONFIG_RTL8814A = n/CONFIG_RTL8814A = y/' Makefile

# 3. 64-bit ARM (Raspberry Pi and others): the platform switch from the upstream README
if [ "$(uname -m)" = "aarch64" ]; then
    sed -i 's/^CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/; s/^CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/' Makefile
fi

grep -E '^CONFIG_RTL88(12|21|14)A = |^CONFIG_PLATFORM_(I386_PC|ARM64_RPI) = ' Makefile
echo "Ready. Install with DKMS as usual; the module is still 88XXau_wfb."
