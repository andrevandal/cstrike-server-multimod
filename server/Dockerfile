FROM debian:bookworm-slim

# Pins are bumped by scripts/update-versions.sh (latest stable releases).
ARG HLDS_BETA=steam_legacy
ARG REHLDS_VERSION=3.15.0.896
ARG REGAMEDLL_VERSION=5.30.0.814
ARG METAMOD_R_VERSION=1.3.0.149
ARG AMXX_VERSION=1.10.0-git5486
ARG REAPI_VERSION=5.29.0.358
ARG REUNION_VERSION=0.2.0.25
# WHBlocker is closed-source and dev-cs.ru no longer serves it; take PluginyCS/BasePack's copy at a
# release commit and refuse anything whose checksum changed.
ARG BASEPACK_REF=6b92574741cb09ae39076eede326557ff95b7e56
ARG WHBLOCKER_SHA256=cba69733648518a90718c367634467e14f0055814293be0c7a40b4ac85bc84c1
# PodBot is fetched from its upstream release and protected by its archive checksum.
ARG PODBOT_URL=https://github.com/APGRoboCop/podbot_mm/releases/download/V3B24-APG/podbot_full_V3B24.zip
ARG PODBOT_SHA256=4cbb2baaa5c6e9120091a7d053f3e8eefefcd06e81236bd8b8e67eaacc18a4c7
ARG FY_POOL_DAY_PWF_URL=https://raw.githubusercontent.com/ggoulart/cs1.6-server-more-maps/cd8b5408e0927a74670b4f08f7df8caa55e2b28b/podbot/wptdefault/fy_pool_day.pwf
ARG FY_POOL_DAY_PWF_SHA256=378a3b3ddd72734223066db48fd8d36f26dfeec293642418e32402b7eb810cca

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
    fetch_zip "$gh/ReUnion/releases/download/$REUNION_VERSION/reunion-$REUNION_VERSION.zip"; \
    mkdir -p "$HLDS_DIR/cstrike/addons/reunion"; \
    cp "$(find /tmp/pkg -name reunion_mm_i386.so | head -n1)" "$HLDS_DIR/cstrike/addons/reunion/"; \
    cp "$(find /tmp/pkg -name reunion.cfg | head -n1)" "$HLDS_DIR/cstrike/reunion.cfg"; \
    rm -rf /tmp/pkg /tmp/podbot.zip; \
    mkdir /tmp/pkg; \
    curl -fsSL "$PODBOT_URL" -o /tmp/podbot.zip; \
    echo "$PODBOT_SHA256  /tmp/podbot.zip" | sha256sum -c -; \
    unzip -q /tmp/podbot.zip -d /tmp/pkg; \
    rm /tmp/podbot.zip; \
    mkdir -p "$HLDS_DIR/cstrike/addons/podbot"; \
    cp -a /tmp/pkg/podbot/. "$HLDS_DIR/cstrike/addons/podbot/"; \
    rm -rf /tmp/pkg; \
    curl -fsSL "$FY_POOL_DAY_PWF_URL" -o "$HLDS_DIR/cstrike/addons/podbot/wptdefault/fy_pool_day.pwf"; \
    echo "$FY_POOL_DAY_PWF_SHA256  $HLDS_DIR/cstrike/addons/podbot/wptdefault/fy_pool_day.pwf" | sha256sum -c -; \
    sed -i -e '/^pb add /d' -e 's/^pb_minbotskill .*/pb_minbotskill 80/' -e 's/^pb_maxbotskill .*/pb_maxbotskill 90/' -e 's/^pb_detailnames .*/pb_detailnames 0/' "$HLDS_DIR/cstrike/addons/podbot/podbot.cfg"; \
    bp="https://raw.githubusercontent.com/PluginyCS/BasePack/$BASEPACK_REF/cstrike/addons/whblocker"; \
    mkdir -p "$HLDS_DIR/cstrike/addons/whblocker"; \
    curl -fsSL "$bp/whblocker_mm_i386.so" -o "$HLDS_DIR/cstrike/addons/whblocker/whblocker_mm_i386.so"; \
    curl -fsSL "$bp/config.ini" -o "$HLDS_DIR/cstrike/addons/whblocker/config.ini"; \
    echo "$WHBLOCKER_SHA256  $HLDS_DIR/cstrike/addons/whblocker/whblocker_mm_i386.so" | sha256sum -c -; \
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
