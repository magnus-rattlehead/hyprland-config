#!/bin/sh
# Hypridle starts this after 15 idle minutes and stops it on activity.
wait_pid=
trap 'if [ -n "$wait_pid" ]; then kill "$wait_pid" 2>/dev/null; fi; exit 0' TERM INT

while pgrep -f '(^|/|[[:space:]])[e]merge([[:space:]]|$)' > /dev/null; do
    sleep 900 &
    wait_pid=$!
    wait "$wait_pid"
    wait_pid=
done

loginctl suspend
