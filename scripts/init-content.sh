#!/usr/bin/env bash
set -euo pipefail

CONTENT_DIR="${1:-/content}"
ROOT="/app"

log() { echo "[content-init] $*"; }

mkdir -p "$CONTENT_DIR"

export BOOTSTRAP_IN_DOCKER=1
export PACKAGE_IN_DOCKER=1
export ASSETS="$ROOT/server/plugins/assets"

# Seed maps.txt from image if not already on the volume
if [ ! -f "$CONTENT_DIR/maps.txt" ] && [ -f "$ROOT/content/maps.txt" ]; then
  log "Seeding $CONTENT_DIR/maps.txt from image..."
  cp "$ROOT/content/maps.txt" "$CONTENT_DIR/maps.txt"
fi

export MANIFEST="${CONTENT_DIR}/maps.txt"

# Always ensure plugin assets are present in the FastDL content directory
if [ -d "$ASSETS" ]; then
  log "Syncing plugin assets to $CONTENT_DIR..."
  cp -a "$ASSETS/." "$CONTENT_DIR/"
fi

if [ ! -f "$MANIFEST" ]; then
  log "WARN: $MANIFEST not found; skipping map bootstrap."
  exit 0
fi

# Run bootstrap (downloads missing maps, skips already existing maps)
bash "$ROOT/scripts/bootstrap-content.sh" "$CONTENT_DIR"

log "Content initialization complete."
