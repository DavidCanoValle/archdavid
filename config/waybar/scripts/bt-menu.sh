#!/usr/bin/env bash
set -u

THEME="$HOME/.config/rofi/menu.rasi"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/bt-menu.lock"
LOG="${XDG_RUNTIME_DIR:-/tmp}/bt-menu.log"
ROFI=(rofi -dmenu -i -no-custom -theme "$THEME")

exec 9>"$LOCK"
flock -n 9 || exit 0

power_on() { bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; }
is_scanning() { bluetoothctl show 2>/dev/null | grep -q 'Discovering: yes'; }

mac_like() {
    local s=${1:-}
    s=${s//-/:}
    s=${s^^}
    [[ $s =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]
}

notify() { notify-send -a Bluetooth "$@" >/dev/null 2>&1 || true; }

remote_state() {
    local info
    info=$(bluetoothctl info "$1" 2>/dev/null)
    if grep -q 'Connected: yes' <<<"$info"; then
        echo connected
    elif grep -q 'Paired: yes' <<<"$info"; then
        echo paired
    else
        echo known
    fi
}

bt_run() {
    local out
    out=$(timeout 45 bluetoothctl "$@" 2>&1)
    printf '[%s] bluetoothctl %s\n%s\n' "$(date '+%F %T')" "$*" "$out" >>"$LOG"
    BT_OUT=$out
    grep -qiE 'succeed|successful|already' <<<"$out"
}

pair_error_hint() {
    case $1 in
        *AuthenticationRejected*)
            echo "Emparejamiento rechazado. Pon los auriculares en modo emparejamiento y desconéctalos de otros equipos (móvil, tablet…)." ;;
        *InProgress*)
            echo "Emparejamiento en curso; espera unos segundos y vuelve a intentarlo." ;;
        *AlreadyExists*)
            echo "El dispositivo ya estaba emparejado." ;;
        *NotFound*|*not\ available*|*Timed\ out*)
            echo "No se encontró el dispositivo. Acércalo y vuelve a escanear." ;;
        *)
            echo "No se pudo emparejar. Acércalo, ponlo en modo emparejamiento y reintenta." ;;
    esac
}

toggle_device() {
    local mac=$1 name=$2 state
    state=$(remote_state "$mac")
    case $state in
        connected)
            if bt_run disconnect "$mac"; then
                notify "Desconectado" "$name"
            else
                notify -u normal "No se pudo desconectar" "$name"
            fi
            ;;
        paired)
            bt_run trust "$mac" || true
            if bt_run connect "$mac"; then
                notify "Conectado" "$name"
            else
                notify -u normal "No se pudo conectar" "$name"
            fi
            ;;
        *)
            if bt_run pair "$mac"; then
                bt_run trust "$mac" || true
                if bt_run connect "$mac"; then
                    notify "Emparejado y conectado" "$name"
                else
                    notify "Emparejado" "$name — conexión pendiente"
                fi
            else
                notify -u critical "Error al emparejar $name" "$(pair_error_hint "$BT_OUT")"
            fi
            ;;
    esac
}

build_menu() {
    labels=()
    macs=()
    names=()
    acts=()
    local mac name state scanning=no

    if ! power_on; then
        labels+=("  Encender Bluetooth")
        macs+=("")
        names+=("")
        acts+=("on")
        return
    fi

    is_scanning && scanning=yes

    while read -r _ mac name; do
        [[ -z ${mac:-} ]] && continue
        state=$(remote_state "$mac")
        if [[ -z ${name:-} ]] || mac_like "$name"; then
            [[ $state == known ]] && continue
            name="Dispositivo ${mac: -5}"
        fi
        case $state in
            connected) labels+=("●  $name") ;;
            paired) labels+=("○  $name") ;;
            *) labels+=("·  $name") ;;
        esac
        macs+=("$mac")
        names+=("$name")
        acts+=("toggle")
    done < <(bluetoothctl devices 2>/dev/null)

    if [[ $scanning == yes ]]; then
        labels+=("  Detener escaneo")
        acts+=("scan_off")
    else
        labels+=("  Escanear dispositivos")
        acts+=("scan_on")
    fi
    labels+=("  Actualizar lista")
    acts+=("refresh")
    labels+=("  Apagar Bluetooth")
    acts+=("off")
}

show_menu() {
    build_menu

    if [[ ${1:-} == --list ]]; then
        printf '%s\n' "${labels[@]}"
        return 0
    fi

    local prompt="Bluetooth" chosen idx=-1 i
    is_scanning && prompt="Bluetooth · escaneando…"

    chosen=$(
        printf '%s\n' "${labels[@]}" | "${ROFI[@]}" -p "$prompt"
    ) || exit 0
    [[ -z $chosen ]] && exit 0

    for i in "${!labels[@]}"; do
        if [[ ${labels[i]} == "$chosen" ]]; then
            idx=$i
            break
        fi
    done
    ((idx < 0)) && exit 0

    case ${acts[idx]} in
        on)
            if bt_run power on; then notify "Bluetooth" "Activado"; else notify -u normal "Bluetooth" "No se pudo activar"; fi
            ;;
        off)
            if bt_run power off; then notify "Bluetooth" "Desactivado"; else notify -u normal "Bluetooth" "No se pudo desactivar"; fi
            ;;
        scan_on)
            bluetoothctl --timeout 20 scan on >/dev/null 2>&1 &
            notify "Bluetooth" "Escaneando dispositivos durante 20 s…"
            sleep 2
            ;;
        scan_off) bluetoothctl scan off >/dev/null 2>&1 ;;
        refresh) : ;;
        toggle) toggle_device "${macs[idx]}" "${names[idx]}" ;;
        *) exit 0 ;;
    esac
}

if [[ ${1:-} == --list ]]; then
    show_menu --list
    exit 0
fi

while true; do
    show_menu
done
