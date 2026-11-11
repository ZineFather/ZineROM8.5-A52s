if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "37" ]; then
# See module.prop. Only the Samsung software Codec2 policy needs the change; the QTI codec2 policy already has the rule.
POL="$WORK_DIR/vendor/etc/seccomp_policy/samsung.software.media.c2-base-policy"
RULE="mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE"
[ -f "$POL" ] || ABORT "seccomp: ${POL//$WORK_DIR/} not found"
if grep -q "^mremap: arg3 == 3$" "$POL"; then
    LOG "- Allowing mremap(MREMAP_MAYMOVE) in /vendor/etc/seccomp_policy/$(basename "$POL")"
    EVAL "sed -i 's/^mremap: arg3 == 3$/$RULE/' \"$POL\""
fi
grep -qxF "$RULE" "$POL" || ABORT "seccomp: Samsung Codec2 mremap rule not found"
QTI="$WORK_DIR/vendor/etc/seccomp_policy/codec2.vendor.base-arm.policy"
grep -qxF "$RULE" "$QTI" || ABORT "seccomp: QTI Codec2 policy no longer has the stock mremap rule"
unset POL RULE QTI
else
    LOG "- Keeping the target seccomp policy unchanged for the Android 16 donor"
fi
