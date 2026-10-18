#!/usr/bin/env bash
# Copy the two files the cloud build needs out of the vendor_boot you already
# unpacked (the one currently on the phone, which is LineageOS's), into this
# repo. Run it once in WSL, then commit and push.
#
#   scripts/prepare_inputs.sh [dir containing vb/ and vr/]    (default: ~/mkbootimg)
#
# vb/dtb                                      -> prebuilt/dtb/dtb.dtb
# vr/first_stage_ramdisk/system/etc/fstab.qcom -> recovery/root/first_stage_ramdisk/system/etc/fstab.qcom
#
# The fstab matters for NORMAL boots too: vendor_boot is shared by Android and
# recovery, and first-stage init reads this file to mount system/vendor/etc.
set -euo pipefail

SRC="${1:-$HOME/mkbootimg}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DTB="$SRC/vb/dtb"
FSTAB="$SRC/vr/first_stage_ramdisk/system/etc/fstab.qcom"

die() { echo "error: $*" >&2; exit 1; }

[ -f "$DTB" ]   || die "missing $DTB (unpack the stock vendor_boot into $SRC/vb first)"
[ -e "$FSTAB" ] || die "missing $FSTAB (extract the vendor ramdisk into $SRC/vr first)"

mkdir -p "$REPO/prebuilt/dtb" "$REPO/recovery/root/first_stage_ramdisk/system/etc"

cp "$DTB" "$REPO/prebuilt/dtb/dtb.dtb"
# -L: the stock entry may be a symlink; we want the real file contents.
cp -L "$FSTAB" "$REPO/recovery/root/first_stage_ramdisk/system/etc/fstab.qcom" \
  || die "could not copy $FSTAB (broken symlink?)"

[ -s "$REPO/prebuilt/dtb/dtb.dtb" ] || die "dtb copy is empty"
[ -s "$REPO/recovery/root/first_stage_ramdisk/system/etc/fstab.qcom" ] || die "fstab copy is empty"

echo "dtb:   $(stat -c %s "$REPO/prebuilt/dtb/dtb.dtb") bytes (stock blob was 326026)"
echo "fstab: $(wc -l < "$REPO/recovery/root/first_stage_ramdisk/system/etc/fstab.qcom") lines"
echo
echo "Next: git add -A && git commit -m 'Add stock dtb and first-stage fstab' && git push"
