#!/bin/bash
if pgrep -x "spotify" > /dev/null
then
    playerctl -p spotify pause
else
    spotify &
fi
