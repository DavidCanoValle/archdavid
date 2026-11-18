#!/usr/bin/env bash
# Instala el helper root-owned y la regla sudoers para actualizar GRUB/SDDM
# sin contraseña. Ejecutar UNA vez con sudo:
#   sudo ~/.local/share/archdavid/scripts/setup-passwordless-theme.sh
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Ejecuta con sudo: sudo $0" >&2
  exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$REPO/system/usr-local-bin/theme-install"
SUDOERS="$REPO/system/sudoers.d/archdavid-theme"

[[ -f "$HELPER" ]] || { echo "falta $HELPER" >&2; exit 1; }
[[ -f "$SUDOERS" ]] || { echo "falta $SUDOERS" >&2; exit 1; }

install -Dm755 "$HELPER" /usr/local/bin/theme-install

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
install -m440 "$SUDOERS" "$tmp"
visudo -cf "$tmp"
install -Dm440 "$tmp" /etc/sudoers.d/archdavid-theme
chown root:root /etc/sudoers.d/archdavid-theme
chmod 440 /etc/sudoers.d/archdavid-theme
visudo -c >/dev/null

echo "OK: /usr/local/bin/theme-install instalado y regla en /etc/sudoers.d/archdavid-theme"
echo "Los cambios de tema (GRUB/SDDM) ya no pedirán contraseña."
echo "Plymouth (--plymouth) seguirá pidiéndola."
