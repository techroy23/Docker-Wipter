# Docker-Wipter v1.25.888
  
## Overview
This repository provides a containerized environment for running the **Wipter desktop application** inside a lightweight Debian‑based image.  
The setup includes both **amd64/arm64**, headless X11 stack with **Xvfb**, **Openbox**, **x11vnc**, and **noVNC**.  

## Links
| DockerHub | GitHub | Invite |
|----------|----------|----------|
| [![Docker Hub](https://img.shields.io/badge/ㅤ-View%20on%20Docker%20Hub-blue?logo=docker&style=for-the-badge)](https://hub.docker.com/r/techroy23/docker-wipter) | [![GitHub Repo](https://img.shields.io/badge/ㅤ-View%20on%20GitHub-black?logo=github&style=for-the-badge)](https://github.com/techroy23/Docker-Wipter) | [![Invite Link](https://img.shields.io/badge/ㅤ-Join%20Wipter%20Now-brightgreen?logo=linktree&style=for-the-badge)](https://wipter.com/register?via=66075F1E60) |

The container also integrates:
- Automated **DBus** system/session bus initialization
- **gnome-keyring** for secure credential storage
- A scripted login flow for Wipter
- Optional **Discord webhook integration** for periodic screenshot reporting
- This design enables reproducible, isolated execution of the Wipter client with minimal host dependencies.

## Features
- **Debian Trixie Slim Base**  
  - Lightweight, up‑to‑date foundation with only required packages installed.

- **Headless GUI Stack**  
  - `Xvfb` virtual framebuffer for X11 rendering  
  - `openbox` as a minimal window manager  
  - `x11vnc` for VNC access  
  
- **Custom System Identity Simulation**  
  - `custom.sh` dynamically generates randomized host metadata (hostname, machine ID, vendor/model, firmware version/date)  
  - Overrides `lsb_release` and `hostnamectl` outputs for consistency

- **DBus & Keyring Integration**  
  - Automatic startup of system and session DBus daemons  
  - `gnome-keyring-daemon` for secrets management  

- **Automated Wipter Login**  
  - `entrypoint.sh` launches the Wipter client  
  - Uses `wmctrl` + `xautomation` to inject credentials `WIPTER_EMAIL` `WIPTER_PASSWORD` if no valid keyring secret is found.

- **Discord Webhook Reporting (Optional)**  
  - Periodic screenshots captured with `scrot`  
  - Uploaded to a configured Discord channel with hostname metadata

- **Resource Limits & Stability**  
  - File descriptor limits raised (`ulimit -n 65536`)  
  - Trap‑based startup sequencing with retries for Xvfb display allocation

## Run
```
docker run -d \
  --name=docker-wipter \
  --restart=always \
  --pull always \
  --shm-size=2gb \
  --privileged \
  -e WIPTER_EMAIL="YourEmail@here.com" \
  -e WIPTER_PASSWORD="your_secure_password" \
  -e DISCORD_WEBHOOK_INTERVAL=300 \
  -e DISCORD_WEBHOOK_URL="your_dicord_webhook_url" \
  techroy23/docker-wipter:latest
```

## Promo
<ul><li><a href="https://wipter.com/register?via=66075F1E60"> [ REGISTER HERE ] </a></li></ul>
<div align="center">
  <a width="50%" href="https://wipter.com/register?via=66075F1E60">
    <img src="https://raw.githubusercontent.com/techroy23/Docker-Wipter/refs/heads/main/screenshot/img0.png" alt="Alt text">
  </a>
</div>

## Screenshot
<div align="center">
  <img width="50%" src="https://raw.githubusercontent.com/techroy23/Docker-Wipter/refs/heads/main/screenshot/img1.png" alt="Alt text">
</div>




