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
