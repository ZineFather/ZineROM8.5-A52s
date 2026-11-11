# ZineROM One UI 8.5 for Galaxy A52s 5G

**Target:** Samsung Galaxy A52s 5G (`a52sxq`, `SM-A528B`, Snapdragon 778G / SM7325)<br>
**System donor:** Galaxy S26 Ultra (`SM-S948B`, EUX), firmware `S948BXXS4AZHL / S948BOXM4AZHL / S948BXXS4AZHL / S948BXXS4AZHL`<br>
**Android base:** Android 16, platform SDK 36<br>
**Port lineage:** `seventeen-s26u` → ZineROM One UI 8.5 / Android 16

> [!WARNING]
> This branch contains the Android 16 donor migration and compatibility changes, but has **not yet been built against the pinned donor image or validated on an SM-A528B device**. Treat it as bring-up work, not a flashable or daily-driver release. Do not flash until the Android 16 source image has been extracted, all patch anchors and donor-derived feature values have been audited, and boot/functional testing has passed.

## Donor and device compatibility

The S26 Ultra EUX Android 16 image is selected as the system donor because it is the matching One UI 8.5 release lineage; the A52s remains the target device and retains its own SM7325/Android 14 vendor and BIT 5 boot-firmware requirements. The S26 Ultra is **not** a same-SoC donor. Qualcomm/SM7325-specific libraries and existing A52s kernel, thermal, battery, performance, and stability adaptations remain sourced from their compatible A52s/A73-family paths rather than being replaced by S26 Ultra hardware blobs.

The source firmware is deliberately pinned to this normalized AP/CSC/CP/BL tuple (samloader's four-part version format) so a later Android 17 FUS release cannot silently change the build base:

- AP: `S948BXXS4AZHL`
- CSC: `S948BOXM4AZHL`
- CP: `S948BXXS4AZHL`
- BL: `S948BXXS4AZHL`

References: [Samsung S26 Ultra update history](https://doc.samsungmobile.com/SM-S948B/ECT/doc.html), [Samsung One UI 8 / Android 16 information](https://www.samsung.com/latin_en/support/mobile-devices/one-ui-8-upgrade-with-android-16/), and [SamMobile's One UI 8.5 firmware report](https://www.sammobile.com/news/leaked-galaxy-s26-ultra-firmware-confirms-one-ui-8-5/).

The install target still requires the Galaxy A52s `A528BXXU5FWK4` BIT 5 firmware as its device-side base, an unlocked bootloader, and a compatible recovery. The donor image is a build input; it is not a firmware package to flash onto the A52s.

## Migration work in this branch

- Changes the configured S26 Ultra source from Android 17 / SDK 37 to the exact Android 16 / SDK 36 donor.
- Adds version-aware download, extraction, cache invalidation, and build checks so a previously cached Android 17 image cannot be reused as the Android 16 source.
- Keeps the Android 16 donor's own Tethering APEX and its version-matched loader/BPF programs; the checked-in Android 17 APEX and train artifacts are not applied on SDK 36.
- Gates Android 17-only native-zygote, property-context, legacy ueventd, seccomp, UDFPS HBM-layer, KeyMint attestation, and KnoxPatch changes by source SDK.
- Keeps the donor's matching `libhwui` instead of replacing it with an older One UI 8.0 build.
- Leaves the Android 16 donor's seamless-brightness defaults unchanged; the target-only threshold transition is deferred until its Android16 code path is source-audited.
- Retains A52s device configuration and the existing SM7325 thermal, battery, performance, and stability work. Those device-specific features still require Android 16 build and device testing.

The source feature constants inherited from the preceding S26 Ultra port remain marked for re-audit against the pinned Android 16 image. A successful compile alone is not sufficient: the patch set, SELinux policy, camera/fingerprint, telephony, radio, audio, thermal behavior, and sustained-load stability must be reviewed on the target before release.

## Project background and credits

ZineROM is an unofficial community port based on the [UN1CA](https://github.com/salvogiangri/UN1CA) build system and patches, with One UI 9 port work inherited from [MonsterROM](https://github.com/devcore94/MonsterROM). It is not affiliated with or endorsed by those projects; please report ZineROM issues to this repository rather than upstream. Preserve the original authors' credits and applicable licenses when redistributing.

The ROM retains upstream package names and internal `k4`/`unica` property identifiers where required for Settings, updater, and build-system compatibility; visible ROM identity is ZineROM.

## Features

The inherited build system provides Samsung One UI features and ROM-level options including live blur, AOD transitions, adaptive display controls, Galaxy AI components, CSC features, app downgrade controls, Play Integrity hooks, key-attestation options, privacy controls, and GPU driver selection. Availability and behavior on the migrated Android 16 A52s port are **unverified until device testing**.

## Licensing

This project remains under the [GNU General Public License v3.0](LICENSE). External dependencies may use separate licenses; see the upstream project and each dependency's license notices.
