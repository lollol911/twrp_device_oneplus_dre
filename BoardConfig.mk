#
# TWRP BoardConfig for the OnePlus Nord N200 5G (dre, SM4350 / holi)
#
# Recovery lives in vendor_boot (boot header v3, no recovery partition), so the
# deliverable is vendor_boot.img (make vendorbootimage), NOT recovery.img.
# The kernel is NOT part of vendor_boot: in recovery the phone runs the kernel
# from the same slot's boot partition (your own build).
#

DEVICE_PATH := device/oneplus/dre

# A/B + dynamic partitions + virtual A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo385

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := kryo385

# Platform
TARGET_BOARD_PLATFORM := holi
TARGET_BOOTLOADER_BOARD_NAME := holi
TARGET_NO_BOOTLOADER := true
BOARD_USES_QCOM_HARDWARE := true

# Boot image: header v3. These values and the cmdline are the ones found in the
# vendor_boot currently on the phone (checked with unpack_bootimg).
BOARD_BOOT_HEADER_VERSION := 3
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_CMDLINE := \
    androidboot.hardware=qcom \
    androidboot.memcg=1 \
    androidboot.usbcontroller=4e00000.dwc3 \
    cgroup.memory=nokmem,nosocket \
    loop.max_part=7 \
    lpm_levels.sleep_disabled=1 \
    msm_rtb.filter=0x237 \
    reboot=panic_warm \
    service_locator.enable=1 \
    swiotlb=0 \
    iptable_raw.raw_before_defrag=1 \
    ip6table_raw.raw_before_defrag=1
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_RAMDISK_USE_LZ4 := true

# The DTB blob from the current vendor_boot, copied byte for byte by scripts/prepare_inputs.sh.
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb

# Recovery resources go into the vendor_boot ramdisk (same layout as stock).
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296

# Not used by vendorbootimage; the workflow creates an empty placeholder file
# so nothing in the build system trips over a missing path.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel

# AVB: vendor_boot is built WITHOUT an AVB footer (BOARD_AVB_ENABLE is not set).
# Flash it with the same vbmeta handling you already use for your custom boot.img.

# Partitions. Super is 6442450944 bytes on this device (blockdev --getsize64).
BOARD_SUPER_PARTITION_SIZE := 6442450944
BOARD_SUPER_PARTITION_GROUPS := oneplus_dynamic_partitions
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_ext vendor vendor_dlkm
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := 3217031168
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_USES_METADATA_PARTITION := true
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs

# Filesystems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
BOARD_HAS_NO_SELECT_BUTTON := true
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_QCOM_RTC_FIX := true

# TWRP
TW_DEVICE_VERSION := 0
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_LANGUAGE := en
TW_HAS_NO_RECOVERY_PARTITION := true
TW_USE_TOOLBOX := true

# /data is unencrypted on this phone right now, so crypto support is left out of
# the first build. The vendor fstab still lists fileencryption/metadata_encryption
# with wrapped keys: if encryption is ever re-enabled this recovery cannot read /data.
TW_INCLUDE_CRYPTO := false

# Screen (backlight max_brightness is 4095 on both backlight nodes)
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 4095
TW_DEFAULT_BRIGHTNESS := 1200

# Debugging (adb logcat from recovery)
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true

# CPU temperature: thermal_zone0 on this kernel is a modem sensor with no reading (shows 0 C).
# thermal_zone36 is cpu-1-0-usr (checked from the thermal zone list in the recovery diagnostics).
# Zone numbers are fixed for a given kernel build; re-check with recovery_diag.sh if you change kernels.
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone36/temp"

# After the screen timeout TWRP blanks the panel and the touch controller (no-flash Novatek, needs its
# firmware reloaded on resume) stops answering. Never blank the panel: the lock screen still comes up
# but the display and touch stay alive. This is a workaround, not a fix for the kernel touch resume.
TW_NO_SCREEN_BLANK := true

# microSD formatted NTFS: the kernel has no NTFS driver, so use ntfs-3g (FUSE) from the TWRP manifest.
# exFAT and FAT32 cards already work through the kernel drivers.
TW_INCLUDE_NTFS_3G := true
