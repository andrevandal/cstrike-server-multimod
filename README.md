# cstrike-server-multimod

The classic LAN house atmosphere of the 2000s: a Counter-Strike 1.6 server (ReHLDS + ReGameDLL + Metamod-r + AMX Mod X)
where the **map prefix picks the game mode**: classic (`de_`/`cs_`), GunGame (`gg_`), floor weapons (`fy_`/`aim_`/`awp_`),
and Zombie Plague (`zm_`). Players get RTV, nominations and vote kick/ban.

The full design is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Layout

| Path | Purpose |
|---|---|
| `docker-compose.yml` | `cstrike` (game), `fastdl` (nginx :8080), `backup` (daily state snapshot) |
| `server/` | Image: Dockerfile, entrypoint, managed config (`cstrike/`), drop-in plugins (`plugins/`) |
| `fastdl/` | nginx config + MOTD page |
| `content/` | Custom maps and client assets (not in git) |
| `state/`, `logs/`, `backups/` | Runtime data (not in git) |
| `scripts/bootstrap-content.sh` | Download maps from `content/maps.txt` and sync plugin assets into `content/` |
| `scripts/restore.sh` | Restore a backup |

## Setup

1. **Plugins:** all required third-party plugins are vendored in [server/plugins/](server/plugins/) at pinned upstream commits. Reunion, WHBlocker and PodBot are fetched at build with SHA-256 verification.
2. **Content:** fill the direct download links in [content/maps.txt](content/maps.txt), then run `scripts/bootstrap-content.sh`.
   Stock maps (de_dust2, de_aztec, cs_assault, …) already come with HLDS.
3. **Env:** `cp .env.example .env` and set at least `RCON_PASSWORD`.
4. `docker compose up -d --build`, then `docker compose logs -f cstrike` and look for `WARN` lines about missing maps or plugins.

### Coolify

1. Create a **Docker Compose** resource from this repo. Coolify builds `server/` itself.
2. Set the variables from `.env.example` under *Environment Variables* (`RCON_PASSWORD` is required).
3. DNS: `fastdl.vandal.services` → A record to the server IP. Firewall: open **27015/udp** and **8080/tcp**.
   Don't assign a domain to `fastdl` in Coolify: it has to stay on plain HTTP outside Traefik.
4. Bootstrap content on the host (only `docker` is needed; the script runs its tools in a Debian container with RAR support if they're missing):
   ```bash
   git clone -b claude/awesome-noether-cqdfab https://github.com/andrevandal/cstrike-server-multimod.git /tmp/cs16
   /tmp/cs16/scripts/bootstrap-content.sh /data/coolify/applications/<uuid>/content
   ```
   Coolify shows the bind path under *Storages*. Re-run it after editing `content/maps.txt` (existing maps are skipped; `--force` re-downloads), then restart `cstrike`.

## Operations

| Task | How |
|---|---|
| Lock / unlock the server | Set `SV_PASSWORD` and restart, or `rcon sv_password "x"` (lasts until the next map change) |
| Admins / moderators | `ADMINS` / `MODERATORS` = comma-separated SteamIDs (`STEAM_0:Y:Z`), then restart. Seeded admin: `STEAM_0:1:26191905` (SteamID64 `76561198012649539`) |
| In-game admin menu | Connect with an admin/moderator SteamID: type `say /admin` (or `say /menu`, or console `adminmenu`) for the categorized Nostalgia menu (Bots, Match, Fun/Deathmatch, Maps/RTV, Players), or console `amxmodmenu` for stock AMXX menus. Deathmatch mode can also be toggled directly with `say /dm` |
| Anti-cheat | On by default (WHBlocker, fetched at build); `ANTICHEAT_ENABLED=0` to turn off |
| Non-Steam clients | On by default (Reunion is fetched at build); salt auto-generated in `state/reunion_salt` unless `REUNION_SALT` is set; `REUNION_ENABLED=0` to turn off |
| Bots | PodBot loads without auto-spawning. Full admins use `pb_add`, `pb_fillserver`, or `pb_removebots` on maps with a waypoint; `fy_pool_day` ships with a checksum-pinned waypoint. Chat is PT-BR (`botchat.txt`) rate-limited to avoid spam (`pb_chat_interval 20.0`), bot flashlights are suppressed, and names carry a `[BOT]` tag (`botnames.txt`, `pb_detailnames 0`) |
| Add a map | Add `<map> <url>` to `content/maps.txt` and run the bootstrap; list it in `server/cstrike/mapcycle.all.txt`, redeploy |
| Check FastDL | `curl -I http://cstrike.vandal.services:8888/maps/cs_rio.bsp` → `200`, no `Location` header |
| Repack client assets | Automatic via `content-init` on deployment/startup (or manually via `scripts/package-client-assets.sh`); creates `content/client-assets.zip` served by FastDL |
| Manual backup | `docker compose exec backup backup` |
| Restore | `scripts/restore.sh backups/cs16-state-<ts>.tar.gz` (on Coolify: `CSTRIKE_CONTAINER=<name> scripts/restore.sh …`) |
| Update engine/modules | `scripts/update-versions.sh` bumps the `ARG` pins in `server/Dockerfile` to the latest stable releases (ReHLDS, ReGameDLL, Metamod-r, ReAPI, Reunion, PodBot, newest AMXX 1.10 build, WHBlocker from the newest PluginyCS/BasePack release). Review the diff, `docker compose build cstrike`, boot it, check logs, commit |

Pinned engine and plugin-loader versions are `ARG`s at the top of `server/Dockerfile`.
