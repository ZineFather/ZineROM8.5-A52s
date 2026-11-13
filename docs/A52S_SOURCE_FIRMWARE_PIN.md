# ZineUI 8.5 — Galaxy A52s Source Firmware Pin

## Target and donor

- Target: Galaxy A52s 5G, `a52sxq` / `SM-A528B`.
- Donor: Galaxy S26 Ultra, `SM-S948B`, CSC `EUX`.
- Firmware build: Android 16, One UI 8.5, binary 4.
- Pinned Samsung FUS version, in AP/CSC/CP/BL order:

  ```text
  S948BXXS4AZHL/S948BOXM4AZHL/CP36080667/S948BXXS4AZHL
  ```

The AP, CSC, Android/One UI version, binary, build date, security patch level and child-package filenames are listed on the [SamFw firmware record](https://samfw.com/firmware/SM-S948B/EUX/S948BXXS4AZHL). Its CP package is named `CP_S948BXXS4AZHL_CP36080667_...tar.md5.zip`; therefore CP validation must not require the device model prefix. Samloader documents the four-part slash-separated version passed to `download -v` in its [README](https://github.com/samloader/samloader).

## Configuration invariants

- `SOURCE_PLATFORM_SDK_VERSION=36` denotes Android 16's SDK/API level.
- `SOURCE_PRODUCT_SHIPPING_API_LEVEL=36` reflects the donor's initial shipping release.
- `SOURCE_BOARD_API_LEVEL=202504` is date-formatted and is not the SDK level. Android documents `ro.board.api_level` separately from the platform SDK in its [API flags documentation](https://source.android.com/docs/core/architecture/api-flags). Confirm the exact donor property against the extracted image before publishing a flashable release.
- The A52s config generator rejects a different donor tuple or changed Android major SDK so a later FUS update cannot silently switch the port to another base.
- The shared tuple validator accepts the Samsung CP forms observed in firmware records: a model-prefixed CP version or a `CP`-prefixed modem build identifier. It rejects wrong-model AP/CSC/BL components and malformed tuples.

Run the no-download regression checks with:

```bash
bash scripts/tests/firmware_version_test.sh
```

## Build and release caveats

The firmware record lists the full package at 22.52 GB. A runner needs additional temporary disk for extracted tar files, dynamic partitions and build outputs. The manual A52s build workflow cleans the hosted runner, verifies a 28 GiB free-space minimum, and builds only `a52sxq`; the push/PR CI workflow runs static checks only and never compiles or downloads a ROM.

The repository is public, so the build workflow deliberately suppresses flashable-ROM artifact upload. The repository must be private for the workflow to expose a downloadable artifact. GitHub also requires a `workflow_dispatch` file to exist on the repository's default branch before the manual action appears.

A source record and static validation do not prove a ROM compiles or boots. A successful fresh `Build ZineUI 8.5 (Galaxy A52s)` Actions run and an on-device boot to the animation remain required verification gates.
