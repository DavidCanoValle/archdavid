#!/bin/bash
# Estado del sistema para el panel (JSON en una linea)

vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
volume=0
muted=false
if [[ -n "$vol_raw" ]]; then
    volume=$(awk '{printf "%d", $2 * 100}' <<<"$vol_raw")
    [[ "$vol_raw" == *MUTED* ]] && muted=true
fi

bright=0
if command -v brightnessctl >/dev/null 2>&1; then
    bright=$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4); print $4}')
fi

wifi=false
ssid=""
if command -v nmcli >/dev/null 2>&1; then
    [[ "$(nmcli -t -f WIFI g 2>/dev/null)" == "enabled" ]] && wifi=true
    ssid=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="802-11-wireless"{print $1; exit}')
fi

bt=false
if command -v bluetoothctl >/dev/null 2>&1; then
    bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && bt=true
fi

bat=0
batstate=""
for b in /sys/class/power_supply/BAT*; do
    [[ -r "$b/capacity" ]] || continue
    bat=$(cat "$b/capacity" 2>/dev/null || echo 0)
    batstate=$(cat "$b/status" 2>/dev/null || echo "")
    break
done

cpu=0
if [[ -r /proc/stat ]]; then
    read -r _ u n s i w irq sirq _ < /proc/stat
    total=$((u + n + s + i + w + irq + sirq))
    idle=$((i + w))
    prev=/tmp/theme-switcher-cpu
    if [[ -r $prev ]]; then
        read -r pt pi < "$prev"
        dt=$((total - pt)); di=$((idle - pi))
        if ((dt > 0)); then cpu=$(((dt - di) * 100 / dt)); fi
    fi
    printf '%s %s\n' "$total" "$idle" > "$prev"
fi

mem=0
if command -v free >/dev/null 2>&1; then
    mem=$(free | awk '/^Mem:/{printf "%d", $3*100/$2}')
fi

uptime=$(uptime -p 2>/dev/null | sed 's/^up //')
profile=$(powerprofilesctl get 2>/dev/null || true)
ws=$(hyprctl activeworkspace 2>/dev/null | sed -n 's/^workspace ID \([0-9]*\).*/\1/p' | head -1)
wtitle=$(hyprctl activewindow 2>/dev/null | sed -n 's/^[[:space:]]*title: //p' | head -1)
[[ -z "$wtitle" ]] && wtitle=$(hyprctl activewindow 2>/dev/null | sed -n 's/^[[:space:]]*class: //p' | head -1)
media=""
playing=false
if command -v playerctl >/dev/null 2>&1; then
    if [[ "$(playerctl status 2>/dev/null)" == "Playing" ]]; then
        playing=true
        media=$(playerctl metadata --format '{{artist}} — {{title}}' 2>/dev/null)
    fi
fi

host=$(uname -n)

export P_VOLUME="$volume" P_MUTED="$muted" P_BRIGHT="$bright" P_WIFI="$wifi" \
       P_SSID="$ssid" P_BT="$bt" P_BAT="$bat" P_BATSTATE="$batstate" P_CPU="$cpu" \
       P_MEM="$mem" P_UPTIME="$uptime" P_PROFILE="$profile" P_WS="$ws" \
       P_WTITLE="$wtitle" P_MEDIA="$media" P_PLAYING="$playing" P_HOST="$host"

python3 - <<'PY'
import json, os
def b(v): return v == "true"
print(json.dumps({
    "volume": int(os.environ["P_VOLUME"] or 0),
    "muted": b(os.environ["P_MUTED"]),
    "bright": int(os.environ["P_BRIGHT"] or 0),
    "wifi": b(os.environ["P_WIFI"]),
    "ssid": os.environ["P_SSID"],
    "bt": b(os.environ["P_BT"]),
    "bat": int(os.environ["P_BAT"] or 0),
    "batstate": os.environ["P_BATSTATE"],
    "cpu": int(os.environ["P_CPU"] or 0),
    "mem": int(os.environ["P_MEM"] or 0),
    "uptime": os.environ["P_UPTIME"],
    "profile": os.environ["P_PROFILE"],
    "ws": os.environ["P_WS"],
    "wtitle": os.environ["P_WTITLE"],
    "media": os.environ["P_MEDIA"],
    "playing": b(os.environ["P_PLAYING"]),
    "host": os.environ["P_HOST"],
}, ensure_ascii=False))
PY
