FROM debian:bookworm-slim

ARG HLDS_BETA=steam_legacy
ARG REHLDS_VERSION=3.14.0.857
ARG REGAMEDLL_VERSION=5.28.0.756
ARG METAMOD_R_VERSION=1.3.0.149
ARG AMXX_VERSION=1.10.0-git5467
ARG REAPI_VERSION=5.26.0.338

ENV HLDS_DIR=/opt/hlds \
    LD_LIBRARY_PATH=/opt/hlds

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip lib32gcc-s1 lib32stdc++6 libc6-i386 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --create-home --home-dir /home/hlds --shell /usr/sbin/nologin hlds

RUN mkdir -p /opt/steamcmd \
 && curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    | tar -xz -C /opt/steamcmd \
 && for attempt in 1 2 3 4 5; do \
      /opt/steamcmd/steamcmd.sh +force_install_dir "$HLDS_DIR" +login anonymous \
        +app_set_config 90 mod cstrike \
        +app_update 90 -beta "$HLDS_BETA" validate +quit; \
      [ -f "$HLDS_DIR/cstrike/liblist.gam" ] && break; \
      echo "steamcmd attempt $attempt incomplete, retrying"; \
    done \
 && test -f "$HLDS_DIR/cstrike/liblist.gam" \
 && mkdir -p /home/hlds/.steam/sdk32 \
 && cp /opt/steamcmd/linux32/steamclient.so /home/hlds/.steam/sdk32/steamclient.so

RUN set -eu; \
    fetch_zip() { rm -rf /tmp/pkg && mkdir /tmp/pkg && curl -fsSL "$1" -o /tmp/pkg.zip && unzip -q /tmp/pkg.zip -d /tmp/pkg && rm /tmp/pkg.zip; }; \
    gh=https://github.com/rehlds; \
    fetch_zip "$gh/ReHLDS/releases/download/$REHLDS_VERSION/rehlds-bin-$REHLDS_VERSION.zip"; \
    cp -a /tmp/pkg/bin/linux32/. "$HLDS_DIR/"; \
    fetch_zip "$gh/ReGameDLL_CS/releases/download/$REGAMEDLL_VERSION/regamedll-bin-$REGAMEDLL_VERSION.zip"; \
    cp -a /tmp/pkg/bin/linux32/cstrike/. "$HLDS_DIR/cstrike/"; \
    fetch_zip "$gh/Metamod-R/releases/download/$METAMOD_R_VERSION/metamod-bin-$METAMOD_R_VERSION.zip"; \
    cp -a /tmp/pkg/addons "$HLDS_DIR/cstrike/"; \
    for pkg in base cstrike; do \
      curl -fsSL "https://www.amxmodx.org/amxxdrop/1.10/amxmodx-$AMXX_VERSION-$pkg-linux.tar.gz" \
        | tar -xz -C "$HLDS_DIR/cstrike"; \
    done; \
    fetch_zip "$gh/ReAPI/releases/download/$REAPI_VERSION/reapi-bin-$REAPI_VERSION.zip"; \
    cp -a /tmp/pkg/addons "$HLDS_DIR/cstrike/"; \
    rm -rf /tmp/pkg; \
    sed -i 's|^gamedll_linux.*|gamedll_linux "addons/metamod/metamod_i386.so"|' "$HLDS_DIR/cstrike/liblist.gam"; \
    chmod +x "$HLDS_DIR/hlds_linux"

COPY plugins/ /tmp/plugins/
RUN set -eu; \
    scripting="$HLDS_DIR/cstrike/addons/amxmodx/scripting"; \
    for sma in /tmp/plugins/addons/amxmodx/scripting/*.sma; do \
      [ -e "$sma" ] || continue; \
      out="$HLDS_DIR/cstrike/addons/amxmodx/plugins/$(basename "$sma" .sma).amxx"; \
      (cd "$scripting" && ./amxxpc "$sma" -i"$scripting/include" -i/tmp/plugins/addons/amxmodx/scripting/include -o"$out"); \
      test -s "$out"; \
    done; \
    cp -a /tmp/plugins/. "$HLDS_DIR/cstrike/"; \
    rm -rf /tmp/plugins

COPY cstrike/ /opt/hlds/cstrike/
RUN echo 'exec addons/amxmodx/configs/nostalgia.cfg' >> "$HLDS_DIR/cstrike/addons/amxmodx/configs/amxx.cfg" \
 && chown -R hlds:hlds "$HLDS_DIR" /home/hlds

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /opt/hlds
EXPOSE 27015/udp
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
