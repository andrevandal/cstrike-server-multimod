# Plugins

`server/plugins/` is an overlay of `cstrike/` copied into the image at build time:

- `addons/amxmodx/scripting/*.sma` → compiled with the bundled `amxxpc` (the build fails if a compile fails).
  Extra `.inc` files go in `addons/amxmodx/scripting/include/`.
- `addons/amxmodx/plugins/*.amxx` → copied as-is.
- `addons/amxmodx/configs/*`, `addons/amxmodx/data/lang/*` → each plugin's own cfg and dictionary files.
- `assets/` (laid out like `cstrike/`) → **not** in the image; `scripts/bootstrap-content.sh` copies it into
  `content/` so FastDL serves it and the server links it.

At each boot `entrypoint.sh` logs a `WARN` for every plugin named in `plugins*.ini` that isn't installed.

Never put a plugin's own `configs/plugins-*.ini` in `addons/amxmodx/configs/`: AMXX loads every file
matching that name on **every** map. Mode plugins belong in `server/cstrike/addons/amxmodx/configs/maps/plugins-<prefix>.ini`.

## Status

| Plugin file(s) | Loaded on | State | Source |
|---|---|---|---|
| `nostalgia_vampire.amxx` | fy_, aim_, awp_ | **in repo** | `scripting/nostalgia_vampire.sma` (cvars `vampire_kill_hp` 15, `vampire_headshot_hp` 30, `vampire_max_hp` 100) |
| `nostalgia_parachute.amxx` | de_, cs_, fy_, zm_ | **in repo** | `scripting/nostalgia_parachute.sma` (hold E; cvar `parachute_fallspeed` 100; shows `models/parachute.mdl` if present in content) |
| Reunion | metamod | **fetched at build** | github.com/rehlds/ReUnion release (`REUNION_VERSION`) |
| PodBot MM V3B24 | metamod | **fetched at build** | `APGRoboCop/podbot_mm` release; auto-population disabled because not every rotated map has a waypoint; `fy_pool_day.pwf` fetched from `ggoulart/cs1.6-server-more-maps` at a pinned commit |
| `podbot_admin.amxx` | all | **in repo** | Full-admin `pb_add`, `pb_fillserver`, and `pb_removebots` commands that invoke PodBot through the server console |
| `nostalgia_adminmenu.amxx` | all | **in repo** | Deep in-game admin menu (`say /admin`, `say /menu`, console `adminmenu`): submenus for Bots, Match, Fun, Maps/RTV, and Players |
| `nostalgia_ammo_pickup.amxx`, `nostalgia_mode_rules.amxx` | all | **in repo** | `scripting/nostalgia_ammo_pickup.sma` gives full reserve ammo for a dropped firearm only to players who already carry that weapon; anyone else picks the gun up normally. `scripting/nostalgia_mode_rules.sma` restores classic rules on `cs_` and `de_` maps and exempts full admins (`ADMIN_BAN`) from the idle kick. |
| `AQS.amxx` | all | **in repo** | github.com/ClaudiuHKS/AdvancedQuakeSounds @ `6e9d36a` (MIT). Quake-style killstreak/headshot/first-blood/etc. announcer; config `configs/AQS.ini` (SQL storage off), sounds in `assets/sound/AQS/`. Players toggle with `/sounds`. |
| `nostalgia_drain.amxx` | all | **in repo** | `scripting/nostalgia_drain.sma` runs the graceful-restart drain: on SIGTERM it announces the restart, starts a Galileo vote, and quits when the next map loads (300 s cap). |
| `ad_manager.amxx` | all | **in repo** | MaximusBrood "Autoresponder and Advertiser" v0.5 (forums.alliedmods.net/showthread.php?t=27814). Colored rotating chat messages and keyword answers from `configs/advertisements.ini`. Local changes: `min_players`/`max_players` count humans only; `map` conditions on `@` answers now work (upstream's check never matched). Avoid `%` in message text (the client treats it as a format token) |
| `nostalgia_punish.amxx` | all | **in repo** | `scripting/nostalgia_punish.sma`: admin punishments (drug, blind, bad aim, levitate, lightning) with duration (default 5 s, 0 = until removed), target notice by text and sound. Commands `amx_punish`, `amx_unpunish`, `amx_punishmenu`; menu under Admin → Jogadores. Effects modelled on Radiance's "punishments" v0.1 (forums.alliedmods.net/showthread.php?t=70363), rewritten (upstream crashes the server in its un-blind path). Needs `ADMIN_SLAY` |
| `galileo.amxx` | all | **in repo** | github.com/addonszz/Galileo @ `5073cac` |
| `regg_core`, `regg_balancer`, `regg_controller`, `regg_informer`, `regg_leader`, `regg_map_cleaner`, `regg_notify`, `regg_warmup`, `regg_show_winner` | gg_ | **in repo** | github.com/d3m37r4/regg @ `4f9a3f4` |
| `bullet_damage`, `say_resetscore`, `gp_grenadetrail`, `c4countdown` | see `plugins*.ini` | **in repo** | github.com/Jessyy/amxx-plugins-sma @ `9acd962` (`say_resetscore` needs `include/amxplus.inc`) |
| `sank_sounds.amxx` | all | **in repo** | github.com/ZTHawk/HL1_SankSounds @ `ed02c30` (keyword list already in `server/cstrike/.../configs/SND-LIST.CFG`) |
| `amx_settings_api`, `zombie_plague_special_45`, `zpsp_zombie_classes`, `zpsp_human_classes`, `zp_game_mode_assassin_vs_sniper`, `zp_game_mode_nightmare`, `zpsp_game_mode_remix` | zm_ | **in repo** | github.com/PerfectScrash/ZP-Special-Final @ `0585736` |
| `backweapons.amxx` | de_, cs_, fy_ | **in repo** | Back Weapons 1.87 (`scripting/backweapons.sma`, `assets/models/backweapons.mdl`) |
| WHBlocker | metamod (`ANTICHEAT_ENABLED`, default on) | **fetched at build** | github.com/PluginyCS/BasePack (`BASEPACK_REF`, checked against `WHBLOCKER_SHA256`) |

### Adding the GitHub-hosted plugins

For each "to add" row, copy from the upstream repo at the pinned commit:

| Upstream path | Destination |
|---|---|
| `**/scripting/<name>.sma`, `**/scripting/regg/` | `server/plugins/addons/amxmodx/scripting/` |
| `**/scripting/include/*.inc` | `server/plugins/addons/amxmodx/scripting/include/` |
| `**/configs/<dir>/` (`galileo/`, `regg/`, `zpsp_configs/`) | `server/plugins/addons/amxmodx/configs/` |
| `**/data/lang/*.txt` | `server/plugins/addons/amxmodx/data/lang/` |
| `sound/`, `models/`, `sprites/` (ReGG `cstrike/sound/regg`, ZP Special root) | `server/plugins/assets/` |

Then commit, redeploy, and run `scripts/bootstrap-content.sh` on the host so the assets reach FastDL.

Only download from these upstreams. Repacked bundles from random forums often ship RCON backdoors.
