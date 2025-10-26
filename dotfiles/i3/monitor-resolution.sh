#!/bin/bash

xev -root -event randr | grep --line-buffered "subtype XRROutputChangeNotifyEvent" | while read line; do
	xrandr --output $(xrandr | grep " connected" | cut -f1 -d " ") --auto
done
