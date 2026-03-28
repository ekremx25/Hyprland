#!/bin/bash

# Applies monitor settings from monitor_config.json

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_FILE="$CONFIG_HOME/quickshell/monitor_config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    exit 0
fi

# Determine compositor
IS_HYPRLAND=0
IS_NIRI=0
IS_MANGO=0

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    IS_HYPRLAND=1
elif [ -n "$NIRI_SOCKET" ]; then
    IS_NIRI=1
elif command -v mmsg >/dev/null 2>&1; then
    IS_MANGO=1
fi

if [ $IS_HYPRLAND -eq 0 ] && [ $IS_NIRI -eq 0 ] && [ $IS_MANGO -eq 0 ]; then
    exit 0
fi

# Read keys from JSON using jq
MONITORS=$(jq -r 'keys[]' "$CONFIG_FILE" 2>/dev/null)
DEFAULT_MONITOR=$(jq -r 'to_entries[] | select(.value.default == true) | .key' "$CONFIG_FILE" 2>/dev/null | head -n1)

if [ $IS_HYPRLAND -eq 1 ]; then
    CONNECTED_MONITORS=$(hyprctl monitors all -j 2>/dev/null | jq -r '.[].name' 2>/dev/null)
fi

while IFS= read -r MON; do
    [ -n "$MON" ] || continue

    RES=$(jq -r --arg mon "$MON" '.[$mon].res' "$CONFIG_FILE")
    HZ=$(jq -r --arg mon "$MON" '.[$mon].hz' "$CONFIG_FILE")
    SCALE=$(jq -r --arg mon "$MON" '.[$mon].scale' "$CONFIG_FILE")
    POS_X=$(jq -r --arg mon "$MON" '.[$mon].posX' "$CONFIG_FILE")
    POS_Y=$(jq -r --arg mon "$MON" '.[$mon].posY' "$CONFIG_FILE")

    if [ "$RES" != "null" ] && [ "$HZ" != "null" ] && [ "$SCALE" != "null" ] && [ "$RES" != "0x0" ]; then
        if [ $IS_HYPRLAND -eq 1 ]; then
            if ! printf '%s\n' "$CONNECTED_MONITORS" | grep -Fxq "$MON"; then
                continue
            fi
            # hyprctl keyword monitor name,res@hz,XxY,scale[,extra_params]
            HDR=$(jq -r --arg mon "$MON" '.[$mon].hdr // false' "$CONFIG_FILE")
            BITDEPTH=$(jq -r --arg mon "$MON" '.[$mon].bitdepth // 8' "$CONFIG_FILE")
            VRR=$(jq -r --arg mon "$MON" '.[$mon].vrr // 0' "$CONFIG_FILE")
            SDR_BRI=$(jq -r --arg mon "$MON" '.[$mon].sdrBrightness // 1.0' "$CONFIG_FILE")
            SDR_SAT=$(jq -r --arg mon "$MON" '.[$mon].sdrSaturation // 1.0' "$CONFIG_FILE")
            COLOR_MGMT=$(jq -r --arg mon "$MON" '.[$mon].colorManagement // "srgb"' "$CONFIG_FILE")

            MON_CMD="$MON,$RES@$HZ,${POS_X}x${POS_Y},$SCALE,bitdepth,$BITDEPTH,vrr,$VRR"
            if [ "$HDR" = "true" ] || [[ "$COLOR_MGMT" =~ ^hdr ]]; then
                if [ "$COLOR_MGMT" = "hdredid" ]; then
                    APPLIED_CM="hdredid"
                else
                    APPLIED_CM="hdr"
                fi
                MON_CMD="$MON_CMD,cm,$APPLIED_CM,sdrbrightness,$SDR_BRI,sdrsaturation,$SDR_SAT"
            elif [ "$COLOR_MGMT" != "default" ] && [ "$COLOR_MGMT" != "srgb" ] && [ "$COLOR_MGMT" != "null" ]; then
                MON_CMD="$MON_CMD,cm,$COLOR_MGMT"
            fi
            hyprctl keyword monitor "$MON_CMD"
        elif [ $IS_NIRI -eq 1 ]; then
            if [ "$POS_X" != "null" ] && [ "$POS_Y" != "null" ]; then
                wlr-randr --output "$MON" --mode "${RES}@${HZ}Hz" --scale "$SCALE" --pos "${POS_X},${POS_Y}"
            else
                wlr-randr --output "$MON" --mode "${RES}@${HZ}Hz" --scale "$SCALE"
            fi
        fi
    fi
done <<< "$MONITORS"

if [ $IS_HYPRLAND -eq 1 ] && [ -n "$DEFAULT_MONITOR" ] && [ "$DEFAULT_MONITOR" != "null" ]; then
    hyprctl dispatch focusmonitor "$DEFAULT_MONITOR" >/dev/null 2>&1
fi
