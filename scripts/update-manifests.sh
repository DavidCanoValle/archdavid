#!/usr/bin/env bash
# Regenera los manifiestos de paquetes del repo a partir del equipo actual.
# Uso (origen): scripts/update-manifests.sh
set -eEo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$ROOT/packages"
mkdir -p "$PKG"

echo "[archdavid] regenerando manifiestos en $PKG"

# Repo oficial: excluye microcódigo (va en hardware-*.txt)
pacman -Qqen | rg -vx 'amd-ucode|intel-ucode' | sort >"$PKG/common.txt"
printf 'flatpak\n' >>"$PKG/common.txt"
sort -u "$PKG/common.txt" -o "$PKG/common.txt"

# AUR: excluye yay (lo instala el bootstrap)
pacman -Qqem | rg -vx 'yay|yay-debug' | sort >"$PKG/aur.txt"

# Flatpak
if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application 2>/dev/null | sort >"$PKG/flatpak.txt" || true
fi

# npm global (sin npm)
if command -v npm >/dev/null 2>&1; then
  npm ls -g --depth=0 --parseable 2>/dev/null \
    | sed 's#^.*/node_modules/##' \
    | rg -vx 'npm' \
    | sort >"$PKG/npm-global.txt" || true
fi

echo "[archdavid] hecho. Revisa pip-user.txt y services-*.txt (curados a mano)."
