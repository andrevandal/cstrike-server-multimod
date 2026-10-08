FROM debian:bookworm-slim

RUN set -eu; \
    sed -i "s/^Components: main$/Components: main non-free/" /etc/apt/sources.list.d/debian.sources; \
    apt-get update -qq; \
    apt-get install -y -qq --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      unzip \
      p7zip-full \
      p7zip-rar \
      file \
      zip; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY scripts/ /app/scripts/
COPY server/plugins/assets/ /app/server/plugins/assets/

ENTRYPOINT ["/app/scripts/init-content.sh"]
