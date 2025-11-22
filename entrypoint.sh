#!/bin/bash

set -e
mkdir -p /tmp/runtime-root
mkdir -p /run/dbus
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
export XDG_RUNTIME_DIR=/tmp/runtime-root
export NO_AT_BRIDGE=1
export DISPLAY=:0
export VNC_DISPLAY=":0"
DISPLAY=:0
VNC_DISPLAY=":0"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

# Allow override of ports via env vars, with fallback check
pick_port() {
    local port="$1"
    local attempts=0
    while [ $attempts -lt 2 ]; do
        if command -v lsof >/dev/null 2>&1; then
            # Try lsof
            if ! lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
                echo "$port"
                return
            fi
        elif command -v ss >/dev/null 2>&1; then
            # Fallback to ss
            if ! ss -ltn | awk '{print $4}' | grep -q ":$port$"; then
                echo "$port"
                return
            fi
        elif command -v netstat >/dev/null 2>&1; then
            # Final fallback to netstat
            if ! netstat -ltn | awk '{print $4}' | grep -q ":$port$"; then
                echo "$port"
                return
            fi
        else
            # No tool available, assume port is free
            echo "$port"
            return
        fi

        port=$((port + 1))
        attempts=$((attempts + 1))
    done
    echo "$port"
}

SLEEP_TIME=$(( RANDOM % 16 + 15 ))
log "Sleeping for $SLEEP_TIME seconds before selecting ports..."
sleep "$SLEEP_TIME"

VNC_PORT=$(pick_port "${VNC_PORT:-5910}")
NOVNC_PORT=$(pick_port "${NOVNC_PORT:-6080}")

echo " "
echo " "
log "Selected VNC port: $VNC_PORT"
log "Selected noVNC port: $NOVNC_PORT"
echo " "
echo " "

if [ -z "${WIPTER_EMAIL:-}" ]; then
    echo " >>> >>> [ERR] WIPTER_EMAIL is not set."
    exit 1
fi

if [ -z "${WIPTER_PASSWORD:-}" ]; then
    echo " >>> >>> [ERR] WIPTER_PASSWORD is not set."
    exit 1
fi

echo " >>> >>> Modifying lsb_release / hostnamectl"
sh /app/custom.sh 
/usr/bin/lsb_release
/usr/bin/hostnamectl

RAND_NUM=$(awk 'BEGIN { srand(); printf "%04d\n", int(1000 + rand()*9000) }')
HOSTNAME="PC-$RAND_NUM"
if hostname "$HOSTNAME" && echo "$HOSTNAME" > /etc/hostname; then
    echo " >>> >>> [INFO] Hostname successfully set to: $HOSTNAME"
else
    echo " >>> >>> [ERR] Failed to set hostname to: $HOSTNAME"
    echo " >>> >>> [ERR] Please check permissions or container capabilities."
fi

echo " >>> >>> [RUN] update-ca-certificates"
update-ca-certificates
sleep 2

echo " >>> >>> [RUN] dbus-uuidgen > /etc/machine-id"
dbus-uuidgen > /etc/machine-id
sleep 2

echo " >>> >>> [CHK] Checking for stale dbus pid file"
if [ -f /run/dbus/pid ] && ! pgrep -x dbus-daemon > /dev/null; then
    echo " >>> >>> [INFO] Removing stale /run/dbus/pid"
    rm -f /run/dbus/pid
fi

echo " >>> >>> [RUN] dbus-daemon --system --fork"
dbus-daemon --system --fork
sleep 2

echo " >>> >>> [RUN] dbus-daemon --session --fork --print-address --print-pid"
dbus_output=$(dbus-daemon --session --fork --print-address --print-pid)
DBUS_SESSION_BUS_ADDRESS=$(echo "$dbus_output" | head -n1)
DBUS_SESSION_BUS_PID=$(echo "$dbus_output" | tail -n1)
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID
sleep 2

max_attempts=999
attempt=0
while [ $attempt -lt $max_attempts ]; do
    new_display_num=$(shuf -i 100-10000 -n 1)
    export DISPLAY=":$new_display_num"
    export VNC_DISPLAY=":$new_display_num"
    DISPLAY=":$new_display_num"
    VNC_DISPLAY=":$new_display_num"
    Xvfb $DISPLAY -screen 0 1280x800x24 &
    if pgrep -x Xvfb > /dev/null; then
        echo " >>> >>> [RUN] Xvfb $DISPLAY -screen 0 1280x800x24"
        break
    else
        if [ $attempt -lt $((max_attempts - 1)) ]; then
            new_display_num=$(shuf -i 100-1000 -n 1)
            export DISPLAY=":$new_display_num"
            export VNC_DISPLAY=":$new_display_num"
            DISPLAY=":$new_display_num"
            VNC_DISPLAY=":$new_display_num"
        else
            echo "ERROR: Xvfb failed to start ..."
            exit 255
        fi
    fi
    attempt=$((attempt+1))
done
sleep 2

echo " >>> >>> [RUN] openbox"
openbox 2>/dev/null &
sleep 2

echo " >>> >>> [RUN] gnome-keyring-daemon --start --components=secrets"
gnome-keyring-daemon --start --components=secrets
sleep 2

echo " >>> >>> [RUN] $WIPTER_PASSWORD | gnome-keyring-daemon --unlock --replace"
echo "$WIPTER_PASSWORD" | gnome-keyring-daemon --unlock --replace
sleep 2

echo " >>> >>> [RUN] x11vnc -display $DISPLAY -rfbport $VNC_PORT -forever -shared -nopw -quiet"
x11vnc -display $DISPLAY -rfbport $VNC_PORT -forever -shared -nopw -quiet 2>/dev/null &
sleep 2

echo " >>> >>> [RUN] /opt/noVNC/utils/novnc_proxy --vnc 0.0.0.0:$VNC_PORT --listen 0.0.0.0:$NOVNC_PORT"
/opt/noVNC/utils/novnc_proxy --vnc 0.0.0.0:$VNC_PORT --listen 0.0.0.0:$NOVNC_PORT 2>/dev/null &
sleep 2

MASKED_PASSWORD=$(printf '*%.0s' $(seq ${#WIPTER_PASSWORD}))

setup_wipter() {
    KEYRING_SECRET=$(secret-tool search service com.wipter.auth.production 2>/dev/null \
        | awk -F' = ' '/^secret = / {print $2; exit}')

    if [ -n "$KEYRING_SECRET" ] && [ "$KEYRING_SECRET" != "-" ]; then
        echo " >>> >>> [INFO] Valid Wipter keyring secret detected — skipping login"
        return 0
    else
        echo " >>> >>> [INFO] No valid Wipter keyring secret detected — starting login process"
    fi

    local WIPTER_WIN=""
    local attempts=0
    while [ -z "$WIPTER_WIN" ] && [ $attempts -lt 30 ]; do
        WIPTER_INFO=$(wmctrl -l | grep -i "Wipter")
        if [ -n "$WIPTER_INFO" ]; then
            WIPTER_WIN=$(echo "$WIPTER_INFO" | head -n 1 | awk '{print $1}')
            break
        fi
        sleep 5
        attempts=$((attempts+1))
    done

    if [ -z "$WIPTER_WIN" ]; then
        echo " >>> >>> [ERR] Wipter window was not found after waiting — exiting"
        exit 1
    fi

    wmctrl -ia "$WIPTER_WIN"
    sleep 3
    xte "key Tab"
    sleep 3
    xte "key Tab"
    sleep 3
    xte "key Tab"
    sleep 3
    echo " >>> >>> [INFO] Typing EMAIL = $WIPTER_EMAIL"
    xte "str $WIPTER_EMAIL"
    sleep 3
    xte "key Tab"
    sleep 3
    echo " >>> >>> [INFO] Typing PASSWORD = $MASKED_PASSWORD"
    xte "str $WIPTER_PASSWORD"
    sleep 3
    xte "key Return"
    echo " >>> >>> [INFO] Wipter setup complete."
    return 0
}

discord_loop() {
    DISCORD_WEBHOOK_INTERVAL=${DISCORD_WEBHOOK_INTERVAL:-300}
    local SCREENSHOT_PATH="/tmp/screenshot.png"
    local DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
    local HOSTNAME="$HOSTNAME"

    while true; do
        scrot -o -D "$DISPLAY" "$SCREENSHOT_PATH"
        curl -s -o /dev/null -X POST "$DISCORD_WEBHOOK_URL" \
            -F "file=@$SCREENSHOT_PATH" \
            -F "payload_json={\"embeds\": [{\"title\": \"Docker Hostname: $HOSTNAME\", \"color\": 5814783}]}"
        sleep "$DISCORD_WEBHOOK_INTERVAL"
    done
}

echo " >>> >>> Starting Wipter "

if [[ -n "$DISCORD_WEBHOOK_URL" && "$DISCORD_WEBHOOK_URL" =~ ^https://discord\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+$ ]]; then
    echo " >>> >>> [INFO] Valid Discord webhook detected — starting Discord loop in background"
    discord_loop &
else
    echo " >>> >>> [WARN] Discord webhook is missing or invalid"
    echo " >>> >>> [WARN] Expected format: https://discord.com/api/webhooks/<id>/<token>"
    echo " >>> >>> [WARN] Skipping Discord loop — please set DISCORD_WEBHOOK_URL correctly"
fi

/opt/Wipter/wipter-app &
sleep 5
setup_wipter

echo " >>> >>> [RUN] tail -f /dev/null"
tail -f /dev/null
