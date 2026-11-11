if [ "$SOURCE_PLATFORM_SDK_VERSION" -lt "37" ]; then
    LOG "- Android 16 uses the donor's stock Tethering loader/BPF set; skipping the Android 17 train checker"
else
# See module.prop. Runs after "tethering" (modules apply in C-locale name order), so a52_netd.o is already in place.
TT_NETD="$WORK_DIR/system/system/etc/bpf/a52_netd.o"
if [ ! -f "$TT_NETD" ]; then
    LOGW "tethering_trains: no system/etc/bpf/a52_netd.o (tethering patch disabled?) - skipped"
else
    if ${TARGET_TETHERING_RESIGN_APEX:-false}; then
        # Re-signed Tethering APEX: Play can never update it, only the factory userspace ever runs.
        TT_KNOWN=("$MODPATH"/known/*_factory_netd.o)   # (+ its *_factory_<obj>.o, found by check_netd.py)
    else
        TT_KNOWN=("$MODPATH"/known/*_netd.o)
    fi
    [ -f "${TT_KNOWN[0]}" ] || ABORT "tethering_trains: no known netd.o in $MODPATH/known"
    # (apply_modules.sh runs with set -e: keep the failing check inside an if)
    if TT_OUT="$(python3 "$MODPATH/check_netd.py" "$TT_NETD" "${TT_KNOWN[@]}" 2>&1)"; then TT_RC=0; else TT_RC=$?; fi
    while IFS= read -r l; do [ "$l" ] && LOG "- $l"; done <<< "$TT_OUT"
    [ "$TT_RC" = 0 ] || ABORT "tethering_trains: a52_netd.o or the frozen loader no longer covers a Tethering version phones may run (see above) - a52_netd.o map/program lines: rerun tethering/regen.py --train-progs with every train in known/; \"(load fails)\" lines: that train cannot load on 5.4 with our frozen loader (bpfloader reboot loop), fix the ROM side first; \"pin gap\" lines: review, then fix or add the printed line to known/tolerated.txt"
    python3 "$MODPATH/check_netd.py" --list "${TT_KNOWN[@]}" > "$WORK_DIR/system/system/etc/bpf/a52_netd.known" || \
        ABORT "tethering_trains: failed to write a52_netd.known"
    SET_METADATA "system" "system/etc/bpf/a52_netd.known" 0 0 644 "u:object_r:system_file:s0"
    unset TT_KNOWN TT_OUT TT_RC
fi
unset TT_NETD
fi
