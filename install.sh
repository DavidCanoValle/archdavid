#!/usr/bin/env bash
set -eEo pipefail

ARCHDAVID_REPO_URL="${ARCHDAVID_REPO_URL:-https://github.com/DavidCanoValle/archdavid.git}"
ARCHDAVID_INSTALL_DEFAULT="${ARCHDAVID_INSTALL_DEFAULT:-$HOME/.local/share/archdavid}"
ARCHDAVID_DRY_RUN="${ARCHDAVID_DRY_RUN:-0}"
ARCHDAVID_ROLE="${ARCHDAVID_ROLE:-target}"
export ARCHDAVID_DRY_RUN ARCHDAVID_ROLE

say() { printf '[archdavid] %s\n' "$*"; }
fail() {
  printf '[archdavid] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
archdavid — distribución Arch + Hyprland

Uso: install.sh [opciones]

Opciones:
  --dry-run        Muestra los comandos sin ejecutarlos
  --role ROLE      origin | target (por defecto: target)
  -h, --help       Esta ayuda

Variables:
  ARCHDAVID_REPO_URL         URL del repo a clonar
  ARCHDAVID_INSTALL_DEFAULT  Ruta destino (~/.local/share/archdavid)
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run)
      ARCHDAVID_DRY_RUN=1
      export ARCHDAVID_DRY_RUN
      ;;
    --role)
      shift
      [[ $# -gt 0 ]] || fail "--role requiere un valor"
      ARCHDAVID_ROLE="$1"
      export ARCHDAVID_ROLE
      ;;
    --role=*)
      ARCHDAVID_ROLE="${1#*=}"
      export ARCHDAVID_ROLE
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fail "opción desconocida: $1 (usa --help)"
      ;;
  esac
  shift
done

case "$ARCHDAVID_ROLE" in
  origin | target) ;;
  *) fail "rol inválido: $ARCHDAVID_ROLE (origin|target)" ;;
esac

src_dir=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "$src_dir" && -d "$src_dir/install" ]]; then
  ARCHDAVID_PATH="$src_dir"
else
  ARCHDAVID_PATH="${ARCHDAVID_PATH:-$ARCHDAVID_INSTALL_DEFAULT}"
fi
export ARCHDAVID_PATH
ARCHDAVID_INSTALL="$ARCHDAVID_PATH/install"
export ARCHDAVID_INSTALL

if [[ ! -d "$ARCHDAVID_INSTALL" ]]; then
  command -v git >/dev/null 2>&1 || fail "git es necesario para clonar archdavid"
  say "Clonando archdavid en $ARCHDAVID_PATH"
  git clone "$ARCHDAVID_REPO_URL" "$ARCHDAVID_PATH" || fail "no se pudo clonar"
fi

# shellcheck source=/dev/null
source "$ARCHDAVID_INSTALL/helpers/all.sh"
archdavid_log_init

log "archdavid $(cat "$ARCHDAVID_PATH/version" 2>/dev/null || echo '?')"
log "Ruta: $ARCHDAVID_PATH · rol: $ARCHDAVID_ROLE · dry-run: $ARCHDAVID_DRY_RUN"

# shellcheck source=/dev/null
source "$ARCHDAVID_INSTALL/preflight/all.sh"
# shellcheck source=/dev/null
source "$ARCHDAVID_INSTALL/packaging/all.sh"
# shellcheck source=/dev/null
source "$ARCHDAVID_INSTALL/config/all.sh"
# shellcheck source=/dev/null
source "$ARCHDAVID_INSTALL/login/all.sh"
# shellcheck source=/dev/null
source "$ARCHDAVID_INSTALL/post-install/all.sh"

archdavid_preflight
archdavid_packaging
archdavid_config
archdavid_login
archdavid_post_install

ok "Instalador de archdavid finalizado."
