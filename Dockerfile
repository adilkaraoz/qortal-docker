FROM alpine:3.19

RUN apk add --no-cache bash curl ca-certificates docker-cli tzdata

WORKDIR /opt
COPY qortal /opt/qortal
COPY automation/run-build.sh /usr/local/bin/run-build
COPY automation/crontab /etc/crontabs/root

RUN chmod +x /usr/local/bin/run-build && mkdir -p /var/log && chmod 644 /etc/crontabs/root

# Default Docker socket for talking to host/sidecar daemon.
ENV DOCKER_HOST=unix:///var/run/docker.sock

# BusyBox crond in foreground, verbose logging
CMD ["crond", "-f", "-l", "8", "-c", "/etc/crontabs"]
