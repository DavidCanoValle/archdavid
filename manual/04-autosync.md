# Autosync (sincronización periódica)

archdavid sincroniza configuraciones mediante **releases mensuales**.

## Roles

| Rol | Qué hace | Timer |
|---|---|---|
| `origin` | Snapshot local semanal + release mensual (día 1) | `archdavid-snapshot.timer`, `archdavid-release.timer` |
| `target` | Update mensual (día 3) al último tag | `archdavid-update.timer` |

Activa el rol:

```sh
archdavid autosync enable --role origin   # tu equipo
archdavid autosync enable --role target   # los demás
archdavid autosync status
archdavid autosync disable
```

El rol se guarda en `~/.local/state/archdavid/role` (no en el repo).

## Origen

- **Snapshot** (semanal): `gitleaks`/escaneo básico, `git add -A` y commit
  local **sin push**. Protege cambios entre releases.
- **Release** (mensual): comprueba secretos y `shellcheck`, regenera
  manifiestos, escribe `version` (CalVer `YYYY.MM`), commit, tag `vYYYY.MM` y
  push a `main` + tag. Nunca usa `--force`.

## Destino

`archdavid update`:

1. Aborta si el árbol tiene cambios locales.
2. `git fetch --tags`, elige el tag más reciente.
3. `git checkout <tag>`, ejecuta migraciones pendientes.
4. Re-enlaza dotfiles.
5. Pregunta si recargar (rofi). Si no hay sesión gráfica, deja
   `~/.local/state/archdavid/pending-reload` y notifica.

Los updates **no instalan paquetes**.

## Secretos

`gitleaks` (o el escaneo básico) se ejecuta antes de cada snapshot/release y
en CI. Si detecta algo, aborta. `~/.config/zsh/secrets.zsh` nunca entra al
repo.
