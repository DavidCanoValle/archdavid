#!/bin/bash
set -u

THEME="$HOME/.config/rofi/menu.rasi"
IFACE="net.hadess.PowerProfiles"
OBJ="/net/hadess/PowerProfiles"

profile_id() {
    case "$1" in
        *Rendimiento) echo performance ;;
        *Equilibrado) echo balanced ;;
        *Ahorro*)     echo power-saver ;;
        *)            echo "" ;;
    esac
}

current=$(busctl --system get-property "$IFACE" "$OBJ" "$IFACE" ActiveProfile 2>/dev/null |
    awk '{print $2}' | tr -d '"')
[[ -z $current ]] && current="desconocido"

mark() { if [[ "$current" == "$1" ]]; then echo "  · activo"; fi; }

choice=$(printf '%s\n' \
    "󰓅  Rendimiento$(mark performance)" \
    "󰾆  Equilibrado$(mark balanced)" \
    "󰾇  Ahorro de energía$(mark power-saver)" |
    rofi -dmenu -i -no-custom -theme "$THEME" \
        -theme-str 'window { width: 420px; } listview { lines: 3; }' \
        -p "Gestor de energía")

[[ -z ${choice:-} ]] && exit 0

profile=$(profile_id "$choice")
[[ -z $profile ]] && exit 0
[[ $profile == "$current" ]] && exit 0

if busctl --system set-property "$IFACE" "$OBJ" "$IFACE" ActiveProfile s "$profile" >/dev/null 2>&1; then
    case "$profile" in
        performance) label="Rendimiento" ;;
        balanced)    label="Equilibrado" ;;
        power-saver) label="Ahorro de energía" ;;
    esac
    notify-send -a "Energía" -i "power-profile-$profile" "Perfil de energía: $label" 2>/dev/null || true
else
    notify-send -a "Energía" -u critical -i dialog-error "No se pudo cambiar el perfil" \
        "Comprueba tuned-ppd / power-profiles-daemon" 2>/dev/null || true
fi
