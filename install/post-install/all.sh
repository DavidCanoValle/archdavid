# shellcheck shell=bash
# Fase: post-install. Secretos, estado y resumen.

archdavid_post_install() {
  log "Post-instalación"

  local secrets="$HOME/.config/zsh/secrets.zsh"
  if [[ -f "$secrets" ]]; then
    ok "Secretos presentes: $secrets"
  else
    run mkdir -p "$HOME/.config/zsh"
    if ! archdavid_is_dry_run; then
      (
        umask 077
        cat >"$secrets" <<'EOF'
# Secretos locales de archdavid. NO versionar. Permisos 600.
# Rellena y descomenta lo que necesites.
# export GROQ_API_KEY=""
# export OPENROUTER_API_KEY=""
# export GEMINI_API_KEY=""
EOF
        chmod 600 "$secrets"
      )
      ok "Creado $secrets (modo 600). Añade tus claves."
    fi
  fi

  local binlink="$HOME/.local/bin/archdavid"
  if [[ -L "$binlink" && "$(readlink "$binlink")" == "$ARCHDAVID_PATH/bin/archdavid" ]]; then
    ok "CLI ya enlazada: $binlink"
  else
    run mkdir -p "$HOME/.local/bin"
    if ! archdavid_is_dry_run; then
      ln -sf "$ARCHDAVID_PATH/bin/archdavid" "$binlink"
    fi
    ok "CLI enlazada: $binlink (añade ~/.local/bin al PATH)"
  fi

  local state version
  state="$(archdavid_state_dir)"
  version="$(cat "$ARCHDAVID_PATH/version" 2>/dev/null || echo unknown)"
  if ! archdavid_is_dry_run; then
    printf '%s\n' "$version" >"$state/installed-version" 2>/dev/null || true
  fi

  ok "Instalación completada. Reinicia sesión para aplicar el entorno."
}
