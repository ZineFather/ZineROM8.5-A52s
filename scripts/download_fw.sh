#!/usr/bin/env bash
# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/firmware_utils.sh" || exit 1
source "$TOOLS_DIR/venv/bin/activate" || exit 1

FORCE=false

FIRMWARES=()
FIRMWARE_VERSIONS=()
MODEL=""
CSC=""
IMEI=""
SERIAL_NO=""
LATEST_FIRMWARE=""
SELECTED_FIRMWARE=""
ZIP_FILE=""

PREPARE_SCRIPT()
{
    local EXTRA_FIRMWARES=()
    local IGNORE_SOURCE=false
    local IGNORE_TARGET=false

    while [ "$#" != 0 ]; do
        if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
            FORCE=true
        elif [[ "$1" == "--ignore-source" ]]; then
            IGNORE_SOURCE=true
        elif [[ "$1" == "--ignore-target" ]]; then
            IGNORE_TARGET=true
        elif [[ "$1" == "-"* ]]; then
            LOGE "Unknown option: $1"
            PRINT_USAGE
            exit 1
        else
            EXTRA_FIRMWARES+=("$1")
        fi

        shift
    done

    if ! $IGNORE_SOURCE; then
        _CHECK_NON_EMPTY_PARAM "SOURCE_FIRMWARE" "$SOURCE_FIRMWARE" || exit 1
        FIRMWARES+=("$SOURCE_FIRMWARE")
        FIRMWARE_VERSIONS+=("${SOURCE_FIRMWARE_VERSION:-}")
        IFS=':' read -r -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
        if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${SOURCE_EXTRA_FIRMWARES[@]}")
            for _ in "${SOURCE_EXTRA_FIRMWARES[@]}"; do FIRMWARE_VERSIONS+=(""); done
        fi
    fi

    if ! $IGNORE_TARGET; then
        _CHECK_NON_EMPTY_PARAM "TARGET_FIRMWARE" "$TARGET_FIRMWARE" || exit 1
        FIRMWARES+=("$TARGET_FIRMWARE")
        FIRMWARE_VERSIONS+=("${TARGET_FIRMWARE_VERSION:-}")
        IFS=':' read -r -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
        if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${TARGET_EXTRA_FIRMWARES[@]}")
            for _ in "${TARGET_EXTRA_FIRMWARES[@]}"; do FIRMWARE_VERSIONS+=(""); done
        fi
    fi

    if [ "${#EXTRA_FIRMWARES[@]}" -ge 1 ]; then
        FIRMWARES+=("${EXTRA_FIRMWARES[@]}")
        for _ in "${EXTRA_FIRMWARES[@]}"; do FIRMWARE_VERSIONS+=(""); done
    fi
}

PRINT_USAGE()
{
    echo "Usage: download_fw [options] <firmware>" >&2
    echo " --ignore-source : Skip parsing source firmware flags" >&2
    echo " --ignore-target : Skip parsing target firmware flags" >&2
    echo " -f, --force : Force firmware download" >&2
}

VERIFY_ODIN_PACKAGES()
{
    local FILE_NAME
    local LENGTH
    local STORED_HASH
    local CALCULATED_HASH

    while IFS= read -r f; do
        FILE_NAME="$(basename "$f")"
        LOG_STEP_IN "- Verifying $FILE_NAME..."

        FILE_NAME="${FILE_NAME%.md5}"

        # Samsung stores the output of `md5sum` at the very end of the file
        LENGTH="32" # Length of MD5 hash
        LENGTH="$((LENGTH + 2))" # 2 whitespace chars
        LENGTH="$((LENGTH + ${#FILE_NAME}))" # File name without .md5 extension
        LENGTH="$((LENGTH + 1))" # 1 newline char

        STORED_HASH="$(tail -c "$LENGTH" "$f" | cut -d " " -f 1 -s)"
        if [ ! "$STORED_HASH" ] || [[ "${#STORED_HASH}" != "32" ]]; then
            LOG "\033[0;31m! Expected hash could not be parsed\033[0m"
            exit 1
        fi

        CALCULATED_HASH="$(head -c-$LENGTH "$f" | md5sum | cut -d " " -f 1 -s)"

        if [[ "$STORED_HASH" != "$CALCULATED_HASH" ]]; then
            LOG "\033[0;31m! File is damaged\033[0m"
            exit 1
        fi

        LOG_STEP_OUT
    done < <(find "$ODIN_DIR/${MODEL}_${CSC}" -type f -name "*.md5")
}
# ]

PREPARE_SCRIPT "$@"

FIRMWARE_INDEX=0
for i in "${FIRMWARES[@]}"; do
    FIRMWARE_VERSION="${FIRMWARE_VERSIONS[$FIRMWARE_INDEX]:-}"
    FIRMWARE_INDEX=$((FIRMWARE_INDEX + 1))
    [[ "$FIRMWARE_VERSION" == "none" ]] && FIRMWARE_VERSION=""
    PARSE_FIRMWARE_STRING "$i" || exit 1

    if [ "$FIRMWARE_VERSION" ]; then
        IFS='/' read -r -a VERSION_PARTS <<< "$FIRMWARE_VERSION"
        MODEL_CODE="${MODEL#SM-}"
        if [ "${#VERSION_PARTS[@]}" -ne 4 ] || \
                [[ "${VERSION_PARTS[0]}" != "$MODEL_CODE"* ]] || \
                [[ "${VERSION_PARTS[1]}" != "$MODEL_CODE"* ]] || \
                [[ "${VERSION_PARTS[2]}" != "$MODEL_CODE"* ]] || \
                [[ "${VERSION_PARTS[3]}" != "$MODEL_CODE"* ]]; then
            LOGE "Pinned firmware version must be an AP/CSC/CP/BL tuple for $MODEL: $FIRMWARE_VERSION"
            exit 1
        fi
        SELECTED_FIRMWARE="$FIRMWARE_VERSION"
        LATEST_FIRMWARE="pinned: $SELECTED_FIRMWARE"
    else
        LATEST_FIRMWARE="$(GET_LATEST_FIRMWARE "$MODEL" "$CSC")"
        if [ ! "$LATEST_FIRMWARE" ]; then
            LOGE "Latest available firmware could not be fetched"
            exit 1
        fi
        SELECTED_FIRMWARE="$LATEST_FIRMWARE"
    fi

    LOG_STEP_IN "- Processing $MODEL firmware with $CSC CSC"
    LOG "- Downloaded firmware: $(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" 2> /dev/null)"
    LOG "- Extracted firmware: $(cat "$FW_DIR/${MODEL}_${CSC}/.extracted" 2> /dev/null)"
    LOG "- Requested firmware: $SELECTED_FIRMWARE"

    LOG_STEP_IN

    if ! $FORCE; then
        # A pinned donor is usable only when its extracted marker matches exactly.
        if [ -f "$FW_DIR/${MODEL}_${CSC}/.extracted" ]; then
            EXTRACTED_FIRMWARE="$(cat "$FW_DIR/${MODEL}_${CSC}/.extracted")"
            if [ "$FIRMWARE_VERSION" ]; then
                if [[ "$EXTRACTED_FIRMWARE" == "$SELECTED_FIRMWARE" ]]; then
                    LOG "\033[0;33m! The pinned firmware has already been extracted, skipping\033[0m"
                    LOG_STEP_OUT; LOG_STEP_OUT
                    continue
                fi
                LOG "- Cached extraction differs from the pinned firmware; replacing it"
            elif COMPARE_SEC_BUILD_VERSION "$EXTRACTED_FIRMWARE" "$LATEST_FIRMWARE"; then
                LOG "\033[0;33m! This firmware has already been extracted, skipping\033[0m"
                LOG_STEP_OUT; LOG_STEP_OUT
                continue
            fi
        fi

        # Skip only an exact cached package for pinned builds; never treat a newer Android17 cache as the donor.
        if [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ]; then
            DOWNLOADED_FIRMWARE="$(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded")"
            if [ "$FIRMWARE_VERSION" ]; then
                if [[ "$DOWNLOADED_FIRMWARE" == "$SELECTED_FIRMWARE" ]] && \
                        find "$ODIN_DIR/${MODEL}_${CSC}" -type f -name '*.md5' -print -quit | grep -q .; then
                    LOG "\033[0;33m! The pinned firmware has already been downloaded, skipping\033[0m"
                    LOG_STEP_OUT; LOG_STEP_OUT
                    continue
                fi
                LOG "- Cached download differs from the pinned firmware; replacing it"
                rm -rf "$ODIN_DIR/${MODEL}_${CSC}"
            elif COMPARE_SEC_BUILD_VERSION "$DOWNLOADED_FIRMWARE" "$LATEST_FIRMWARE"; then
                LOG "\033[0;33m! This firmware has already been downloaded, skipping\033[0m"
                LOG_STEP_OUT; LOG_STEP_OUT
                continue
            else
                LOG "\033[0;33m! A newer firmware is available for download; replacing the cached older build\033[0m"
            fi
        fi
    fi

    LOG "- Downloading firmware..."
    [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ] && rm -rf "$ODIN_DIR/${MODEL}_${CSC}"
    mkdir -p "$ODIN_DIR/${MODEL}_${CSC}"
    # Anan's samloader stores its logs in the current working directory, let's move into OUT_DIR just for this time
    (
    cd "$OUT_DIR" || exit 1
    if [ "$FIRMWARE_VERSION" ]; then
        samloader -m "$MODEL" -r "$CSC" -i "$IMEI" -s "$SERIAL_NO" download -v "$SELECTED_FIRMWARE" -O "$ODIN_DIR/${MODEL}_${CSC}" 1> /dev/null || exit 1
    else
        samloader -m "$MODEL" -r "$CSC" -i "$IMEI" -s "$SERIAL_NO" download -O "$ODIN_DIR/${MODEL}_${CSC}" 1> /dev/null || exit 1
    fi
    )

    ZIP_FILE="$(find "$ODIN_DIR/${MODEL}_${CSC}" -name "*.zip" | sort -r | head -n 1)"
    if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
        LOG "\033[0;31m! Download failed\033[0m"
        exit 1
    fi

    LOG "- Extracting $(basename "$ZIP_FILE")..."
    EVAL "unzip -o \"$ZIP_FILE\" -d \"$ODIN_DIR/${MODEL}_${CSC}\" && rm -rf \"$ZIP_FILE\"" || exit 1

    VERIFY_ODIN_PACKAGES

    echo -n "$SELECTED_FIRMWARE" > "$ODIN_DIR/${MODEL}_${CSC}/.downloaded"

    LOG_STEP_OUT; LOG_STEP_OUT
done

deactivate

exit 0
