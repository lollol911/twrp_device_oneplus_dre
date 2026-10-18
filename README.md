# TWRP device tree: OnePlus Nord N200 5G (dre)

Unofficial TWRP for a phone with **no recovery partition**: recovery lives in
`vendor_boot` (boot header v3). The build produces `vendor_boot.img`, built in
the cloud by GitHub Actions on the `twrp-12.1` minimal manifest.

Status: first build, untested. Known limits:

- `/data` must be **unencrypted**. Crypto support is left out on purpose.
- Slot switching from the TWRP reboot menu may not work (AOSP boot HAL, not Qualcomm's).
- No fastbootd, no NTFS/exFAT. Add them after the basics boot.

## One-time setup (in WSL)

```
# copies the stock dtb and first-stage fstab out of your unpacked vendor_boot
bash scripts/prepare_inputs.sh ~/mkbootimg
git add -A
git commit -m "Add stock dtb and first-stage fstab"
git push
```

Note: the vendor_boot you unpacked is the one currently flashed, which is
LineageOS's (it contains Lineage's recovery). The DTB and first-stage fstab come
from it, which is what you want: they are what boots your phone today.

The fstab matters for **normal boots**, not just recovery: vendor_boot is shared,
and first-stage init reads `first_stage_ramdisk/system/etc/fstab.qcom` to mount
system and vendor.

## Build

GitHub: Actions -> "Build TWRP vendor_boot" -> Run workflow. Takes roughly an
hour. Download the `twrp-dre-vendor_boot` artifact. The workflow runs
`scripts/verify_vendor_boot.sh` and fails if the image would obviously break a
normal boot. If a build fails, download the `build-logs` artifact (`error.log`).

## Testing safely (A/B)

1. Back up both slots first: `dd if=/dev/block/by-name/vendor_boot_a of=/sdcard/vendor_boot_a.img`, same for `_b`.
2. Flash only the **inactive** slot: `fastboot flash vendor_boot_b vendor_boot.img`, then `fastboot --set-active=b`.
3. Boot normally and confirm Android still comes up (proves the first-stage fstab is right).
4. `adb reboot recovery` to get TWRP.
5. If anything goes wrong: `fastboot --set-active=a`.

Use the same vbmeta handling you already use for your custom boot image.
