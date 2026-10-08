# content/

Everything players may download: custom maps and the client-side assets of plugins.
Mounted read-only into the game server (symlinked into `cstrike/` at boot) and served as-is by FastDL.

Mirror the `cstrike/` layout:

```
content/
├── cs_rio.wad            # external .wad files at the root
├── maps/                 # .bsp (+ .res listing the map's dependencies)
├── sound/                # map ambience, gal/, gungame/, zombie_plague/ …
├── models/player/        # jailbreak / zombie player models
├── sprites/
└── gfx/env/              # skyboxes (.tga)
```

Not tracked by git (maps are large third-party files), except `maps.txt`: the list of custom maps and their
direct download links. `scripts/bootstrap-content.sh [content_dir]` downloads them, merges each archive's
`cstrike/` layout into this folder, and copies plugin assets from `server/plugins/assets/`.

`scripts/package-client-assets.sh [content_dir]` zips everything here (except `maps.txt`/`README.md`) into
`client-assets.zip`, so a player can grab the whole set in one download instead of one file at a time.
FastDL serves it at `<FASTDL_URL>client-assets.zip`; `fastdl/motd.html` links to it. Rerun after any
bootstrap/content change, then `docker compose restart fastdl`.
