#!/bin/bash
set -m
   
echo " "
echo "# ### ### ### ### ### ### ### #"
echo "# Executing custom entrypoint #"
echo "# ### ### ### ### ### ### ### #"
echo " "

echo " "
echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ###"
echo "# Modifying lsb_release / hostnamectl / ca-certificates #"
echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ###"
sh /custom.sh 
echo " "
echo "# ### ### ### #"
echo "# lsb_release #"
echo "# ### ### ### #"
/usr/bin/lsb_release
echo " "
echo "# ### ### ### #"
echo "# hostnamectl #"
echo "# ### ### ### #"
/usr/bin/hostnamectl
echo " "
echo "# ### ### ### ### ### ### #"
echo "# update-ca-certificates  #"
echo "# ### ### ### ### ### ### #"
update-ca-certificates
echo " "

echo " "
echo "[INFO] Forcing hostname to: $HOSTNAME"
echo " "
if [ -z "${HOSTNAME:-}" ]; then
    RAND_NUM=$(awk 'BEGIN { srand(); printf "%04d\n", int(1000 + rand()*9000) }')
    HOSTNAME="PC-$RAND_NUM"
fi

if hostname "$HOSTNAME" && echo "$HOSTNAME" > /etc/hostname; then
    echo " "
    echo "[INFO] Hostname successfully set to: $HOSTNAME"
    echo " "
else
    echo " "
    echo "[WARN] Failed to set hostname to: $HOSTNAME"
    echo "[WARN] Please check permissions or container capabilities."
    echo " "
fi

if eval "$(dbus-launch --sh-syntax)"; then
    echo " "
    echo "[INFO] D-Bus session launched."
    echo " "
else
    echo " "
    echo "[WARN] Failed to launch D-Bus session."
    echo " "
fi

if echo "$WIPTER_PASSWORD" | gnome-keyring-daemon --unlock --replace; then
    echo " "
    echo "[INFO] GNOME keyring unlocked successfully."
    echo " "
else
    echo " "
    echo "[WARN] Failed to unlock GNOME keyring — check password or environment."
    echo " "
fi

MASKED_PASSWORD=$(printf '*%.0s' $(seq ${#WIPTER_PASSWORD}))

setup_wipter() {
  KEYRING_SECRET=$(secret-tool search service com.wipter.auth.production 2>/dev/null \
                   | awk -F' = ' '/^secret = / {print $2; exit}')

  if [ -n "$KEYRING_SECRET" ] && [ "$KEYRING_SECRET" != "-" ]; then
      echo " "
      echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ##"
      echo "# [INFO] Valid Wipter keyring secret detected — skipping login #"
      echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ##"
      echo " "
      return 0
  else
      echo " "
      echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #"
      echo "# [WARN] No valid Wipter keyring secret detected — starting login process #"
      echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #"
      echo " "
  fi

  if [ -z "$WIPTER_EMAIL" ] || [ -z "$WIPTER_PASSWORD" ]; then
    echo " "
    echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###"
    echo "# [WARN] WIPTER_EMAIL or WIPTER_PASSWORD is not set. Please set both before running this script #"
    echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###"
    return 0
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
    echo " "
    echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #"
    echo "# [WARN] Wipter window was not found after waiting — exiting  #"
    echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #"
    echo " "
    exit 1
  fi

  wmctrl -ia "$WIPTER_WIN"
  sleep 5
  xte "key Tab"
  sleep 5
  xte "key Tab"
  sleep 5
  xte "key Tab"
  sleep 5
  echo " "
  echo "=== === === === === === === === === === === === ==="
  echo "[INFO] Typing EMAIL = $WIPTER_EMAIL"
  echo "=== === === === === === === === === === === === ==="
  echo " "
  xte "str $WIPTER_EMAIL"
  sleep 5
  xte "key Tab"
  sleep 5
  echo " "
  echo "=== === === === === === === === === === === === ==="
  echo "[INFO] Typing PASSWORD = $MASKED_PASSWORD"
  echo "=== === === === === === === === === === === === ==="
  echo " "
  xte "str $WIPTER_PASSWORD"
  sleep 5
  xte "key Return"
  echo " "
  echo "=== === === === === === === === === === === === ==="
  echo "[INFO] Wipter setup complete."
  echo "=== === === === === === === === === === === === ==="
  echo " "
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

echo " "
echo "# ### ### ### ### #"
echo "# Starting Wipter #"
echo "# ### ### ### ### #"
echo " "

if [[ -n "$DISCORD_WEBHOOK_URL" && "$DISCORD_WEBHOOK_URL" =~ ^https://discord\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+$ ]]; then
    echo " "
    echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #"
    echo "# [INFO] Valid Discord webhook detected — starting Discord loop in background #"
    echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #"
    echo " "
    discord_loop &
else
    echo " "
    echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #"
    echo "# [WARN] Discord webhook is missing or invalid                            #" 
    echo "# [WARN] Expected format: https://discord.com/api/webhooks/<id>/<token>   #"
    echo "# [WARN] Skipping Discord loop — please set DISCORD_WEBHOOK_URL correctly #"
    echo "# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #"
    echo " "
fi

/opt/Wipter/wipter-app &
sleep 5
setup_wipter