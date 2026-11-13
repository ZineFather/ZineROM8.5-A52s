# ZineUI 8.5 — Galaxy A52s 5G

![ZineUI blue Z mark](readme-res/banner.png)

**Device:** Samsung Galaxy A52s 5G (`a52sxq`, `SM-A528B`, Snapdragon 778G / SM7325)<br>
**Maintainer:** `@ZineFather`<br>
**Engine:** `ZineROM Engine`<br>
**System donor:** Galaxy S26 Ultra (`SM-S948B`, EUX)<br>
**Android base:** One UI 8.5 / Android 16 (platform SDK 36)

> [!WARNING]
> This is an Android 16 bring-up branch. The donor migration and build-pipeline changes have **not yet been verified by a complete GitHub Actions build or on-device boot test**. It is not a flashable or daily-driver release. Do not flash until the build succeeds, patch anchors and donor-derived feature values have been audited, and boot/functional testing has passed.

## Firmware and device compatibility

The source firmware is pinned to a normalized AP/CSC/CP/BL tuple so a later firmware release cannot silently change the build base:

- AP: `S948BXXS4AZHL`
- CSC: `S948BOXM4AZHL`
- CP: `CP36080667`
- BL: `S948BXXS4AZHL`

The port config pins platform SDK 36 and a date-based board API value of `202504`; verify the donor's actual `ro.board.api_level` against the extracted image before release. The target remains the Galaxy A52s and retains its own SM7325/Android 14 vendor and BIT 5 boot-firmware requirements. The S26 Ultra is a framework/system donor, **not** a same-SoC donor. Qualcomm/SM7325-specific libraries and existing A52s kernel, thermal, battery, performance, camera and stability adaptations must remain on compatible A52s/A73-family paths rather than being replaced with S26 Ultra hardware blobs.

The A52s device-side base requires the appropriate `SM-A528B` BIT 5 firmware, an unlocked bootloader and compatible recovery. The donor image is a build input; it is not a firmware package to flash onto the A52s.

## Build on GitHub Actions

The full build is intentionally manual and is not part of the push/PR checks. The quick CI workflow runs static validation only; it does not download firmware or compile a ROM.

1. Use the `manus/zinerom85-phase2` branch containing this workflow and target configuration.
2. In GitHub, open **Actions → Build ZineUI 8.5 (Galaxy A52s)** and select **Run workflow**.
3. The workflow checks out with shallow history, frees runner disk space, builds dependencies, downloads and validates the pinned firmware, extracts it, then builds the ROM. It does not run a full build in the developer sandbox.
4. ROM artifacts are uploaded only if the repository is private. Upload is deliberately suppressed for public repositories because the flashable package contains firmware-derived proprietary files.

GitHub only exposes `workflow_dispatch` after the workflow file is present on the repository's default branch. If the action is not listed, merge this branch's workflow into the intended default branch first. A successful compile alone is not evidence of bootability.

## Port status and preserved work

This fork keeps the A52s target configuration and its existing device-specific kernel/vendor hooks, camera fixes, CSC/floating-feature overrides, thermal settings, performance tuning and battery adaptations. Their behavior against the Android 16 donor remains subject to build and device testing.

The source feature constants inherited from the S26 Ultra port are marked for re-audit against the pinned Android 16 image. Before release, review patch anchors, SELinux policy, camera/fingerprint, telephony/radio, audio, thermal behavior and sustained-load stability on the target. The current goal is to reach the boot animation; Setup Wizard and full feature parity are later milestones.

## Project background and credits

ZineUI is an unofficial community port based on the [UN1CA](https://github.com/salvogiangri/UN1CA) build system and patches, with inherited One UI porting work from [MonsterROM](https://github.com/devcore94/MonsterROM). It is not affiliated with or endorsed by those projects. Preserve upstream authors' credits and applicable licenses when redistributing, and report ZineUI-specific issues to this repository.

Legacy `unica` package/resource names and `k4` property identifiers remain where required for Settings, updater and build-system compatibility. They are internal compatibility details; the visible ROM identity is **ZineUI 8.5**.

## Licensing

This project remains under the [GNU General Public License v3.0](LICENSE). External dependencies may use separate licenses; see the upstream project and each dependency's license notices.
