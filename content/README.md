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

Not tracked by git (maps are large third-party files). Upload them to the server's bind path, e.g.
`rsync -av content/ user@host:/data/coolify/services/<uuid>/content/`.
