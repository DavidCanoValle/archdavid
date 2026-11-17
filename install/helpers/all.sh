# shellcheck shell=bash
# Helpers comunes de archdavid.

if [[ -n "${ARCHDAVID_HELPERS_LOADED:-}" ]]; then
  return 0
fi
ARCHDAVID_HELPERS_LOADED=1

: "${ARCHDAVID_DRY_RUN:=0}"
: "${ARCHDAVID_PATH:=}"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
else
  C_RESET=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
fi

log() { printf '%s[archdavid]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok() { printf '%s[archdavid]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s[archdavid]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err() { printf '%s[archdavid]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die() {
  err "$*"
  exit 1
}

archdavid_is_dry_run() { [[ "${ARCHDAVID_DRY_RUN:-0}" != "0" ]]; }

run() {
  if archdavid_is_dry_run; then
    log "DRY-RUN: $*"
    return 0
  fi
  log "+ $*"
  "$@"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Comando requerido no encontrado: $1"
}

confirm() {
  local prompt="${1:-¿Continuar?}"
  local default="${2:-n}"
  local answer
  if [[ ! -t 0 ]]; then
    [[ "$default" == "y" ]]
    return
  fi
  read -r -p "$prompt " answer || true
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[yYsS]$ ]]
}

archdavid_state_dir() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/archdavid"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

archdavid_log_init() {
  if [[ -z "${ARCHDAVID_LOG:-}" ]]; then
    local dir
    dir="$(archdavid_state_dir)"
    ARCHDAVID_LOG="$dir/install.log"
  fi
  export ARCHDAVID_LOG
}

run_logged() {
  if archdavid_is_dry_run; then
    log "DRY-RUN: $*"
    return 0
  fi
  log "+ $*"
  if [[ -n "${ARCHDAVID_LOG:-}" ]]; then
    "$@" 2>&1 | tee -a "$ARCHDAVID_LOG"
    return "${PIPESTATUS[0]}"
  fi
  "$@"
}

# Busca secretos obvios. Usa gitleaks si está disponible; si no, un patrón básico.
archdavid_secret_scan() {
  local repo="${1:-${ARCHDAVID_PATH:-$PWD}}"
  if command -v gitleaks >/dev/null 2>&1; then
    log "gitleaks: escaneando $repo"
    if ! gitleaks detect --source "$repo" --no-git --redact --no-banner >/dev/null 2>&1; then
      err "gitleaks detectó posibles secretos en $repo"
      return 1
    fi
    ok "gitleaks: limpio"
    return 0
  fi
  warn "gitleaks no instalado; comprobación básica con rg"
  if command -v rg >/dev/null 2>&1; then
    if rg -n --hidden -g '!.git' -g '!node_modules' -g '!*.md' \
      -e 'sk-[A-Za-z0-9]{20,}' \
      -e 'gsk_[A-Za-z0-9]{20,}' \
      -e 'AIza[0-9A-Za-z_-]{20,}' \
      -e 'ghp_[A-Za-z0-9]{20,}' \
      -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
      "$repo" >/dev/null 2>&1; then
      err "Posibles secretos detectados; revisa el repo antes de publicar"
      return 1
    fi
  fi
  ok "Comprobación básica: sin coincidencias"
}
