# shellcheck shell=bash
# Fase: login. Plymouth y SDDM siempre; GRUB solo si ya existe.
# Nunca instala ni cambia el bootloader.

archdavid_detect_bootloader() {
  if [[ -f /etc/default/grub ]] && command -v grub-mkconfig >/dev/null 2>&1; then
    printf 'grub\n'
    return 0
  fi
  if command -v bootctl >/dev/null 2>&1 && bootctl is-installed >/dev/null 2>&1; then
    printf 'systemd-boot\n'
    return 0
  fi
  printf 'unknown\n'
}

archdavid_install_theme_installer() {
  local src="$ARCHDAVID_PATH/system/usr-local-bin/theme-install"
  [[ -f "$src" ]] || return 0
  if archdavid_is_dry_run; then
    log "DRY-RUN: install theme-install -> /usr/local/bin/theme-install"
    return 0
  fi
  run_logged sudo install -Dm755 "$src" /usr/local/bin/theme-install
}

archdavid_login() {
  log "Login/boot"
  local boot
  boot="$(archdavid_detect_bootloader)"
  log "Bootloader detectado: $boot"

  archdavid_install_theme_installer

  if [[ -f /etc/locale.gen ]]; then
    run sudo locale-gen || warn "locale-gen falló"
  fi

  run sudo mkinitcpio -P || warn "mkinitcpio falló"

  case "$boot" in
    grub)
      local grub_theme=0
      if ! archdavid_is_dry_run && sudo test -f /boot/grub/themes/david/theme.txt; then
        grub_theme=1
      fi
      if (( grub_theme )); then
        if ! rg -q '^GRUB_THEME=' /etc/default/grub 2>/dev/null; then
          if archdavid_is_dry_run; then
            log "DRY-RUN: añadir GRUB_THEME a /etc/default/grub"
          else
            printf 'GRUB_THEME="/boot/grub/themes/david/theme.txt"\n' \
              | sudo tee -a /etc/default/grub >/dev/null
          fi
        fi
        run sudo grub-mkconfig -o /boot/grub/grub.cfg || warn "grub-mkconfig falló"
      else
        warn "Tema GRUB no instalado; aplícalo con: archdavid theme <id>"
      fi
      ;;
    systemd-boot)
      local root_uuid
      root_uuid="$(findmnt -no UUID / 2>/dev/null || true)"
      if [[ -n "$root_uuid" ]]; then
        if archdavid_is_dry_run; then
          log "DRY-RUN: /etc/kernel/cmdline root=UUID=$root_uuid ..."
        else
          printf 'root=UUID=%s zswap.enabled=0 rw rootfstype=ext4 quiet splash\n' "$root_uuid" \
            | sudo tee /etc/kernel/cmdline >/dev/null
        fi
        run sudo mkinitcpio -P || warn "mkinitcpio falló"
      else
        warn "No se pudo detectar el UUID raíz"
      fi
      ;;
    *)
      warn "Bootloader no reconocido; solo se configuran Plymouth y SDDM"
      ;;
  esac

  ok "Login/boot completado"
}
