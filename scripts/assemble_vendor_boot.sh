#!/usr/bin/env bash
# Fallback: rebuild vendor_boot.img by hand when the stock make rule produced an
# image whose ramdisk is empty (no TWRP, no first-stage fstab).
#
#   scripts/assemble_vendor_boot.sh <twrp tree dir>
#
# Run it AFTER `mka out/target/product/dre/ramdisk-recovery.img`, which makes the
# build populate out/target/product/dre/recovery/root. It then does exactly what
# the make rule does for BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT:
#
#   mkbootfs <vendor_ramdisk dir> <recovery root> | lz4 > vendor_ramdisk
#   mkbootimg <same header args as the image we already built> --vendor_ramdisk ...
#
# The header fields, cmdline and DTB are taken from the image the build already
# produced, so only the ramdisk changes. The result is written over
# out/target/product/dre/vendor_boot.img (the bad one is kept as .bad).
set -euo pipefail

TREE="$(cd "${1:?usage: $0 <twrp tree dir>}" && pwd)"
OUT="$TREE/out/target/product/dre"
IMG="$OUT/vendor_boot.img"
ROOT="$OUT/recovery/root"
VR="$OUT/vendor_ramdisk"
SYS="$OUT/system"
MKBOOTFS="${MKBOOTFS:-$TREE/out/host/linux-x86/bin/mkbootfs}"
MKBOOTIMG_DIR="$TREE/system/tools/mkbootimg"
MAX_SIZE=100663296

die() { echo "error: $*" >&2; exit 1; }

[ -f "$IMG" ]                       || die "$IMG not found"
[ -x "$MKBOOTFS" ]                  || die "mkbootfs not found at $MKBOOTFS"
[ -f "$MKBOOTIMG_DIR/mkbootimg.py" ] || die "mkbootimg.py not found in $MKBOOTIMG_DIR"
[ -d "$ROOT" ]                      || die "$ROOT does not exist: the recovery ramdisk was never staged"

n=$(find "$ROOT" -mindepth 1 | wc -l)
echo "recovery root has $n entries"
[ "$n" -gt 100 ] || die "recovery root only has $n entries; nothing sensible to assemble"
[ -e "$ROOT/system/bin/recovery" ] || die "$ROOT/system/bin/recovery is missing: the TWRP binary was not built"
[ -e "$ROOT/first_stage_ramdisk/system/etc/fstab.qcom" ] || die "first-stage fstab missing from the recovery root"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# 1. Header arguments from the image we already have (dtb, cmdline, offsets...).
python3 -I "$MKBOOTIMG_DIR/unpack_bootimg.py" --boot_img "$IMG" --out "$work/u" --format=mkbootimg > "$work/args.txt"

# 2. New ramdisk: vendor ramdisk dir (if any) + recovery root, lz4 legacy like Android.
dirs=()
[ -d "$VR" ] && dirs+=("$VR")
dirs+=("$ROOT")
"$MKBOOTFS" -d "$SYS" "${dirs[@]}" > "$work/ramdisk.cpio"
lz4 -l -9 -c "$work/ramdisk.cpio" > "$work/vendor_ramdisk.lz4"
echo "new ramdisk: $(stat -c %s "$work/ramdisk.cpio") bytes cpio, $(stat -c %s "$work/vendor_ramdisk.lz4") bytes lz4"

# 3. Swap the ramdisk path in the argument list and repack.
args="$(sed "s#--vendor_ramdisk [^ ]*#--vendor_ramdisk $work/vendor_ramdisk.lz4#" "$work/args.txt")"
grep -q -- "$work/vendor_ramdisk.lz4" <<<"$args" || die "could not substitute the vendor_ramdisk argument"
cp "$IMG" "$IMG.bad"
( cd "$MKBOOTIMG_DIR" && eval "python3 ./mkbootimg.py $args --vendor_boot '$work/new_vendor_boot.img'" )

size=$(stat -c %s "$work/new_vendor_boot.img")
[ "$size" -le "$MAX_SIZE" ] || die "new image is $size bytes, over the $MAX_SIZE partition"
cp "$work/new_vendor_boot.img" "$IMG"
echo "wrote $IMG ($size bytes); the earlier image is kept as $IMG.bad"
