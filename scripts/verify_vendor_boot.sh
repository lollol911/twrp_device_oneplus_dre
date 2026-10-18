#!/usr/bin/env bash
# Sanity-check the freshly built vendor_boot.img before anyone flashes it.
#
#   scripts/verify_vendor_boot.sh <twrp tree dir> <device tree dir>
#
# Fails (non-zero exit) if the image would obviously break a normal boot or is
# not actually TWRP.
set -euo pipefail

TREE="${1:?usage: $0 <twrp tree dir> <device tree dir>}"
DEVTREE="${2:?usage: $0 <twrp tree dir> <device tree dir>}"

IMG="$TREE/out/target/product/dre/vendor_boot.img"
UNPACK="$TREE/system/tools/mkbootimg/unpack_bootimg.py"
MAX_SIZE=100663296

fail=0
bad() { echo "FAIL: $*"; fail=1; }
ok()  { echo "ok:   $*"; }

[ -f "$IMG" ]    || { echo "FAIL: $IMG not found"; exit 1; }
[ -f "$UNPACK" ] || { echo "FAIL: $UNPACK not found"; exit 1; }

size=$(stat -c %s "$IMG")
if [ "$size" -le "$MAX_SIZE" ]; then ok "size $size <= $MAX_SIZE"; else bad "size $size exceeds the partition ($MAX_SIZE)"; fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

python3 -I "$UNPACK" --boot_img "$IMG" --out "$work/u" --format=mkbootimg > "$work/args.txt"
echo "--- unpack_bootimg arguments ---"
cat "$work/args.txt"
echo "--------------------------------"

# Header and cmdline
grep -q -- '--header_version 3' "$work/args.txt" && ok "boot header v3" || bad "header is not v3"
for opt in androidboot.hardware=qcom androidboot.usbcontroller=4e00000.dwc3 swiotlb=0 reboot=panic_warm; do
  grep -q -- "$opt" "$work/args.txt" && ok "cmdline has $opt" || bad "cmdline is missing $opt"
done

# DTB must be the stock blob, byte for byte
if cmp -s "$work/u/dtb" "$DEVTREE/prebuilt/dtb/dtb.dtb"; then
  ok "dtb identical to prebuilt/dtb/dtb.dtb"
else
  bad "dtb in the image differs from prebuilt/dtb/dtb.dtb"
fi

# Ramdisk contents
rd="$work/u/vendor_ramdisk"
[ -f "$rd" ] || { echo "FAIL: no vendor_ramdisk extracted"; exit 1; }
if   lz4 -t "$rd" >/dev/null 2>&1; then dec=(lz4 -dc)
elif gzip -t "$rd" >/dev/null 2>&1; then dec=(gzip -dc)
else bad "vendor_ramdisk is neither lz4 nor gzip"; dec=(cat)
fi
"${dec[@]}" "$rd" | cpio -t 2>/dev/null | sed 's#^\./##' > "$work/files.txt" || true
n=$(wc -l < "$work/files.txt")
[ "$n" -gt 100 ] && ok "ramdisk lists $n entries" || bad "ramdisk has only $n entries"

grep -qx 'first_stage_ramdisk/system/etc/fstab.qcom' "$work/files.txt" \
  && ok "first_stage_ramdisk/system/etc/fstab.qcom present (needed for normal boot)" \
  || bad "first_stage_ramdisk/system/etc/fstab.qcom is MISSING: Android would not boot from this vendor_boot"

grep -qx 'init.recovery.qcom.rc' "$work/files.txt" \
  && ok "init.recovery.qcom.rc present (adb over configfs, /dev/block/bootdevice)" \
  || bad "init.recovery.qcom.rc is missing: no adb and the by-name paths in recovery.fstab would not resolve"

# MTP rules (init.recovery.qcom.rc) and the NTFS driver for the microSD
if "${dec[@]}" "$rd" | cpio -i --to-stdout '*init.recovery.qcom.rc' 2>/dev/null | grep -q 'ffs.mtp'; then
  ok "init.recovery.qcom.rc has the MTP gadget rules"
else
  bad "init.recovery.qcom.rc has no ffs.mtp rules: MTP would not work"
fi
grep -Eq '(^|/)(mount\.ntfs|ntfs-3g)$' "$work/files.txt" && ok "ntfs-3g present" || echo "WARN: no ntfs-3g in the ramdisk (NTFS microSD would not mount)"

grep -qx 'init' "$work/files.txt" && ok "/init present" || bad "/init missing"
grep -Eq '^(twres|system/etc/twrp\.flags|system/etc/recovery\.fstab)' "$work/files.txt" \
  && ok "TWRP resources/fstab present" || bad "no TWRP resources (twres/, twrp.flags) in the ramdisk"
grep -Eq '(^|/)recovery$' "$work/files.txt" && ok "recovery binary present" || bad "recovery binary missing"

if [ "$fail" -ne 0 ]; then
  echo
  echo "verification FAILED: do not flash this image"
  exit 1
fi
echo
echo "verification passed"
