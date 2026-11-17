#!/usr/bin/env bash
set -u

THEME="$HOME/.config/rofi/menu.rasi"

confirm() {
    printf 'No\nSí\n' | rofi -dmenu -i -no-custom -theme "$THEME" \
        -theme-str 'window { width: 420px; } listview { lines: 2; }' \
        -p "$1" | grep -qx 'Sí'
}

choice=$(printf '%s\n' \
    "󰐥  Apagar" \
    "󰜉  Reiniciar" \
    "󰤄  Suspender" \
    "󰌾  Bloquear" \
    "󰍃  Cerrar sesión" |
    rofi -dmenu -i -no-custom -theme "$THEME" \
        -theme-str 'window { width: 420px; } listview { lines: 5; }' \
        -p "Energía")

[[ -z ${choice:-} ]] && exit 0

case $choice in
    *Apagar) confirm "¿Apagar el equipo?" && systemctl poweroff ;;
    *Reiniciar) confirm "¿Reiniciar el equipo?" && systemctl reboot ;;
    *Suspender) systemctl suspend ;;
    *Bloquear) hyprlock ;;
    *"Cerrar sesión") confirm "¿Cerrar la sesión?" && hyprctl dispatch exit ;;
esac
