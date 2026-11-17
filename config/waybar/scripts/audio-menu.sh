#!/usr/bin/env bash
set -u

THEME="$HOME/.config/rofi/menu.rasi"
BAR_WIDTH=24

volume_pct() {
    pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null |
        grep -o '[0-9]\+%' | head -n1 | tr -d '%'
}

is_muted() {
    [[ $(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}') == yes ]]
}

slider_bar() {
    local vol=$1 filled i bar=""
    ((vol > 100)) && vol=100
    ((vol < 0)) && vol=0
    filled=$((vol * BAR_WIDTH / 100))
    ((filled >= BAR_WIDTH)) && filled=$((BAR_WIDTH - 1))
    for ((i = 0; i < filled; i++)); do bar+="━"; done
    bar+="●"
    for ((i = filled + 1; i < BAR_WIDTH; i++)); do bar+="─"; done
    printf '%s' "$bar"
}

emit_options() {
    local prompt=$1
    printf '\0use-hot-keys\x1ftrue\n'
    printf '\0no-custom\x1ftrue\n'
    printf '\0prompt\x1f%s\n' "$prompt"
}

row() {
    local label=$1 info=${2:-}
    if [[ ${LIST_ONLY:-0} == 1 ]]; then
        printf '%s\n' "$label"
        return
    fi
    if [[ -n $info ]]; then
        printf '%s\0info\x1f%s\n' "$label" "$info"
    else
        printf '%s\n' "$label"
    fi
}

header() {
    if [[ ${LIST_ONLY:-0} == 1 ]]; then
        printf '%s\n' "$1"
        return
    fi
    printf '%s\0nonselectable\x1ftrue\n' "$1"
}

list_nodes() {
    local kind=$1
    if [[ $kind == sink ]]; then
        pactl list sinks 2>/dev/null
    else
        pactl list sources 2>/dev/null
    fi | awk '
        /^\tName: / { n = substr($0, index($0, ": ") + 2) }
        /^\tDescription: / { print n "\t" substr($0, index($0, ": ") + 2) }
    '
}

list_profiles() {
    pactl list cards 2>/dev/null | awk '
    function flush(   i) {
        for (i = 1; i <= n; i++)
            print card "\t" desc "\t" active "\t" pk[i] "\t" pl[i]
        n = 0
    }
    /^\tName: / {
        flush()
        card = substr($0, index($0, ": ") + 2)
        desc = card
        active = ""
        n = 0
        next
    }
    /^\t\tdevice\.description = / {
        desc = substr($0, index($0, "= ") + 2)
        gsub(/^"|"$/, "", desc)
        next
    }
    /^\tProfiles:$/ { inprof = 1; next }
    /^\tActive Profile: / {
        active = substr($0, index($0, ": ") + 2)
        inprof = 0
        flush()
        next
    }
    inprof && /^\t\t/ {
        line = substr($0, 3)
        key = substr(line, 1, index(line, ": ") - 1)
        rest = substr(line, index(line, ": ") + 2)
        if (rest !~ /available: yes/) next
        if (key == "off") next
        pdesc = rest
        sub(/ \(sinks:.*\)$/, "", pdesc)
        label = pdesc
        if (key ~ /^a2dp-sink/) {
            if (pdesc ~ /codec /) {
                codec = pdesc
                sub(/.*codec /, "", codec)
                sub(/\).*/, "", codec)
                label = "A2DP · " codec
            } else {
                label = "A2DP"
            }
        } else if (key ~ /^headset-head-unit/) {
            if (pdesc ~ /codec /) {
                codec = pdesc
                sub(/.*codec /, "", codec)
                sub(/\).*/, "", codec)
                label = "HSP/HFP · " codec
            } else {
                label = "HSP/HFP"
            }
        }
        pk[++n] = key
        pl[n] = label
        next
    }
    END { flush() }
    '
}

set_sink() {
    local name=$1 id
    pactl set-default-sink "$name" >/dev/null
    while read -r id; do
        [[ -z ${id:-} ]] && continue
        pactl move-sink-input "$id" "$name" >/dev/null 2>&1
    done < <(pactl list short sink-inputs 2>/dev/null | cut -f1)
}

main_view() {
    [[ ${LIST_ONLY:-0} == 1 ]] || emit_options "Volumen (←/→)"

    local vol mute_label default_sink default_source name desc mark
    vol=$(volume_pct)
    vol=${vol:-0}

    if is_muted; then
        mute_label="󰕾 Activar sonido"
    else
        mute_label="󰖁 Silenciar"
    fi

    row "󰕾  $(slider_bar "$vol")  ${vol}%" "slider"
    row "$mute_label" "act|mute"

    default_sink=$(pactl get-default-sink 2>/dev/null)
    while IFS=$'\t' read -r name desc; do
        [[ -z ${name:-} ]] && continue
        [[ -z ${desc:-} ]] && desc=$name
        [[ $name == "$default_sink" ]] && mark="●" || mark="○"
        row "$mark  󰓃 $desc" "sink|$name"
    done < <(list_nodes sink)

    default_source=$(pactl get-default-source 2>/dev/null)
    while IFS=$'\t' read -r name desc; do
        [[ -z ${name:-} ]] && continue
        [[ $name == *.monitor ]] && continue
        [[ -z ${desc:-} ]] && desc=$name
        [[ $name == "$default_source" ]] && mark="●" || mark="○"
        row "$mark  󰍬 $desc" "source|$name"
    done < <(list_nodes source)

    row "󰒓 Perfiles y códecs…" "view|profiles"
}

profile_view() {
    [[ ${LIST_ONLY:-0} == 1 ]] || emit_options "Perfiles y códecs"

    local card cdesc active key label current="" mark
    while IFS=$'\t' read -r card cdesc active key label; do
        [[ -z ${card:-} ]] && continue
        if [[ $card != "$current" ]]; then
            header "$cdesc"
            current=$card
        fi
        [[ $key == "$active" ]] && mark="●" || mark="○"
        row "$mark  $label" "profile|$card|$key"
    done < <(list_profiles)

    row "  ← Volver" "view|main"
}

if [[ ${1:-} == --list ]]; then
    LIST_ONLY=1
    main_view
    exit 0
fi

if [[ ${1:-} == --list-profiles ]]; then
    LIST_ONLY=1
    profile_view
    exit 0
fi

if [[ -z ${ROFI_RETV:-} ]]; then
    exec rofi -show audio \
        -modes "audio:$0" \
        -theme "$THEME" \
        -theme-str 'window { width: 600px; } listview { lines: 12; }' \
        -kb-move-char-back "Control+b" \
        -kb-move-char-forward "Control+f" \
        -kb-custom-1 "Left,Alt+h" \
        -kb-custom-2 "Right,Alt+l"
fi

view=${ROFI_DATA:-main}
retv=${ROFI_RETV:-0}
info=${ROFI_INFO:-}

if [[ $retv == 10 || $retv == 11 ]]; then
    if [[ $view == main ]]; then
        vol=$(volume_pct)
        vol=${vol:-0}
        if [[ $retv == 10 ]]; then
            vol=$((vol - 5))
        else
            vol=$((vol + 5))
        fi
        ((vol < 0)) && vol=0
        ((vol > 150)) && vol=150
        pactl set-sink-volume @DEFAULT_SINK@ "${vol}%" >/dev/null 2>&1
    fi
elif [[ $retv == 1 ]]; then
    case $info in
        act\|mute) pactl set-sink-mute @DEFAULT_SINK@ toggle >/dev/null ;;
        sink\|*) set_sink "${info#sink|}" ;;
        source\|*) pactl set-default-source "${info#source|}" >/dev/null ;;
        profile\|*)
            rest=${info#profile|}
            card=${rest%%|*}
            key=${rest#*|}
            pactl set-card-profile "$card" "$key" >/dev/null
            sleep 0.5
            view=main
            ;;
        view\|profiles) view=profiles ;;
        view\|main) view=main ;;
        slider) : ;;
    esac
fi

if [[ $view == profiles ]]; then
    printf '\0data\x1fprofiles\n'
    profile_view
else
    printf '\0data\x1f\n'
    main_view
fi
