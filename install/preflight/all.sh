# shellcheck shell=bash
# Fase: preflight. Comprobaciones previas, sin modificar nada.

archdavid_preflight() {
  log "Preflight"

  if [[ "$(id -u)" -eq 0 ]]; then
    die "Ejecuta como usuario normal (con sudo), no como root"
  fi

  if [[ -f /etc/arch-release ]]; then
    ok "Arch Linux detectado"
  else
    warn "No se detecta Arch Linux (/etc/arch-release ausente)"
  fi

  if [[ -d /sys/firmware/efi ]]; then
    ok "UEFI detectado"
  else
    warn "Sistema sin UEFI (BIOS legacy)"
  fi

  require_cmd sudo
  require_cmd git

  if command -v yay >/dev/null 2>&1; then
    ok "yay disponible"
  else
    warn "yay no instalado; se usará en la fase de paquetes"
  fi

  if command -v curl >/dev/null 2>&1; then
    if curl -fsS --max-time 6 https://github.com >/dev/null 2>&1; then
      ok "Conectividad con GitHub"
    else
      warn "Sin conexión a GitHub"
    fi
  fi

  local conflicts=()
  local d
  for d in nvim kitty hypr waybar quickshell rofi theme-switcher; do
    if [[ -e "$HOME/.config/$d" && ! -L "$HOME/.config/$d" ]]; then
      conflicts+=("$d")
    fi
  done
  if (( ${#conflicts[@]} > 0 )); then
    warn "Configs existentes detectadas: ${conflicts[*]}"
    log "Se respaldarán antes de enlazar en la fase de configuración"
  fi

  ok "Preflight completado"
}
