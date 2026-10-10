# AGENTS.md

Guidance for coding agents working in this repo. Design rationale lives in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md); operator tasks live in [README.md](README.md).

## What this is

A Counter-Strike 1.6 server (ReHLDS, ReGameDLL, Metamod-r, AMX Mod X 1.10, ReAPI) in one Docker image, run with Docker Compose and deployed through Coolify. The map prefix selects the game mode (`de_`/`cs_` classic, `gg_` GunGame, `fy_`/`aim_`/`awp_`, `zm_` Zombie Plague). Plugins are Pawn (`.sma`), compiled at image build.

## Layout

| Path | Contents |
|---|---|
| `server/Dockerfile` | Pinned engine/plugin versions as `ARG`s; compiles every `server/plugins/addons/amxmodx/scripting/*.sma` |
| `server/entrypoint.sh` | Boot: renders env-driven cfgs, links state/content, drops to `hlds`, runs the server; SIGTERM starts a drain |
| `server/cstrike/` | Managed config baked into the image (`server.cfg`, `plugins.ini`, `configs/maps/prefix_*.cfg`, `plugins-*.ini`) |
| `server/plugins/` | Vendored third-party plugins and assets; `MANIFEST.md` and `SOURCES.md` document provenance |
| `server/plugins/addons/amxmodx/scripting/` | Our plugins (`nostalgia_*.sma`, `podbot_admin.sma`, …) and `include/` |
| `tests/unit/` | Pawn unit tests (not compiled into the image) |
| `scripts/` | Operator and test scripts (`test.sh` and its levels, `bootstrap-content.sh`, `restore.sh`, `update-versions.sh`) |
| `.githooks/pre-push`, `.github/workflows/test.yml` | Test gate locally and on PRs to `main` |
| `content/`, `state/`, `logs/`, `backups/`, `.env` | Runtime data and secrets; git-ignored. Never commit `.env` or anything in `state/` |

## Commands

- Full test suite (builds the image first): `scripts/test.sh`
- Skip the build: `scripts/test.sh --no-build`
- One level: `scripts/test.sh --only compile|unit|integration`
- Build the image directly: `docker build -t cstrike-server-multimod-cstrike server`
- Compose: `docker compose up -d --build`, then `docker compose logs -f cstrike`

The test levels are `scripts/test-compile.sh` (every plugin plus unit tests compile; warnings fail our own files), `scripts/test-unit.sh` (Pawn assertions run inside the real server image), and `scripts/test-integration.py` (boots containers and drives the HLDS console over stdin; stdlib Python only).

Enable the pre-push hook once per clone with `git config core.hooksPath .githooks`. Skip it with `git push --no-verify`, but only when the change does not affect the server.

## Where changes go

- **Server behaviour or cvars:** `server/cstrike/` (baseline in `server.cfg`, per-prefix in `configs/maps/`). Changing a mode's cvars in a mode cfg alone is wrong, because they leak into the next map; the baseline must reset them. See ARCHITECTURE §4.
- **Our plugin logic:** `server/plugins/addons/amxmodx/scripting/`. Put pure logic (no natives beyond `max`/`equali`) in `include/*.inc` so unit tests can reach it. `nostalgia_logic.inc` is the existing example.
- **Third-party plugins:** `server/plugins/` with an entry in `MANIFEST.md`. Do not edit vendored code without noting it there.
- **Secrets and per-host identity** (`RCON_PASSWORD`, admins, FastDL URL): environment variables, rendered by the entrypoint. Never hard-code them.
- **Versions:** bump the `ARG` pins in `server/Dockerfile` (`scripts/update-versions.sh` does this); review the diff.
- **Tests:** unit test plugins live in `tests/unit/`, never under `scripting/`, because the Dockerfile compiles everything in `scripting/`.

## Conventions

- Clean cutover: when logic moves into an include, update every caller and delete the old inline copy. No shims or duplicate paths.
- Shell scripts: `set -euo pipefail`, a `log()` helper, usage on `-h`. Match `scripts/bootstrap-content.sh`.
- Docs follow behaviour: a change that alters operator-visible behaviour updates README (Operations table) or ARCHITECTURE in the same change.

## Gotchas

- `docker compose build` interpolates `${RCON_PASSWORD:?}` and fails without `.env`. Scripts build with `docker build` directly for that reason.
- `amxx plugins` truncates plugin names to 20 characters. Match the displayed prefix (`Autoresponder/Advertis`), not the full name.
- The unit test needs `quit` from `plugin_init` to stop the server. It does today; if it stops working, call `quit` from `plugin_cfg` via `set_task`.
- Integration timings are real: bot-count checks depend on `pb_minplayers 10` (9 bots) and need about 75 s of boot. If that default changes, update the expected count.
- The image needs stock maps (`de_dust2`, `as_oilrig`, …) to boot without `content/`. Those ship in `server/cstrike/` or the HLDS install; keep them there.
- WHBlocker and Reunion are fetched at build with SHA-256 checks. A checksum mismatch is a deliberate stop; do not skip the check.
