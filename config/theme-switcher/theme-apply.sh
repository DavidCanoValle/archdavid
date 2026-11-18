#!/bin/bash
set -euo pipefail
umask 022

notify() { notify-send "$@" 2>/dev/null || true; }

DIR="$HOME/.config/theme-switcher"
ID=""
BOOT_MODE="background" # background | foreground | none
PLYMOUTH=0

for arg in "$@"; do
    case "$arg" in
        --boot) BOOT_MODE="foreground" ;;
        --no-boot) BOOT_MODE="none" ;;
        --plymouth) PLYMOUTH=1 ;;
        --no-plymouth) PLYMOUTH=0 ;;
        -*) notify "Tema" "Opción desconocida: $arg"; exit 1 ;;
        *) ID="$arg" ;;
    esac
done
ID="${ID:-$(cat "$DIR/current" 2>/dev/null || echo david)}"
CONF="$DIR/themes/$ID.conf"

if [[ ! -f "$CONF" ]]; then
    notify "Tema no encontrado" "$ID"
    exit 1
fi

# shellcheck disable=SC1090
source "$CONF"
for v in NAME BG PANEL PANEL2 BORDER ACCENT TEXT DIM WARN WALLPAPER; do
    if [[ -z "${!v:-}" ]]; then
        notify "Tema invalido" "Falta $v en $CONF"
        exit 1
    fi
done

HAVE_WALL=1
if [[ ! -f "$WALLPAPER" ]]; then
    HAVE_WALL=0
    notify -i dialog-warning "Tema: sin fondo" "$WALLPAPER — se aplican solo los colores"
fi

notify -t 6000 -i preferences-desktop-theme "Aplicando tema: $NAME" "Aplicando colores..."
S="$HOME/.cache/theme-switcher/staging/$ID"

# --- Ruta rápida: solo colores de usuario ---
if ! python3 "$DIR/render.py" user "$CONF" "$S" >/tmp/theme-render-user.log 2>&1; then
    notify -i dialog-error "Error al aplicar el tema" "$(tail -n 3 /tmp/theme-render-user.log)"
    exit 1
fi

cp -f "$S/user/waybar-colors.css" "$HOME/.config/waybar/colors.css"
cp -f "$S/user/palette.rasi" "$HOME/.config/rofi/palette.rasi"
cp -f "$S/user/theme.lua" "$HOME/.config/hypr/theme.lua"
cp -f "$S/user/kitty-theme.conf" "$HOME/.config/kitty/theme.conf"
pkill -USR1 -x kitty >/dev/null 2>&1 || true
if [[ -d "$HOME/.config/nvim" ]]; then
    cp -f "$S/user/theme_current.lua" "$HOME/.config/nvim/lua/theme_current.lua"
    pkill -USR1 -x nvim >/dev/null 2>&1 || true
fi
while IFS= read -r -d '' file; do
    printf '@import "~/.config/rofi/palette.rasi"\n' >"$file"
done < <(find "$HOME/.config/rofi" -path "*/shared/colors.rasi" -print0)

if (( HAVE_WALL )); then
    awww img "$WALLPAPER" --transition-type grow --transition-pos 0.85,0.85 --transition-duration 1.2 --transition-fps 60 >/dev/null 2>&1 \
        || awww img "$WALLPAPER" >/dev/null 2>&1 || true
fi
if pgrep -x waybar >/dev/null; then
    "$HOME/.config/waybar/scripts/launch.sh" >/dev/null 2>&1 || true
fi
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# --- Estado (se escribe antes del paso de sistema) ---
printf '%s\n' "$ID" >"$DIR/current"
printf '%s\n' "$NAME" >"$DIR/current-name"
python3 "$DIR/panel-gen.py" "$DIR" "$ID" >"$DIR/panel.json.tmp"
cat "$DIR/panel.json.tmp" >"$DIR/panel.json"
rm -f "$DIR/panel.json.tmp"
notify -t 6000 -i preferences-desktop-theme "Tema aplicado: $NAME" "Colores de usuario actualizados."

if [[ "$BOOT_MODE" == "none" ]]; then
    exit 0
fi
if (( ! HAVE_WALL )); then
    notify -t 5000 "Tema de arranque" "Omitido: falta el fondo para GRUB/SDDM/Plymouth"
    exit 0
fi

boot_args=("$ID" "$CONF")
(( PLYMOUTH )) && boot_args+=(--plymouth)

if [[ "$BOOT_MODE" == "foreground" ]]; then
    "$DIR/theme-apply-boot.sh" "${boot_args[@]}" || true
else
    notify -t 4000 "Tema de arranque" "Se actualizará en segundo plano."
    if command -v setsid >/dev/null 2>&1; then
        setsid bash "$DIR/theme-apply-boot.sh" "${boot_args[@]}" </dev/null >>/tmp/theme-boot.log 2>&1 &
    else
        nohup bash "$DIR/theme-apply-boot.sh" "${boot_args[@]}" </dev/null >>/tmp/theme-boot.log 2>&1 &
    fi
fi
