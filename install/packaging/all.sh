# shellcheck shell=bash
# Fase: packaging. Instala la lista de paquetes una sola vez.
# Los updates de archdavid NUNCA tocan paquetes.

archdavid_cpu_vendor() {
  rg -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | sed 's/.*: //' || true
}

archdavid_read_list() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  rg -v '^\s*(#|$)' "$file" || true
}

archdavid_pacman_install_file() {
  local file="$1"
  local pkgs=()
  [[ -f "$file" ]] || return 0
  mapfile -t pkgs < <(archdavid_read_list "$file")
  (( ${#pkgs[@]} > 0 )) || return 0
  run_logged sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

archdavid_install_yay() {
  if command -v yay >/dev/null 2>&1; then
    ok "yay ya instalado"
    return 0
  fi
  if archdavid_is_dry_run; then
    log "DRY-RUN: compilar e instalar yay desde AUR"
    return 0
  fi
  local tmp="/tmp/archdavid-yay"
  rm -rf "$tmp"
  git clone https://aur.archlinux.org/yay.git "$tmp"
  (
    cd "$tmp" || return 1
    makepkg -si --noconfirm
  )
}

archdavid_yay_install_file() {
  local file="$1"
  local pkgs=()
  [[ -f "$file" ]] || return 0
  mapfile -t pkgs < <(archdavid_read_list "$file")
  (( ${#pkgs[@]} > 0 )) || return 0
  run_logged yay -S --needed --noconfirm "${pkgs[@]}"
}

archdavid_flatpak_install() {
  local file="$ARCHDAVID_PATH/packages/flatpak.txt"
  local apps=()
  [[ -f "$file" ]] || return 0
  mapfile -t apps < <(archdavid_read_list "$file")
  (( ${#apps[@]} > 0 )) || return 0
  run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  local app
  for app in "${apps[@]}"; do
    run flatpak install -y flathub "$app"
  done
}

archdavid_npm_install() {
  local file="$ARCHDAVID_PATH/packages/npm-global.txt"
  local pkgs=()
  [[ -f "$file" ]] || return 0
  mapfile -t pkgs < <(archdavid_read_list "$file")
  (( ${#pkgs[@]} > 0 )) || return 0
  run_logged sudo npm install -g "${pkgs[@]}"
}

archdavid_pip_install() {
  local file="$ARCHDAVID_PATH/packages/pip-user.txt"
  local pkgs=()
  [[ -f "$file" ]] || return 0
  mapfile -t pkgs < <(archdavid_read_list "$file")
  (( ${#pkgs[@]} > 0 )) || return 0
  run python3 -m pip install --user --break-system-packages "${pkgs[@]}"
}

archdavid_packaging() {
  log "Paquetes (instalación única)"

  archdavid_pacman_install_file "$ARCHDAVID_PATH/packages/common.txt"

  local hw=""
  case "$(archdavid_cpu_vendor)" in
    AuthenticAMD) hw="$ARCHDAVID_PATH/packages/hardware-amd.txt" ;;
    GenuineIntel) hw="$ARCHDAVID_PATH/packages/hardware-intel.txt" ;;
    *) warn "CPU no reconocida; revisa packages/hardware-*.txt" ;;
  esac
  if [[ -n "$hw" ]]; then
    archdavid_pacman_install_file "$hw"
  fi

  archdavid_install_yay
  archdavid_yay_install_file "$ARCHDAVID_PATH/packages/aur.txt"

  archdavid_flatpak_install
  archdavid_npm_install
  archdavid_pip_install

  ok "Paquetes instalados"
}
