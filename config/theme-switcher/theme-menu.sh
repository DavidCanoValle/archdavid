#!/bin/bash
set -euo pipefail

DIR="$HOME/.config/theme-switcher"
current=$(cat "$DIR/current" 2>/dev/null || echo david)

ids=()
rows=()
for conf in "$DIR"/themes/*.conf; do
    [[ -f "$conf" ]] || continue
    id=$(basename "$conf" .conf)
    # shellcheck disable=SC1090
    name=$(sed -n 's/^NAME="\(.*\)"$/\1/p' "$conf")
    accent=$(sed -n 's/^ACCENT="\(.*\)"$/\1/p' "$conf")
    ids+=("$id")
    if [[ "$id" == "$current" ]]; then
        rows+=("<span foreground='$accent'>●</span>  <b>$name</b>  <span foreground='#5b6b8c'>(activo)</span>")
    else
        rows+=("<span foreground='$accent'>●</span>  $name")
    fi
done

selection=$(
    printf '%s\n' "${rows[@]}" |
        rofi -dmenu -i -markup-rows -format i -p "Tema" \
            -theme "$HOME/.config/rofi/menu.rasi"
) || exit 0

[[ -n "$selection" ]] || exit 0
"$DIR/theme-apply.sh" "${ids[$selection]}"
