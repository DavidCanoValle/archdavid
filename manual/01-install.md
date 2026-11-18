# Instalación

> Arch Linux **ya instalado**, con un usuario normal y `sudo`. archdavid no
> particiona discos ni instala el sistema base.

## Rápida

```sh
curl -fsSL https://raw.githubusercontent.com/DavidCanoValle/archdavid/main/install.sh | bash
```

## Recomendada

```sh
git clone https://github.com/DavidCanoValle/archdavid.git ~/.local/share/archdavid
~/.local/share/archdavid/install.sh --dry-run   # ver qué hará
~/.local/share/archdavid/install.sh             # ejecutar
```

## Opciones

| Opción | Descripción |
|---|---|
| `--dry-run` | Muestra los comandos sin ejecutarlos |
| `--role origin` | Equipo origen (publica releases) |
| `--role target` | Equipo destino (consume releases, por defecto) |
| `--passwordless` | Instala la regla sudoers para actualizar GRUB/SDDM sin contraseña |
| `--help` | Ayuda |

## Requisitos

- Arch Linux (UEFI o BIOS).
- `git`, `sudo`; `yay` se usa para AUR (se instala en la fase de paquetes).
- Conexión a red para clonar y descargar paquetes.

## Tras instalar

1. Rellena `~/.config/zsh/secrets.zsh` (chmod 600) con tus claves.
2. Activa el autosync: `archdavid autosync enable --role origin|target`.
3. Cierra sesión y vuelve a entrar para aplicar el tema y el shell.

## Rollback

```sh
archdavid update        # última release
git -C ~/.local/share/archdavid checkout vYYYY.MM
```
