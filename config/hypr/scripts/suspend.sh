#!/bin/bash
LID_SWITCH=$(hyprctl devices | grep "Lid Switch" | awk '{print $NF}')
hyprctl bindl=,switch:on:$LID_SWITCH,exec,systemctl suspend
