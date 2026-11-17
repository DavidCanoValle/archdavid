# CLI archdavid

```
archdavid <comando>
```

| Comando | Qué hace |
|---|---|
| `version` | Versión (CalVer `YYYY.MM`). |
| `doctor` | Diagnóstico: repo, bootloader, secretos, herramientas, timers. |
| `snapshot` | Commit local en el origen (sin push). |
| `release [YYYY.MM]` | Gate de secretos/shellcheck, versión, tag y push a `main`. |
| `update` | Fetch de tags y checkout del último `vYYYY.MM`; migraciones. |
| `reload` | `hyprctl reload`, Waybar, `SIGUSR1` a kitty/nvim. |
| `autosync enable --role origin\|target` | Instala y activa los timers. |
| `autosync disable` | Desactiva los timers. |
| `autosync status` | Muestra los timers. |
| `theme <id>` | Aplica un tema vía theme-switcher. |
| `pkg-add <pkg…>` | Instala paquetes (manual, `yay`). |
| `pkg-remove <pkg…>` | Elimina paquetes (manual, `yay`). |
| `install [opts]` | Ejecuta `install.sh`. |

## Ciclo origen → destino

```sh
# Origen (tu equipo), semanal automático:
archdavid snapshot

# Origen, mensual automático:
archdavid release

# Destino, mensual automático:
archdavid update
```

Los timers se activan con `archdavid autosync enable --role …` y respetan la
configuración de `~/.local/share/archdavid/config/archdavid/config.toml`.
