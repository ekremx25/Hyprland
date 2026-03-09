#!/bin/bash
echo "Starting wlsunset at $(date)" >> ~/.config/hypr/logs/wlsunset.log
/usr/bin/wlsunset -l 41.0 -L 29.0 -t 4500 -T 5500 &
echo "wlsunset process started at $(date)" >> ~/.config/hypr/logs/wlsunset.log
