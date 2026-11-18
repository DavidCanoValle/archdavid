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
ROOT_HELPER="${ARCHDAVID_ROOT_HELPER:-/usr/local/bin/theme-install}"
SUDOERS="${ARCHDAVID_SUDOERS_FILE:-/etc/sudoers.d/archdavid-theme}"

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

resolve_repo_helper() {
  local real repo candidate
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
  return 1
}

REPO_HELPER="$(resolve_repo_helper || true)"

if (( PLYMOUTH )); then
  ARGS=(--plymouth "$S" "$ID")
else
  ARGS=(--no-plymouth "$S" "$ID")
fi

# 1) Intento sin contraseña: solo helper root-owned + regla sudoers.
if [[ -x "$ROOT_HELPER" ]]; then
  if out="$(sudo -n "$ROOT_HELPER" "${ARGS[@]}" 2>&1)"; then
    MSG="GRUB y SDDM actualizados."
    (( PLYMOUTH )) && MSG="GRUB, SDDM y Plymouth actualizados."
    notify -t 7000 "Tema de arranque aplicado" "$MSG"
    exit 0
  fi
  case "$out" in
    *"password is required"*|*"no password was provided"*|*"a terminal is required"*) ;;
    *)
      notify -i dialog-error "Tema de arranque" "$out"
      exit 1
      ;;
  esac
fi

# 2) Fallback con contraseña (rofi askpass).
if [[ ! -f "$SUDOERS" ]]; then
  notify -t 6000 "Tema de arranque" "Sin contraseña: archdavid theme-passwordless enable"
fi

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

if [[ -x "$ROOT_HELPER" ]]; then
  ok=0
  SUDO_ASKPASS="$ASK" sudo -A "$ROOT_HELPER" "${ARGS[@]}" || ok=$?
else
  [[ -n "$REPO_HELPER" ]] || { notify -i dialog-error "Tema de arranque" "No se encontró theme-install"; exit 1; }
  ok=0
  SUDO_ASKPASS="$ASK" sudo -A bash "$REPO_HELPER" "${ARGS[@]}" || ok=$?
fi

[[ "$MADE_ASK" == 1 ]] && rm -f "$ASK"

if [[ "$ok" == 0 ]]; then
  MSG="GRUB y SDDM actualizados."
  (( PLYMOUTH )) && MSG="GRUB, SDDM y Plymouth actualizados."
  notify -t 7000 "Tema de arranque aplicado" "$MSG"
else
  notify -i dialog-warning "Tema de arranque" "No se actualizó (cancelado o error)."
fi
exit 0
