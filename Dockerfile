FROM ghcr.io/techroy23/docker-slimvnc:latest
  
ENV DEBIAN_FRONTEND=noninteractive
 
RUN apt-get update -y
RUN apt-get install -y net-tools gnome-keyring xautomation wmctrl libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libuuid1 libsecret-1-0

RUN wget -O /tmp/wipter.deb https://provider-assets.wipter.com/latest/linux/x64/wipter-app-amd64.deb && \
    gdebi --n /tmp/wipter.deb && \
    rm /tmp/wipter.deb

RUN apt-get autoclean && apt-get autoremove -y && apt-get autopurge -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN printf '#!/bin/sh \n echo "%s"' "$(lsb_release -a)" > /usr/bin/lsb_release && \
    printf '#!/bin/sh \n echo "%s"' "$(hostnamectl)" > /usr/bin/hostnamectl && \
    chmod a+x /usr/bin/hostnamectl /usr/bin/lsb_release

COPY custom.sh /custom.sh

COPY custom-entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh
