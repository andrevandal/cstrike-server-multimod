#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 [--no-build] [--only compile|unit|integration]" >&2
  echo "  Runs the plugin test levels in order: compile, unit, integration. Stops at the first failing level." >&2
  echo "  --no-build        skip building the server image (must already exist)" >&2
  echo "  --only <level>    run a single level" >&2
  echo "  Env: IMAGE (default cstrike-server-multimod-cstrike)." >&2
  exit 1
}

log() { echo "[test] $*"; }
die() { echo "[test] ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export IMAGE="${IMAGE:-cstrike-server-multimod-cstrike}"

BUILD=1
ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --no-build) BUILD=0 ;;
    --only)
      [ $# -ge 2 ] || usage
      ONLY="$2"
      shift
      ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
  shift
done

case "$ONLY" in
  ""|compile|unit|integration) ;;
  *) usage ;;
esac

command -v docker >/dev/null 2>&1 || die "docker is required"

if [ "$BUILD" = "1" ]; then
  log "building $IMAGE from server/"
  docker build -t "$IMAGE" "$ROOT/server" || die "image build failed"
else
  docker image inspect "$IMAGE" >/dev/null 2>&1 || die "image $IMAGE not found; run without --no-build"
fi

run_level() {
  local level="$1"
  shift
  if [ -n "$ONLY" ] && [ "$ONLY" != "$level" ]; then
    return 0
  fi
  log "== level: $level"
  "$@" || { log "FAILED: $level"; exit 1; }
}

run_level compile "$ROOT/scripts/test-compile.sh"
run_level unit "$ROOT/scripts/test-unit.sh"
run_level integration python3 "$ROOT/scripts/test-integration.py"

log "all selected levels passed"
