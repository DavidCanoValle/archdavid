# Temas y fondos

Los temas viven en `config/theme-switcher/` (enlazado a
`~/.config/theme-switcher`) y generan colores para kitty, Hyprland, Waybar,
rofi y Neovim, además de GRUB, Plymouth y SDDM.

## Aplicar un tema (rápido)

```sh
archdavid theme gruvbox
# o desde el panel (Super + A) / menú (Super + Shift + T)
```

El cambio de colores del escritorio y del panel es **inmediato** (<1 s).
Después, en **segundo plano**, se actualizan GRUB y SDDM (con `sudo`). El vídeo
de SDDM se reutiliza de caché.

## Arranque

- `archdavid theme gruvbox --boot` fuerza la actualización del arranque en
  primer plano.
- `archdavid theme gruvbox --no-boot` solo aplica colores de usuario.
- `archdavid theme gruvbox --plymouth` incluye además el splash **estático** de
  Plymouth (reconstruye el initramfs una vez, en segundo plano).

Plymouth ya no se regenera en cada cambio de tema (era lo que hacía lento el
proceso). Queda fijo hasta que ejecutes `--plymouth`.

## Sin contraseña

Por defecto, la actualización de GRUB/SDDM en segundo plano pide `sudo`. Para
eliminarlo (una sola vez):

```sh
archdavid theme-passwordless enable
```

Esto instala `/usr/local/bin/theme-install` (root-owned) y la regla
`/etc/sudoers.d/archdavid-theme`, que **solo** permite al grupo `wheel`:

```
/usr/local/bin/theme-install --no-plymouth *
```

- Los cambios normales de tema (GRUB + SDDM) ya no piden contraseña.
- `--plymouth` sigue pidiendo contraseña (reconstruye initramfs).
- Desactivar: `archdavid theme-passwordless disable`.
- Seguridad: permite a `wheel` escribir el tema de GRUB/SDDM sin contraseña.
  Si no quieres ese riesgo, deja el prompt o usa
  `archdavid theme <id> --no-boot` (solo colores, sin tocar arranque).

## Fondos

Los fondos **no** se incluyen en el repo. Los temas esperan encontrarlos en:

```
~/.wallpapers/
```

Cada tema usa `WALLPAPER="$HOME/.wallpapers/<archivo>"`. Si el fondo no existe:

- se aplican igualmente los colores de usuario (kitty, Waybar, Hyprland, nvim,
  rofi y panel);
- no se cambia el fondo de pantalla ni el tema de arranque.

## Caché

Los assets de GRUB/SDDM/Plymouth se cachean por tema + contenido del fondo en
`~/.cache/theme-switcher/cache/render/`. Repetir un tema es instantáneo; solo
se regenera si cambia el `.conf` o el fondo. `--refresh` fuerza regeneración.

