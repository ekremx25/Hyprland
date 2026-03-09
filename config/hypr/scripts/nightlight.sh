#!/bin/bash
while true; do
    hour=$(date +%H:%M)
    if [[ "$hour" > "19:00" || "$hour" < "06:00" ]]; then
        gammastep -O 4500 -m wayland
    else
        gammastep -O 5500 -m wayland
    fi
    sleep 60
done
