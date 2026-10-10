#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0" >&2
  echo "  Compiles every server plugin (server/plugins/addons/amxmodx/scripting/*.sma) and every" >&2
  echo "  tests/unit/*.sma inside \$IMAGE with the Dockerfile's amxxpc flags. Fails on compile errors," >&2
  echo "  and on any warning from our own plugins and unit tests (third-party plugins: errors only)." >&2
  echo "  Env: IMAGE (default cstrike-server-multimod-cstrike)." >&2
  exit 1
}

case "${1:-}" in
  -h|--help) usage ;;
esac

log() { echo "[test-compile] $*"; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${IMAGE:-cstrike-server-multimod-cstrike}"
SCRIPTING="$ROOT/server/plugins/addons/amxmodx/scripting"

# Runs inside the image. Arg 1: sma path. Arg 2: 1 if warnings are fatal for this file.
read -r -d '' COMPILE_LOOP <<'EOF' || true
status=0
scripting=/opt/hlds/cstrike/addons/amxmodx/scripting
cd "$scripting"

check() {
  local sma="$1" own="$2" name out rc=0
  name="$(basename "$sma")"
  out="$(./amxxpc "$sma" -i"$scripting/include" -i/src/include -o/tmp/out.amxx 2>&1)" || rc=$?
  if [ "$rc" -ne 0 ] || ! grep -q 'Done\.' <<<"$out"; then
    echo "FAIL $name (amxxpc exit $rc)"
    echo "$out"
    status=1
    return
  fi
  if [ "$own" = 1 ] && grep -qi 'warning' <<<"$out"; then
    echo "FAIL $name (warnings in own file)"
    echo "$out"
    status=1
    return
  fi
  echo "PASS $name"
}

for sma in /src/*.sma; do
  [ -e "$sma" ] || continue
  own=0
  case "$(basename "$sma")" in
    nostalgia_*|podbot_admin.sma|ad_manager.sma|AQS.sma) own=1 ;;
  esac
  check "$sma" "$own"
done

for sma in /tests/unit/*.sma; do
  [ -e "$sma" ] || continue
  check "$sma" 1
done

exit "$status"
EOF

log "compiling with $IMAGE"
docker run --rm --entrypoint /bin/bash \
  -v "$SCRIPTING:/src:ro" \
  -v "$ROOT/tests:/tests:ro" \
  "$IMAGE" -c "$COMPILE_LOOP"
