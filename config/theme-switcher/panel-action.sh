#!/bin/bash
# Acciones del panel lateral

action="${1:-}"
value="${2:-}"

case "$action" in
    volume-up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
    volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute)        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    volume)      wpctl set-volume @DEFAULT_AUDIO_SINK@ "$((value))%" ;;
    bright-up)   brightnessctl set 5%+ ;;
    bright-down) brightnessctl set 5%- ;;
    brightness)  brightnessctl set "$((value))%" ;;
    wifi-toggle)
        if [[ "$(nmcli -t -f WIFI g)" == "enabled" ]]; then
            nmcli radio wifi off
        else
            nmcli radio wifi on
        fi
        ;;
    bt-toggle)
        if bluetoothctl show | grep -q "Powered: yes"; then
            bluetoothctl power off
        else
            bluetoothctl power on
        fi
        ;;
    theme)
        "$HOME/.config/theme-switcher/theme-apply.sh" "$value" &
        ;;
    profile-cycle)
        cur=$(powerprofilesctl get 2>/dev/null)
        case "$cur" in
            performance) next=balanced ;;
            balanced)    next=power-saver ;;
            *)           next=performance ;;
        esac
        powerprofilesctl set "$next" >/dev/null 2>&1 || true
        ;;
    suspend)  systemctl suspend ;;
    logout)   hyprctl dispatch exit ;;
    reboot)   systemctl reboot ;;
    poweroff) systemctl poweroff ;;
esac
