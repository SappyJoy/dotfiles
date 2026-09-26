#!/bin/sh

rofi_command="rofi -theme ~/.config/rofi/powermenu.rasi"

# Options
shutdown=" Shutdown"
reboot=" Reboot"
lock=" Lock"
suspend="鈴 Suspend"
logout=" Logout"

# Variable passed to rofi
options="$shutdown\n$reboot\n$lock\n$suspend\n$logout"

chosen="$(echo -e "$options" | $rofi_command -p "Power" -dmenu -selected-row 2)"
case $chosen in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    $lock)
        ~/.config/i3/lock
        ;;
    $suspend)
        systemctl suspend
        ;;
    $logout)
        i3-msg exit
        ;;
esac
