#!/bin/bash
# Actualiza el tema de arranque (GRUB/SDDM y, opcionalmente, Plymouth).
# Se ejecuta en segundo plano desde theme-apply.sh.
set -euo pipefail
umask 022

notify() { notify-send "$@" 2>/dev/null || true; }

DIR="$HOME/.config/theme-switcher"
ID="${1:-}"
CONF="${2:-$DIR/themes/$ID.conf}"
shift 2 2>/dev/null || true

PLYMOUTH=0
for a in "$@"; do
  case "$a" in
    --plymouth) PLYMOUTH=1 ;;
    --no-plymouth) PLYMOUTH=0 ;;
  esac
done

[[ -n "$ID" && -f "$CONF" ]] || { notify "Tema de arranque" "Tema no válido: $ID"; exit 1; }

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/archdavid"
mkdir -p "$STATE"
exec 9>"$STATE/theme-boot.lock"
flock -n 9 || exit 0

S="$HOME/.cache/theme-switcher/staging/$ID"
LOG=/tmp/theme-render-boot.log

notify -t 5000 "Tema de arranque" "Actualizando GRUB/SDDM..."
if ! python3 "$DIR/render.py" system "$CONF" "$S" >>"$LOG" 2>&1; then
  notify -i dialog-error "Tema de arranque" "Error generando assets (ver $LOG)"
  exit 1
fi
if (( PLYMOUTH )); then
  notify -t 5000 "Tema de arranque" "Generando Plymouth estático..."
  if ! python3 "$DIR/render.py" plymouth "$CONF" "$S" >>"$LOG" 2>&1; then
    notify -i dialog-error "Tema de arranque" "Error generando Plymouth (ver $LOG)"
    exit 1
  fi
fi

resolve_helper() {
  local candidate real repo
  if [[ -n "${ARCHDAVID_PATH:-}" && -f "$ARCHDAVID_PATH/system/usr-local-bin/theme-install" ]]; then
    printf '%s\n' "$ARCHDAVID_PATH/system/usr-local-bin/theme-install"
    return 0
  fi
  real=""
  if [[ -d "$DIR" ]]; then
    real="$(cd "$DIR" && pwd -P)"
  fi
  if [[ -n "$real" ]]; then
    repo="$(dirname "$(dirname "$real")")"
    candidate="$repo/system/usr-local-bin/theme-install"
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi
  candidate="$HOME/.local/share/archdavid/system/usr-local-bin/theme-install"
  [[ -f "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  candidate=/usr/local/bin/theme-install
  [[ -f "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  return 1
}

HELPER="$(resolve_helper)" || {
  notify -i dialog-error "Tema de arranque" "No se encontró theme-install"
  exit 1
}

MADE_ASK=0
if [[ -n "${THEME_ASKPASS:-}" ]]; then
  ASK="$THEME_ASKPASS"
else
  ASK="$HOME/.cache/theme-switcher/askpass.sh"
  cat >"$ASK" <<'ASKPASS'
#!/bin/sh
exec rofi -dmenu -password -p "Contrasena sudo" -theme "$HOME/.config/rofi/menu.rasi"
ASKPASS
  chmod 700 "$ASK"
  MADE_ASK=1
fi

notify -t 5000 "Tema de arranque" "Se necesita tu contraseña para actualizar el sistema."
FLAG=--no-plymouth
(( PLYMOUTH )) && FLAG=--plymouth

if SUDO_ASKPASS="$ASK" sudo -A bash "$HELPER" "$S" "$ID" "$FLAG"; then
  [[ "$MADE_ASK" == 1 ]] && rm -f "$ASK"
  DONE_MSG="GRUB y SDDM actualizados."
  (( PLYMOUTH )) && DONE_MSG="GRUB, SDDM y Plymouth actualizados."
  notify -t 7000 "Tema de arranque aplicado" "$DONE_MSG"
  exit 0
fi

[[ "$MADE_ASK" == 1 ]] && rm -f "$ASK"
notify -i dialog-warning "Tema de arranque" "No se actualizó (cancelado o error)."
exit 0
