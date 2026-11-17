# Temas y fondos

Los temas viven en `config/theme-switcher/` (enlazado a
`~/.config/theme-switcher`) y generan colores para kitty, Hyprland, Waybar,
rofi y Neovim, además de GRUB, Plymouth y SDDM.

## Fondos

Los fondos **no** se incluyen en el repo (pesan ~36 MB). Los temas esperan
encontrarlos en:

```
~/.wallpapers/
```

Cada tema usa `WALLPAPER="$HOME/.wallpapers/<archivo>"`. Si el fondo no existe,
`archdavid theme <id>` avisa y **no** cambia nada (ni colores ni arranque).

Para usar un tema:

1. Copia tus fondos a `~/.wallpapers/` con los nombres esperados por
   `config/theme-switcher/themes/*.conf`.
2. `archdavid theme gruvbox` (o el id que quieras).
3. El tema del sistema (GRUB/SDDM/Plymouth) se instala con `sudo` mediante
   `/usr/local/bin/theme-install`.

## Nota

Los ficheros de color generados del tema actual ya están en el repo, así que un
equipo recién instalado se ve correcto incluso sin fondos; solo no podrá
*cambiar* de tema hasta que añadas los fondos.
