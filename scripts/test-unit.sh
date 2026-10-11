#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0" >&2
  echo "  Compiles every tests/unit/*_test.sma and runs each inside the server image, one at a time." >&2
  echo "  Each plugin prints TEST PASS/FAIL lines and TEST SUMMARY, then quits the server." >&2
  echo "  Passes iff every run reports TEST SUMMARY fail=0 and no TEST FAIL line appears." >&2
  echo "  Env: IMAGE (default cstrike-server-multimod-cstrike)." >&2
  exit 1
}

case "${1:-}" in
  -h|--help) usage ;;
esac

log() { echo "[test-unit] $*"; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${IMAGE:-cstrike-server-multimod-cstrike}"
SCRIPTING="$ROOT/server/plugins/addons/amxmodx/scripting"
TESTS="$ROOT/tests"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Arg 1: test plugin name without extension (e.g. nostalgia_logic_test). Returns non-zero on failure.
run_one() {
  local PLUGIN="$1" out rc=0
  log "compiling $PLUGIN.sma"
  docker run --rm --entrypoint /bin/bash \
    -v "$SCRIPTING:/src:ro" \
    -v "$TESTS:/tests:ro" \
    -v "$TMP:/out" \
    "$IMAGE" -c "cd /opt/hlds/cstrike/addons/amxmodx/scripting && ./amxxpc /tests/unit/$PLUGIN.sma -i\"\$PWD/include\" -i/src/include -o/out/$PLUGIN.amxx"
  [ -s "$TMP/$PLUGIN.amxx" ] || { log "FAIL: $PLUGIN.amxx not produced"; return 1; }

  log "running server with $PLUGIN loaded"
  out="$(timeout 120 docker run --rm -i \
    -e RCON_PASSWORD=test \
    -e START_MAP=de_dust2 \
    -v "$TMP/$PLUGIN.amxx:/opt/hlds/cstrike/addons/amxmodx/plugins/$PLUGIN.amxx:ro" \
    --entrypoint /bin/bash \
    "$IMAGE" -c "echo $PLUGIN.amxx >> /opt/hlds/cstrike/addons/amxmodx/configs/plugins.ini && exec /usr/local/bin/entrypoint.sh" \
    </dev/null 2>&1)" || rc=$?

  grep -E 'TEST (PASS|FAIL|SUMMARY)' <<<"$out" || true

  if grep -q 'TEST FAIL' <<<"$out"; then
    log "FAIL: $PLUGIN assertions failed"
    return 1
  fi
  if ! grep -Eq 'TEST SUMMARY .*fail=0' <<<"$out"; then
    log "FAIL: $PLUGIN has no passing TEST SUMMARY (docker/timeout rc=$rc)"
    return 1
  fi
  log "PASS $PLUGIN (rc=$rc)"
}

status=0
for sma in "$TESTS"/unit/*_test.sma; do
  [ -e "$sma" ] || continue
  run_one "$(basename "$sma" .sma)" || status=1
done

[ "$status" -eq 0 ] && log "PASS" || log "FAIL"
exit "$status"
