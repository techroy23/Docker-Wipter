# Docker-Wipter
   
## Overview
This repository provides a Dockerized solution for running Wipter. The setup uses `ghcr.io/techroy23/docker-slimvnc:latest` as base image to ensure minimal system overhead and integrates all necessary dependencies for seamless operation.

## Features
- Lightweight Debian-based image (`ghcr.io/techroy23/docker-slimvnc:latest`).
- Automated installation of required dependencies.
- Automated Wipter login via  `WIPTER_EMAIL` `WIPTER_PASSWORD`.
- VNC password can be set via `VNC_PASS`.

## Run
```

docker run -d --name docker-wipter \
  -e WIPTER_EMAIL="YourEmail@here.com" \
  -e WIPTER_PASSWORD="your_secure_password" \
  -e DISCORD_WEBHOOK_INTERVAL=300 \
  -e DISCORD_WEBHOOK_URL="your_dicord_webhook_url" \
  -e VNC_PASS="your_secure_password" \
  -e VNC_PORT=5900 \
  -e NOVNC_PORT=6080 \
  -p 5900:5900 -p 6080:6080 \
  --shm-size=2gb \
  ghcr.io/techroy23/docker-wipter:latest

```

## Access
- VNC Client: localhost:5900
- Web Interface (noVNC): http://localhost:6080

## Promo
<ul><li><a href="https://wipter.com/register?via=66075F1E60"> [ REGISTER HERE ] </a></li></ul>
<div align="center">
  <a href="https://wipter.com/register?via=66075F1E60">
    <img src="screenshot/img0.png" alt="Alt text">
  </a>
</div>

## Screenshot
<div align="center">
  <img src="screenshot/img1.png" alt="Alt text">
</div>








