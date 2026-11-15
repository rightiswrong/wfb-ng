# RTL8814AU support for the wfb-ng RTL8812AU driver

The wfb-ng driver [svpcom/rtl8812au](https://github.com/svpcom/rtl8812au) (branch v5.2.20)
already contains the RTL8814AU chip code, including wfb-ng's injection handling, but
builds it only with `CONFIG_RTL8814A = y`. With that set, the build stops at:

    #error "FIXME: Need to backport phydm_get_rssi_8814_ofdm from v5.6.4.2"

That line was added on 2023-11-07 when another fix was backported from Realtek v5.6.4.2.
The missing function averages the received signal of the four RX paths for the driver's
own statistics; it is not part of injection.

`0001-phydm-backport-phydm_get_rssi_8814_ofdm.patch` adds it, adapted to this driver's
older maths library. It skips paths that report 0 (the upstream version would read past
its lookup table) and uses every path with a signal if the active-path mask was never set.

**Status: builds on Ubuntu 24.04 and 26.04 (see CI), not tested on hardware.**

## Install

```sh
git clone -b v5.2.20 https://github.com/svpcom/rtl8812au.git
cd rtl8812au
sh /path/to/wfb-ng/drivers/rtl8812au-8814/enable-8814.sh
sudo ./dkms-install.sh        # note: upstream's script also disables IPv6 machine-wide
```

`enable-8814.sh` applies the patch, sets `CONFIG_RTL8814A = y`, and on 64-bit ARM
switches the Makefile to the ARM64 platform. The module is still `88XXau_wfb` and
`ethtool -i` reports `rtl88xxau_wfb`, so wfb-ng needs no changes.

Plug RTL8814AU cards into a USB 3 port; they draw more power than RTL8812AU cards.

## CI

`.github/workflows/build_rtl8812au_8814.yml` fetches svpcom/rtl8812au at
3577999 (2026-11-07), runs `enable-8814.sh`, and builds against every Ubuntu 24.04 and
26.04 kernel-header package on amd64 and arm64. It checks the module contains
RTL8814AU USB IDs and code.
