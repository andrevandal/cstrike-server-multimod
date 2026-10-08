#!/usr/bin/env bash
# Zips everything in content/ that FastDL serves to players (maps, sound, models,
# sprites, gfx, overviews, loose .wad files) into content/client-assets.zip, so a
# player can grab the whole asset set in one download instead of relying on
# per-map HTTP fetches. Linked from fastdl/motd.html as a relative "client-assets.zip".
#
# Run this after scripts/bootstrap-content.sh (or after any content/ change) so the
# zip matches what's on FastDL. Not wired into bootstrap-content.sh automatically:
# rerun it explicitly once content/ is in the state you want to ship.
set -euo pipefail

usage() {
  echo "usage: $0 [content_dir]" >&2
  echo "  Zips content_dir (default: ./content) into <content_dir>/client-assets.zip," >&2
  echo "  excluding maps.txt, README.md and any existing *.zip." >&2
  exit 1
}

[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && usage

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTENT="${1:-$ROOT/content}"
OUTPUT="client-assets.zip"

[ -d "$CONTENT" ] || { echo "content dir not found: $CONTENT" >&2; exit 1; }

if ! command -v zip >/dev/null 2>&1; then
  if [ -z "${PACKAGE_IN_DOCKER:-}" ] && command -v docker >/dev/null 2>&1; then
    exec docker run --rm -e PACKAGE_IN_DOCKER=1 -e HOST_OWNER="$(id -u):$(id -g)" \
      -v "$ROOT:/repo:ro" -v "$(realpath "$CONTENT"):/content" \
      debian:bookworm-slim sh -c 'apt-get update -qq >/dev/null \
        && apt-get install -y -qq --no-install-recommends bash zip >/dev/null \
        && bash /repo/scripts/package-client-assets.sh /content; rc=$?
        chown "$HOST_OWNER" /content/client-assets.zip 2>/dev/null || true
        exit $rc'
  fi
  echo "missing tool: zip (or docker to run it in a container)" >&2
  exit 1
fi

rm -f "$CONTENT/$OUTPUT"
(cd "$CONTENT" && zip -q -r -X "$OUTPUT" . -x 'maps.txt' -x 'README.md' -x '*.zip')

echo "==> $CONTENT/$OUTPUT ($(du -h "$CONTENT/$OUTPUT" | cut -f1))"
