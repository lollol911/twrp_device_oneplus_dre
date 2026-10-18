# Inherit from the AOSP base config and the TWRP vendor config
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, vendor/twrp/config/common.mk)

# Device config
$(call inherit-product, device/oneplus/dre/device.mk)

PRODUCT_DEVICE := dre
PRODUCT_NAME := twrp_dre
PRODUCT_BRAND := OnePlus
PRODUCT_MODEL := OnePlus Nord N200 5G
PRODUCT_MANUFACTURER := OnePlus
PRODUCT_RELEASE_NAME := OnePlus Nord N200 5G
