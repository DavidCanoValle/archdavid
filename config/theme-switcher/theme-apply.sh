#!/bin/bash
set -euo pipefail
umask 022

notify() { notify-send "$@" 2>/dev/null || true; }

DIR="$HOME/.config/theme-switcher"
ID="${1:-$(cat "$DIR/current" 2>/dev/null || echo david)}"
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
if [[ ! -f "$WALLPAPER" ]]; then
    notify "Fondo no encontrado" "$WALLPAPER — añade los fondos en ~/.wallpapers para cambiar de tema"
    exit 0
fi

notify -t 8000 -i preferences-desktop-theme "Aplicando tema: $NAME" "Generando estilos..."
S="$HOME/.cache/theme-switcher/staging/$ID"
rm -rf "$S"
mkdir -p "$S"

if ! python3 "$DIR/render.py" "$CONF" "$S" >/tmp/theme-render.log 2>&1; then
    notify -i dialog-error "Error al generar el tema" "$(tail -n 3 /tmp/theme-render.log)"
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
    printf '@import "~/.config/rofi/palette.rasi"\n' > "$file"
done < <(find "$HOME/.config/rofi" -path "*/shared/colors.rasi" -print0)

awww img "$WALLPAPER" --transition-type grow --transition-pos 0.85,0.85 --transition-duration 1.2 --transition-fps 60 >/dev/null 2>&1 || awww img "$WALLPAPER" >/dev/null 2>&1 || true
if pgrep -x waybar >/dev/null; then
    "$HOME/.config/waybar/scripts/launch.sh" >/dev/null 2>&1 || true
fi
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# Estado del tema: se escribe ANTES del paso con sudo para no perderlo si se cancela.
printf '%s\n' "$ID" > "$DIR/current"
printf '%s\n' "$NAME" > "$DIR/current-name"

python3 "$DIR/panel-gen.py" "$DIR" "$ID" > "$DIR/panel.json.tmp"
cat "$DIR/panel.json.tmp" > "$DIR/panel.json"
rm -f "$DIR/panel.json.tmp"

notify -t 6000 -i preferences-desktop-theme "Tema aplicado: $NAME" "Colores de usuario actualizados."

# Parte de sistema (GRUB/SDDM/Plymouth). Si se cancela, el tema de usuario ya está aplicado.
MADE_ASK=0
if [[ -n "${THEME_ASKPASS:-}" ]]; then
    ASK="$THEME_ASKPASS"
else
    ASK="$HOME/.cache/theme-switcher/askpass.sh"
    cat > "$ASK" <<'ASKPASS'
#!/bin/sh
exec rofi -dmenu -password -p "Contrasena sudo" -theme "$HOME/.config/rofi/menu.rasi"
ASKPASS
    chmod 700 "$ASK"
    MADE_ASK=1
fi

notify -t 6000 -i system-software-update "Instalando en sistema" "GRUB, SDDM y Plymouth (reconstruyendo initramfs, ~1 min)..."
THEME_INSTALL=/usr/local/bin/theme-install
if [[ ! -x "$THEME_INSTALL" ]]; then
    THEME_INSTALL=/usr/local/bin/david-theme-install
fi
if ! SUDO_ASKPASS="$ASK" sudo -A "$THEME_INSTALL" "$S" "$ID"; then
    [[ "$MADE_ASK" == 1 ]] && rm -f "$ASK"
    notify -i dialog-warning "Tema aplicado (usuario)" "No se actualizó GRUB/SDDM/Plymouth (cancelado o error)."
    exit 0
fi
[[ "$MADE_ASK" == 1 ]] && rm -f "$ASK"
notify -t 8000 -i preferences-desktop-theme "Sistema actualizado" "GRUB, SDDM y Plymouth actualizados. El arranque se verá al reiniciar."
