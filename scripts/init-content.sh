#!/usr/bin/env bash
set -euo pipefail

CONTENT_DIR="${1:-/content}"
ROOT="/app"

log() { echo "[content-init] $*"; }

mkdir -p "$CONTENT_DIR"

export BOOTSTRAP_IN_DOCKER=1
export PACKAGE_IN_DOCKER=1
export MANIFEST="${CONTENT_DIR}/maps.txt"
export ASSETS="$ROOT/server/plugins/assets"

log "Verifying maps and client assets in $CONTENT_DIR..."

if [ ! -f "$MANIFEST" ]; then
  log "WARN: $MANIFEST not found; skipping map bootstrap."
  exit 0
fi

# Run bootstrap (downloads missing maps, skips already existing maps)
bash "$ROOT/scripts/bootstrap-content.sh" "$CONTENT_DIR"

log "Content initialization complete."
