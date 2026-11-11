FINGERPRINT="$(GET_PROP "odm" "ro.odm.build.fingerprint")"
[ "$FINGERPRINT" ] || ABORT "ro.odm.build.fingerprint not found"
# brand/product/device:release/id/incremental:type/tags -> tag the incremental
FINGERPRINT="$(sed -E "s|^([^:]*:[^:]*):(.*)$|\1.k4$(date -u +%Y%m%d%H%M):\2|" <<< "$FINGERPRINT")"
SET_PROP "odm" "ro.odm.build.fingerprint" "$FINGERPRINT"
unset FINGERPRINT

# Human-readable ZineROM identity: target/a52sxq/version holds the One UI release version. Keep the legacy ro.k4.*
# keys because inherited Settings code reads them; their values display ZineROM to users.
K4_VERSION="$(tr -d '[:space:]' < "$SRC_DIR/target/$TARGET_CODENAME/version" 2> /dev/null)"
if [ "$K4_VERSION" ]; then
    K4_TAG="k4$(date -u +%Y%m%d%H%M)"
    # the de-Googled variant (target/a52sxq/patches/degoogle enabled) is marked in the version string
    [ -f "$SRC_DIR/target/$TARGET_CODENAME/patches/degoogle/disable" ] || K4_VERSION="${K4_VERSION}-degoogled"
    SET_PROP "system" "ro.k4.version" "$K4_VERSION"
    # ROM_VERSION is "<version>-<commit>[-dirty]" (unica/configs/version.sh): the Settings row shows the commit part
    SET_PROP "system" "ro.k4.commit" "${ROM_VERSION#*-}"
    # shown by the Settings "ROM version" row (settings mod ROMVersionPreferenceController)
    SET_PROP "system" "ro.k4.rom_name" "ZineROM One UI ${K4_VERSION} (Galaxy A52s 5G)"
    # the source defines ro.build.display.id in both system and product; init's merged map lets product win
    for part in system product; do
        SET_PROP "$part" "ro.build.display.id" "ZineROM_A52s_OneUI${K4_VERSION}.${K4_TAG} ($(GET_PROP "system" "ro.build.id"))"
    done
    unset part
fi
unset K4_VERSION K4_TAG
