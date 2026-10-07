# Drop-in plugins

This folder is an overlay of `cstrike/` that gets copied into the image at build time:

- `addons/amxmodx/scripting/*.sma` → compiled with the bundled `amxxpc` (the build fails if a compile fails).
  Extra `.inc` files go in `addons/amxmodx/scripting/include/`.
- `addons/amxmodx/plugins/*.amxx` → copied as-is (when you only have a binary).
- `addons/amxmodx/configs/*` and `addons/amxmodx/data/lang/*` → each plugin's own cfg and dictionary files.
- **Client assets** (`sound/`, `models/`, `sprites/`) go in `/content`, not here, so FastDL can serve them.

Commit the files here: Coolify builds from git. At each boot, `entrypoint.sh` logs a `WARN` for every plugin
named in `plugins*.ini` that isn't installed. AMXX skips missing plugins, so the server still starts.

## Expected files

Filenames must match the ones in `server/cstrike/addons/amxmodx/configs/` (rename the downloaded file, or edit the `.ini`).

| File | Loaded on | Source | Notes |
|---|---|---|---|
| `galileo.amxx` | all | github.com/addonszz/Galileo (releases) | Needs `galileo.txt` lang, `configs/galileo.cfg`, `sound/gal/` in content. Set RTV to 51% in its cfg |
| `bullet_damage.amxx` | all | AlliedModders "Bullet Damage" | |
| `resetscore.amxx` | all | AlliedModders "Reset Score" | `/rs`, `/resetscore` |
| `sank_sounds.amxx` | all | AlliedModders "Sank Sounds Plugin" | `configs/sank_sounds.ini`; sounds in content |
| `c4_timer.amxx` | de_ | AlliedModders "C4 Timer" | |
| `backweapons.amxx` | de_, cs_, fy_ | AlliedModders "Back Weapons" | model in content |
| `grenade_trail.amxx` | all except jb_ | AlliedModders "Grenade Trail" | |
| `amx_parachute.amxx` | all except gg_ | AlliedModders "Parachute" | model in content |
| `amx_vampire.amxx` | fy_, aim_, awp_ | AlliedModders "Vampire" | +15 HP / kill, +30 HS, cap 100 |
| `gungame.amxx` | gg_ | AlliedModders "GunGame AMXX" (2.13c) | `configs/gungame.cfg` (weapon order, `gg_dm`) |
| `jailbreak.amxx` | jb_ | AlliedModders "JailBreak Extreme" or a ReAPI JB from dev-cs.ru | Rename the core plugin or edit `plugins-jb.ini`; models in content |
| `zombie_plague40.amxx` | zm_ | AlliedModders "Zombie Plague 4.3 Fix5a" | `configs/zombieplague.cfg` (`zp_delay`, `zp_lighting`); models/sounds in content |

`miscstats.amxx` (Quake sounds), `statsx.amxx`, `adminvote.amxx` etc. come with AMXX itself.
Auto-bunnyhop is native in ReGameDLL (`mp_autobunnyhopping`), so it needs no plugin.

## Metamod modules (enabled by default)

| Path | Toggle | Source |
|---|---|---|
| `addons/reunion/reunion_mm_i386.so` + `reunion.cfg` (cstrike root) | `REUNION_ENABLED` (default `1`), `REUNION_SALT` | dev-cs.ru "Reunion" |
| `addons/whblocker/*_mm_i386.so` | `ANTICHEAT_ENABLED` (default `1`) | dev-cs.ru "WHBlocker" |

Both are required while enabled: if a binary is missing, the server stops at boot with an error instead of running without it.
Set the toggle to `0` to opt out.

Only download from these upstreams. Repacked bundles from random forums often ship RCON backdoors.
