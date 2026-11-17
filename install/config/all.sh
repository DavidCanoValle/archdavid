# shellcheck shell=bash
# Fase: config. Enlaza (o copia) los dotfiles según config.manifest,
# instala plantillas de /etc y habilita servicios.

archdavid_backup_dir() {
  local ts dir
  ts="$(date +%Y%m%d-%H%M%S)"
  dir="$(archdavid_state_dir)/backup-$ts"
  if ! archdavid_is_dry_run; then
    mkdir -p "$dir"
  fi
  printf '%s\n' "$dir"
}

archdavid_link_entry() {
  local mode="$1" source="$2" dest="$3" backup="$4" linkmode="$5"
  local src="$ARCHDAVID_PATH/config/$source"
  local target="$HOME/$dest"

  if [[ ! -e "$src" ]]; then
    warn "no existe en el repo: config/$source"
    return 0
  fi

  if [[ -L "$target" ]] && [[ "$(readlink -f "$target")" == "$(readlink -f "$src")" ]]; then
    ok "$dest ya enlazado"
    return 0
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if archdavid_is_dry_run; then
      log "DRY-RUN: backup $target -> $backup/$dest"
    else
      mkdir -p "$backup/$(dirname "$dest")"
      mv "$target" "$backup/$dest"
    fi
  fi

  if archdavid_is_dry_run; then
    log "DRY-RUN: ${linkmode} $src -> $target"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  if [[ "$linkmode" == "copy" ]]; then
    cp -a "$src" "$target"
  else
    ln -s "$src" "$target"
  fi
  ok "$dest -> ${linkmode}"
}

archdavid_seed_config() {
  local cfg="$HOME/.config/archdavid/config.toml"
  if [[ -f "$cfg" ]]; then
    return 0
  fi
  if archdavid_is_dry_run; then
    log "DRY-RUN: seed $cfg"
  else
    mkdir -p "$(dirname "$cfg")"
    cp "$ARCHDAVID_PATH/config/archdavid/config.toml" "$cfg"
  fi
}

archdavid_relink() {
  local linkmode="${ARCHDAVID_MODE:-link}"
  if [[ "$linkmode" != "link" && "$linkmode" != "copy" ]]; then
    die "ARCHDAVID_MODE inválido: $linkmode (link|copy)"
  fi

  if [[ ! -f "$ARCHDAVID_PATH/config.manifest" ]]; then
    warn "sin config.manifest; se omiten los dotfiles"
    return 0
  fi

  local backup
  backup="$(archdavid_backup_dir)"
  log "Backup de configs previas: $backup"

  local mode source dest rest
  while read -r mode source dest rest; do
    if [[ -z "${mode:-}" || "$mode" == \#* ]]; then
      continue
    fi
    case "$mode" in
      dir | file)
        archdavid_link_entry "$mode" "$source" "$dest" "$backup" "$linkmode"
        ;;
      *)
        warn "entrada inválida en config.manifest: $mode $source $dest"
        ;;
    esac
  done <"$ARCHDAVID_PATH/config.manifest"

  archdavid_seed_config
}

archdavid_install_etc() {
  local map
  while IFS='|' read -r map; do
    if [[ -z "$map" || "$map" == \#* ]]; then
      continue
    fi
    local src dest
    src="${map%%->*}"
    dest="${map##*->}"
    src="$(printf '%s' "$src" | xargs)"
    dest="$(printf '%s' "$dest" | xargs)"
    if [[ ! -f "$ARCHDAVID_PATH/etc/$src" ]]; then
      continue
    fi
    if archdavid_is_dry_run; then
      log "DRY-RUN: install etc/$src -> $dest"
    else
      run_logged sudo install -Dm644 "$ARCHDAVID_PATH/etc/$src" "$dest"
    fi
  done <<'EOF'
locale.gen -> /etc/locale.gen
vconsole.conf -> /etc/vconsole.conf
X11/xorg.conf.d/00-keyboard.conf -> /etc/X11/xorg.conf.d/00-keyboard.conf
sddm.conf.d/10-theme.conf -> /etc/sddm.conf.d/10-theme.conf
plymouth/plymouthd.conf -> /etc/plymouth/plymouthd.conf
mkinitcpio.conf -> /etc/mkinitcpio.conf
mkinitcpio.d/linux.preset -> /etc/mkinitcpio.d/linux.preset
default/grub -> /etc/default/grub
EOF
}

archdavid_enable_services() {
  local f unit
  f="$ARCHDAVID_PATH/packages/services-system.txt"
  if [[ -f "$f" ]]; then
    while IFS= read -r unit; do
      if [[ -z "$unit" || "$unit" == \#* ]]; then
        continue
      fi
      run sudo systemctl enable "$unit" || warn "no se pudo habilitar $unit"
    done <"$f"
  fi

  f="$ARCHDAVID_PATH/packages/services-user.txt"
  if [[ -f "$f" ]]; then
    while IFS= read -r unit; do
      if [[ -z "$unit" || "$unit" == \#* ]]; then
        continue
      fi
      run systemctl --user enable "$unit" || warn "no se pudo habilitar (usuario) $unit"
    done <"$f"
  fi
}

archdavid_config() {
  log "Configuración: dotfiles y sistema"
  archdavid_relink
  archdavid_install_etc
  archdavid_enable_services
  ok "Configuración aplicada"
}
