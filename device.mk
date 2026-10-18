LOCAL_PATH := device/oneplus/dre

# Dynamic partitions (super) and virtual A/B
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# A/B boot control (slot switching from the TWRP reboot menu).
# These are the AOSP implementations; if the stock slot handling turns out to
# need Qualcomm's own HAL, this is the place to change it.
PRODUCT_PACKAGES += \
    android.hardware.boot@1.1-impl \
    android.hardware.boot@1.1-impl.recovery \
    android.hardware.boot@1.1-service

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += bootctrl
