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
normal boot. If the stock rule leaves the ramdisk empty, the workflow stages the recovery ramdisk and
assembles `vendor_boot.img` itself (`scripts/assemble_vendor_boot.sh`), then verifies again. If a build fails,
download the `build-logs` artifact (`diagnostics.txt`, `build.log.gz`, `error.log`).

## Testing safely (A/B)

**Slot rule.** TWRP maps the logical partitions (`system`, `vendor`, ...) of the slot it was booted from.
If your ROM is in slot a and TWRP is in slot b, every logical mount fails with "Invalid argument". Once
step 3 below proves the image boots Android, flash it to the slot your ROM actually lives in
(`fastboot getvar current-slot`, `lpdump` in TWRP shows which slot has valid partitions).

1. Back up both slots first: `dd if=/dev/block/by-name/vendor_boot_a of=/sdcard/vendor_boot_a.img`, same for `_b`.
2. Flash only the **inactive** slot: `fastboot flash vendor_boot_b vendor_boot.img`, then `fastboot --set-active=b`.
3. Boot normally and confirm Android still comes up (proves the first-stage fstab is right).
4. `adb reboot recovery` to get TWRP.
5. If anything goes wrong: `fastboot --set-active=a`.

Use the same vbmeta handling you already use for your custom boot image.

## Known behaviour

- Time zone: TWRP's built-in default is CST6CDT. Set Settings > Time Zone once (Arizona = MST7); it is saved.
- CPU temperature reads `thermal_zone36` (`TW_CUSTOM_CPU_TEMP_PATH`); zone numbers can change with a different kernel.
- MTP: `init.recovery.qcom.rc` adds the `ffs.mtp` function to the configfs gadget (TWRP only ships adb/fastboot).
- microSD: kernel has no NTFS driver, `TW_INCLUDE_NTFS_3G` adds ntfs-3g; exFAT/FAT32 mount natively.
- USB-OTG: the controller is forced to peripheral mode, so USB sticks do not mount.
- `TW_NO_SCREEN_BLANK` keeps the panel and touch alive after the timeout; it works around, not fixes, touch resume.
