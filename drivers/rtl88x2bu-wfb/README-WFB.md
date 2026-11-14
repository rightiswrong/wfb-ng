# RTL88x2BU driver for WFB-ng

Linux driver for USB cards based on Realtek RTL8812BU and RTL8822BU, patched for
packet injection with WFB-ng. Module `88x2bu_wfb`, driver name `rtl88x2bu_wfb`.

Base: [morrownr/88x2bu-20210702](https://github.com/morrownr/88x2bu-20210702)
commit 418d71cc00cd18b4a671f8c49ecce9b19cbfd3c9 (2026-10-25), Realtek v5.13.1, GPL-2.0.
The WFB-ng changes are ported from [svpcom/rtl8812au](https://github.com/svpcom/rtl8812au)
branch v5.2.20.

**Status: experimental.** Not yet tested on hardware. See "Testing" below.

## Changes from the base driver

| Area | Base driver | This driver |
| --- | --- | --- |
| Injection | Frames whose radiotap header is not 12 bytes are dropped; broadcast data goes at 24 Mbit/s | Radiotap is parsed: legacy rate, HT MCS, VHT MCS/NSS, short GI, 20/40/80 MHz, LDPC, STBC and the NOACK flag are applied per frame |
| TX descriptor (8822B) | Fixed retry limit, hardware sequence numbers | Injected frames: rate fallback off, 0 retries with NOACK (6 without), injected sequence number kept |
| Frame size | 1536-byte extension buffers | 4096-byte buffers, frames up to 4052 bytes (WFB-ng `WIFI_MTU` is 4045) |
| TX queue | Frames dropped when buffers run out | Module option `MaxTxBufLen` returns `NETDEV_TX_BUSY` before the queue fills |
| TX power | dBm targets only | Module option `rtw_tx_pwr_idx_override` (0..63) and `iw ... set txpower fixed -N00` set a raw power index, as in rtl8812au |
| RX radiotap | One combined signal value | Per-path dBm signal and antenna index (used by `wfb-cli` and TX antenna selection) |
| Names | `88x2bu` / `rtl88x2bu` | `88x2bu_wfb` / `rtl88x2bu_wfb` |

Not ported from rtl8812au: "Relax WIFI regional rules" and "Disable DFS". Keep to
channels your regulatory domain allows; non-DFS channels only.

## Install (Ubuntu / Debian)

```sh
sudo apt install build-essential bc dkms linux-headers-$(uname -r)
cd drivers/rtl88x2bu-wfb
sudo ./dkms-install.sh
```

This builds the module through DKMS (rebuilt on kernel updates) and installs
`/etc/modprobe.d/rtl88x2bu-wfb.conf`, which blacklists `rtw88_8822bu` and `88x2bu`,
turns power saving off and sets TX power index 1. Unplug and replug the card.
With Secure Boot on, enroll the DKMS key once:
`sudo mokutil --import /var/lib/shim-signed/mok/MOK.der`, then reboot and choose Enroll MOK.

Remove with `sudo ./dkms-remove.sh`.

## Testing

```sh
IF=wlx...                          # from 'iw dev'
ethtool -i $IF | head -1           # driver: rtl88x2bu_wfb
sudo ip link set $IF down
sudo iw dev $IF set type monitor
sudo ip link set $IF up
sudo iw dev $IF set channel 165 HT20
```

Then run WFB-ng with a known-good RTL8812AU card on the other end, in both directions:

1. RTL8812AU transmits, this card receives: checks RX and per-antenna RSSI in `wfb-cli`.
2. This card transmits, RTL8812AU receives: checks injection. In `wfb-cli` on the
   receiver the MCS should match `mcs_index` from the profile.
3. Set `ldpc = 0` in the profile until LDPC has been confirmed on this chip.

## Known limits

- RTL8822B is 2T2R: VHT NSS above 2 is clamped to 2.
- 40 MHz injection sets the bandwidth bit only, not the sub-channel; use 20 MHz.
- The RTL8822BU Bluetooth part is handled by the kernel's btusb driver, not this one.
