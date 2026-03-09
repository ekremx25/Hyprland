#!/bin/sh
swayidle -w \
               timeout 13 'swaylock -f & sleep 1' \
                timeout 15 'hyprctl dispatch dpms off' \
                    resume 'hyprctl dispatch dpms on' \
                timeout 20 'systemctl suspend'
