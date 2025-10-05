FROM debian:trixie-slim

ARG TARGETARCH

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates dos2unix bash curl wget gdebi git procps net-tools coreutils util-linux iproute2 scrot gnome-keyring libsecret-tools wmctrl xautomation \
		dbus dbus-x11 openbox menu xterm xvfb x11vnc python3-numpy \
        xfonts-base xfonts-75dpi xfonts-100dpi xfonts-scalable \
		libappindicator3-1 libasound2 libatspi2.0-0 libgtk-3-0 libnotify4 libnss3 libsecret-1-0 libuuid1 libxss1 libxtst6 xdg-utils \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 https://github.com/novnc/noVNC /opt/noVNC \
    && git clone --depth=1 https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && cp /opt/noVNC/vnc.html /opt/noVNC/index.html \
    && chmod +x /opt/noVNC/utils/novnc_proxy

RUN if [ "$TARGETARCH" = "amd64" ]; then \
        url="https://provider-assets.wipter.com/latest/linux/x64/wipter-app-amd64.deb"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        url="https://provider-assets.wipter.com/latest/linux/arm64/wipter-app-arm64.deb"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi \
    && wget -O /tmp/wipter.deb "$url" \
    && gdebi --n /tmp/wipter.deb \
    && rm /tmp/wipter.deb

RUN printf '#!/bin/sh \n echo "%s"' "$(lsb_release -a)" > /usr/bin/lsb_release \
    && printf '#!/bin/sh \n echo "%s"' "$(hostnamectl)" > /usr/bin/hostnamectl

COPY entrypoint.sh /app/entrypoint.sh

COPY custom.sh /app/custom.sh

RUN dos2unix /app/entrypoint.sh

RUN dos2unix /app/custom.sh

RUN chmod a+x /app/entrypoint.sh /app/custom.sh /usr/bin/hostnamectl /usr/bin/lsb_release

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["bash"]