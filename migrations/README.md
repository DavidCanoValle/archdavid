# Migraciones

Cada migración es un script idempotente que se ejecuta **una vez** cuando un
destino pasa de una versión anterior a una nueva.

## Convención

- Nombre: `YYYY.MM-descripcion.sh` (CalVer, el mismo que `version`).
- Se ejecutan en orden lexicográfico las que tengan prefijo **mayor** que la
  versión instalada (`~/.local/state/archdavid/last-version`).
- Deben poder ejecutarse dos veces sin romper nada.
- No usan `sudo` salvo que sea imprescindible; si lo necesitan, avisan.

## Ejemplo

```sh
#!/usr/bin/env bash
set -euo pipefail
# 2026.12: renombrar una opción de configuración
echo "migración 2026.12 aplicada"
```

`archdavid update` ejecuta las pendientes automáticamente.
