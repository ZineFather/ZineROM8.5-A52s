#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/firmware_version.sh
source "$SCRIPT_DIR/../utils/firmware_version.sh"

CASES=0

assert_valid()
{
    local DESCRIPTION="$1"
    local MODEL="$2"
    local VERSION="$3"
    if ! VALIDATE_FIRMWARE_VERSION "$MODEL" "$VERSION"; then
        echo "FAIL: expected valid firmware tuple: $DESCRIPTION" >&2
        exit 1
    fi
    CASES=$((CASES + 1))
}

assert_invalid()
{
    local DESCRIPTION="$1"
    local MODEL="$2"
    local VERSION="$3"
    if VALIDATE_FIRMWARE_VERSION "$MODEL" "$VERSION"; then
        echo "FAIL: expected invalid firmware tuple: $DESCRIPTION" >&2
        exit 1
    fi
    CASES=$((CASES + 1))
}

assert_valid "verified S26 Ultra CP######## tuple" "SM-S948B" \
    "S948BXXS4AZHL/S948BOXM4AZHL/CP36080667/S948BXXS4AZHL"
assert_valid "model-prefixed CP tuple" "SM-A528B" \
    "A528BXXU1DWA4/A528BOXM1DWA4/A528BXXU1DWA4/A528BXXU1DWA4"
assert_invalid "missing BL component" "SM-S948B" \
    "S948BXXS4AZHL/S948BOXM4AZHL/CP36080667"
assert_invalid "extra tuple component" "SM-S948B" \
    "S948BXXS4AZHL/S948BOXM4AZHL/CP36080667/S948BXXS4AZHL/EXTRA"
assert_invalid "empty CSC component" "SM-S948B" \
    "S948BXXS4AZHL//CP36080667/S948BXXS4AZHL"
assert_invalid "wrong AP model" "SM-S948B" \
    "S938BXXS4AZHL/S948BOXM4AZHL/CP36080667/S948BXXS4AZHL"
assert_invalid "wrong CSC model" "SM-S948B" \
    "S948BXXS4AZHL/S938BOXM4AZHL/CP36080667/S948BXXS4AZHL"
assert_invalid "unrecognized CP component" "SM-S948B" \
    "S948BXXS4AZHL/S948BOXM4AZHL/MODEM/S948BXXS4AZHL"
assert_invalid "wrong BL model" "SM-S948B" \
    "S948BXXS4AZHL/S948BOXM4AZHL/CP36080667/S938BXXS4AZHL"
assert_invalid "empty model" "" \
    "S948BXXS4AZHL/S948BOXM4AZHL/CP36080667/S948BXXS4AZHL"

echo "PASS: $CASES firmware tuple validation cases"
