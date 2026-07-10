#!/bin/sh
set -u

config="pill"
method="${1-}"

focused_monitor() {
    monitor="$(hyprctl monitors 2>/dev/null | awk '
        /^Monitor / { monitor = $2 }
        /^[[:space:]]*focused: yes$/ { print monitor; exit }
    ')"

    if [ -z "$monitor" ]; then
        monitor="$(hyprctl --instance 0 monitors 2>/dev/null | awk '
            /^Monitor / { monitor = $2 }
            /^[[:space:]]*focused: yes$/ { print monitor; exit }
        ')"
    fi

    printf '%s\n' "$monitor"
}

if [ -z "$method" ]; then
    exit 2
fi
shift

if [ "$#" -eq 0 ] && [ "$method" != "hide" ]; then
    monitor="$(focused_monitor)"
    [ -n "$monitor" ] || exit 1
    set -- "$monitor"
fi

if ! qs -c "$config" ipc show >/dev/null 2>&1; then
    /home/stivi/.config/hypr/scripts/watchdog.sh "$config" >/dev/null 2>&1 &

    i=0
    while [ "$i" -lt 50 ]; do
        qs -c "$config" ipc show >/dev/null 2>&1 && break
        sleep 0.1
        i=$((i + 1))
    done
fi

exec qs -c "$config" ipc call "$config" "$method" "$@"
