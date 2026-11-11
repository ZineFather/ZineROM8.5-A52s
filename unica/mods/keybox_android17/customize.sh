if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "37" ]; then
    APPLY_PATCH "system" "system/framework/framework.jar" \
        "$MODPATH/0001-Report-Android-17-OS-version-in-attestation.patch"
else
    LOG "- Skipping the Android 17 KeyMint attestation override on the Android 16 donor"
fi
