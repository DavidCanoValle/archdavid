# Changelog

Todas las versiones siguen CalVer `YYYY.MM` (tag `vYYYY.MM`).

## v2026.11 — primeras fases

- Estructura Omarchy-style: repo en `~/.local/share/archdavid`, configs por
  symlink (`--mode link`) o copia (`--mode copy`), CLI `archdavid`, migraciones.
- `install.sh` por fases: preflight, packaging, config, login, post-install.
- Dotfiles: Hyprland, Waybar, QuickShell, kitty, Neovim, rofi, theme-switcher,
  yazi, mpv, zsh/p10k, GTK, opencode y más.
- Paquetes: listas repo/AUR/flatpak/npm/pip y detección CPU AMD/Intel.
- Sistema: plantillas de `/etc`, SDDM, Plymouth, GRUB condicional y
  `/usr/local/bin/theme-install` portable.
- Autosync: snapshot local semanal, release mensual (día 1), update mensual
  (día 3), migraciones y gates de secretos/shellcheck.
- CI: `shellcheck` y `gitleaks`.
- Secretos fuera del repo; `secrets.zsh` con permisos 600.
