# cstrike-server-multimod

The classic LAN house atmosphere of the 2000s: a Counter-Strike 1.6 server (ReHLDS + ReGameDLL + Metamod-r + AMX Mod X)
where the **map prefix picks the game mode**: classic (`de_`/`cs_`), GunGame (`gg_`), floor weapons (`fy_`/`aim_`/`awp_`),
Jailbreak (`jb_`) and Zombie Plague (`zm_`). Players get RTV, nominations and vote kick/ban.

The full design is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Layout

| Path | Purpose |
|---|---|
| `docker-compose.yml` | `cstrike` (game), `fastdl` (nginx :8080), `backup` (daily state snapshot) |
| `server/` | Image: Dockerfile, entrypoint, managed config (`cstrike/`), drop-in plugins (`plugins/`) |
| `fastdl/` | nginx config + MOTD page |
| `content/` | Custom maps and client assets (not in git) |
| `state/`, `logs/`, `backups/` | Runtime data (not in git) |
| `scripts/restore.sh` | Restore a backup |

## Setup

1. **Plugins:** put the files listed in [server/plugins/MANIFEST.md](server/plugins/MANIFEST.md) into `server/plugins/` and commit them.
2. **Content:** download the custom maps (17buddies, GameBanana) into `content/` (see [content/README.md](content/README.md)).
   Stock maps (de_dust2, de_aztec, cs_assault, …) already come with HLDS.
3. **Env:** `cp .env.example .env` and set at least `RCON_PASSWORD`.
4. `docker compose up -d --build`, then `docker compose logs -f cstrike` and look for `WARN` lines about missing maps or plugins.

### Coolify

1. Create a **Docker Compose** resource from this repo. Coolify builds `server/` itself.
2. Set the variables from `.env.example` under *Environment Variables* (`RCON_PASSWORD` is required).
3. DNS: `fastdl.vandal.services` → A record to the server IP. Firewall: open **27015/udp** and **8080/tcp**.
   Don't assign a domain to `fastdl` in Coolify: it has to stay on plain HTTP outside Traefik.
4. Upload content to the service's bind path: `rsync -av content/ root@host:<bind path>/content/` (Coolify shows the path under *Storages*; usually `/data/coolify/applications/<uuid>/`), then restart `cstrike`.

## Operations

| Task | How |
|---|---|
| Lock / unlock the server | Set `SV_PASSWORD` and restart, or `rcon sv_password "x"` (lasts until the next map change) |
| Admins / moderators | `ADMINS` / `MODERATORS` = comma-separated SteamIDs, then restart |
| Anti-cheat | Add WHBlocker to `server/plugins/`, set `ANTICHEAT_ENABLED=1`, restart |
| Non-Steam clients | Add Reunion, set `REUNION_ENABLED=1` and `REUNION_SALT`, restart |
| Add a map | Drop it in `content/` (+ `.wad`/`.res`), list it in `server/cstrike/mapcycle.all.txt`, redeploy |
| Check FastDL | `curl -I http://fastdl.vandal.services:8080/maps/cs_rio.bsp` → `200`, no `Location` header |
| Manual backup | `docker compose exec backup backup` |
| Restore | `scripts/restore.sh backups/cs16-state-<ts>.tar.gz` (on Coolify: `CSTRIKE_CONTAINER=<name> scripts/restore.sh …`) |

Pinned engine and plugin-loader versions are `ARG`s at the top of `server/Dockerfile`.
