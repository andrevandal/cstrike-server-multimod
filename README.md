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
| Admin controls | Deathmatch is default outside `cs_` and `de_` maps; those prefixes restore classic rounds/economy. Full admins use console commands: `amx_dm` toggles Deathmatch; `amx_money16k` sets every connected human and bot to $16,000. Full admins (`ADMIN_BAN`) are exempt from the idle (AFK) kick; moderators and players are not. |
| Sounds | Quake-style announcer (AdvancedQuakeSounds, MIT): killstreaks, headshots, first blood, double kill, etc. Config `server/cstrike/addons/amxmodx/configs/AQS.ini`; players toggle with `/sounds`. Sounds live in `server/plugins/assets/sound/AQS/` and are precached, so FastDL serves them |
| Punishments | Full admins (`ADMIN_SLAY`): Admin menu → Jogadores → Punicoes, or `amx_punishmenu`. Effects: `drug` (FOV 140), `blind` (black screen), `badaim` (bullets deal no damage; knife and grenades still do), `drop` (levitate), `light` (lightning kill). Pick a player or TODOS; duration is set in the menu (default 5 s, cycles 5/10/15/30/60 s/until removed). Console: `amx_punish <effect> <name\|#userid\|todos> [seconds, 0 = until removed]`, `amx_unpunish <name\|#userid\|todos> [effect]`. The target gets center text, chat and a sound; immune admins are skipped; effects re-apply after respawn |
| Anti-cheat | On by default (WHBlocker, fetched at build); `ANTICHEAT_ENABLED=0` to turn off |
| Non-Steam clients | On by default (Reunion is fetched at build); salt auto-generated in `state/reunion_salt` unless `REUNION_SALT` is set; `REUNION_ENABLED=0` to turn off |
| Bots | PodBot loads without auto-spawning. The server keeps `pb_minplayers - 1` bots (default 10 → 9) plus every human, with teams equal in size (one apart when the total is odd; the extra slot goes to a team picked at random per map). Alone: 9 bots, 5 vs 4. One human: 10 players, 5 vs 5, so the human's team has one bot less and the other team one more. Joins, leaves and team changes are debounced (3 s) and applied in one pass. `pb_minplayers 0` or `pb_autobalance 0` turns the automatic management off; `pb_balance` forces a pass. Full admins use `pb_add [skill] [T|CT|ANY]` or `pb_fillserver [skill] [T|CT|ANY]` for exact difficulty and team, or `pb_skill <min> <max>` to set the default 0–100 range (new bots get a random skill in that range). `pb_removebots` removes all bots; `pb_kick <bot name or #userid>` removes one (the next human join/leave re-runs the fill). `fy_pool_day` ships with a checksum-pinned waypoint. Chat is PT-BR (`botchat.txt`) rate-limited to avoid spam (`pb_chat_interval 20.0`), bot flashlights are suppressed, and names carry a `[BOT]` tag (`botnames.txt`, `pb_detailnames 0`) |
| Add a map | Add `<map> <url>` to `content/maps.txt` and run the bootstrap; list it in `server/cstrike/mapcycle.all.txt`, redeploy |
| Check FastDL | `curl -I http://cstrike.vandal.services:8888/maps/cs_rio.bsp` → `200`, no `Location` header |
| Repack client assets | Automatic via `content-init` on deployment/startup (or manually via `scripts/package-client-assets.sh`); creates `content/client-assets.zip` served by FastDL |
| Manual backup | `docker compose exec backup backup` |
| Restore | `scripts/restore.sh backups/cs16-state-<ts>.tar.gz` (on Coolify: `CSTRIKE_CONTAINER=<name> scripts/restore.sh …`) |
| Update engine/modules | `scripts/update-versions.sh` bumps the `ARG` pins in `server/Dockerfile` to the latest stable releases (ReHLDS, ReGameDLL, Metamod-r, ReAPI, Reunion, PodBot, newest AMXX 1.10 build, WHBlocker from the newest PluginyCS/BasePack release). Review the diff, `docker compose build cstrike`, boot it, check logs, commit |
| Redeploy without surprise disconnects | Coolify/compose stop sends SIGTERM; the server drains: it announces the restart in chat, sound and center countdown, starts a Galileo map vote, and exits when the next map loads (300 s cap, `stop_grace_period: 6m` in compose). Empty server exits at once. Set Coolify *Advanced → Deployment → Auto deploy* to *Manual deployments only* to choose when to roll out. |

Pinned engine and plugin-loader versions are `ARG`s at the top of `server/Dockerfile`.
