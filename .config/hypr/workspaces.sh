#!/bin/env bash
MAIN=$1
SUPPORT=1$1
CUR_MONITOR=$(hyprctl monitors -j | jq -r ".[]|select(.focused).name");
echo "Moving workspace $MAIN to DP-1 and $SUPPORT to HDMI-A-1" >> /tmp/hypr.log
hyprctl --batch "dispatch workspace $SUPPORT ; dispatch workspace $MAIN ; dispatch focusmonitor $CUR_MONITOR"
#hyprctl dispatch workspace $SUPPORT && hyprctl dispatch workspace $MAIN
#hyprctl dispatch workspace HDMI-A-1~$SUPPORT
#hyprctl dispatch moveworkspacetomonitor $MAIN DP-1
#hyprctl dispatch moveworkspacetomonitor $SUPPORT HDMI-A-1
