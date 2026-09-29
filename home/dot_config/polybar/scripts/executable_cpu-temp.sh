#!/bin/sh
# CPU temperature for polybar: the first CPU sensor found (AMD k10temp or zenpower,
# Intel coretemp). Prints nothing where there is none, which hides the module.
for dir in /sys/class/hwmon/hwmon*; do
    case $(cat "$dir/name" 2>/dev/null) in
    k10temp | zenpower | coretemp)
        echo "$(($(cat "$dir/temp1_input") / 1000))°C"
        exit
        ;;
    esac
done
