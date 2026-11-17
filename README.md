# archdavid

Distribución personal de Arch Linux + Hyprland, al estilo de
[Omarchy](https://omarchy.org): un instalador que convierte un Arch ya
instalado en mi entorno completo, y un módulo de sincronización mensual para
replicarlo en otros equipos.

> **Estado: Fases 1–5.** Esqueleto, dotfiles, paquetes, sistema/temas y
> autosync implementados. Ver [manual/](manual/).

## Instalación

En un Arch Linux ya instalado, con un usuario normal y `sudo`:

```sh
curl -fsSL https://raw.githubusercontent.com/DavidCanoValle/archdavid/main/install.sh | bash
```

Alternativa recomendada (revisar antes de ejecutar):

```sh
git clone https://github.com/DavidCanoValle/archdavid.git ~/.local/share/archdavid
~/.local/share/archdavid/install.sh --dry-run
~/.local/share/archdavid/install.sh
```

`install.sh` se ejecuta **como usuario**, nunca como root; usa `sudo` solo para
lo que lo necesita.

## CLI

```sh
archdavid version      # versión instalada
archdavid doctor       # diagnóstico
archdavid snapshot     # commit local (origen, sin push)
archdavid release      # nueva versión CalVer + tag + push (origen)
archdavid update       # actualiza al último tag (destino)
archdavid reload       # recarga Hyprland/Waybar/kitty/nvim
archdavid autosync enable --role origin|target
archdavid theme <id>
```

## Modelo

- Repo en `~/.local/share/archdavid`; configs de `~/.config` enlazadas
  (`--mode link`, por defecto) o copiadas (`--mode copy`).
- Versiones **CalVer** `YYYY.MM`, tag `vYYYY.MM`.
- **Origen**: snapshot local semanal; release mensual (día 1) a `main`.
- **Destino**: update mensual (día 3) al último tag; nunca toca paquetes.
- Secretos **fuera** del repo (`~/.config/zsh/secrets.zsh`, chmod 600).

## Estructura

```
install/      fases del instalador (preflight, packaging, config, login, post-install)
bin/          CLI archdavid
config/       dotfiles gestionados (incluye theme-switcher)
packages/     listas de paquetes (repo, AUR, hardware, flatpak, npm, pip)
etc/          plantillas de /etc
system/       script root theme-install
systemd/user/ timers de snapshot/release/update
migrations/   migraciones versionadas
manual/       documentación
```

## Licencia

MIT © 2026 David Cano Valle
