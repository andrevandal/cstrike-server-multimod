#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 [--force] [content_dir]" >&2
  echo "  Downloads every map listed in content/maps.txt into content_dir (default: ./content)" >&2
  echo "  and syncs plugin assets from server/plugins/assets. --force re-downloads existing maps." >&2
  exit 1
}

FORCE=0
if [ "${1:-}" = "--force" ]; then FORCE=1; shift; fi
[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && usage

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTENT="${1:-$ROOT/content}"
MANIFEST="${MANIFEST:-$ROOT/content/maps.txt}"
ASSETS="$ROOT/server/plugins/assets"

missing_tools() {
  local tool
  for tool in curl unzip 7z file; do
    command -v "$tool" >/dev/null 2>&1 || return 0
  done
  return 1
}

if missing_tools; then
  if [ -z "${BOOTSTRAP_IN_DOCKER:-}" ] && command -v docker >/dev/null 2>&1; then
    mkdir -p "$CONTENT"
    args=()
    [ "$FORCE" = "1" ] && args+=(--force)
    exec docker run --rm -e BOOTSTRAP_IN_DOCKER=1 -e MANIFEST=/manifest \
      -v "$ROOT:/repo:ro" -v "$(realpath "$MANIFEST"):/manifest:ro" -v "$(realpath "$CONTENT"):/content" \
      alpine:3 sh -c 'apk add --no-cache bash curl unzip 7zip file >/dev/null && bash /repo/scripts/bootstrap-content.sh "$@" /content' \
      bootstrap "${args[@]}"
  fi
  echo "missing tools: need curl, unzip, 7z and file (or docker to run them in a container)" >&2
  exit 1
fi

[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 1; }
mkdir -p "$CONTENT/maps"

ok=() skipped=() failed=() no_url=()

extract() {
  local archive="$1" dest="$2"
  case "$(file -b --mime-type "$archive")" in
    application/zip) unzip -q -o "$archive" -d "$dest" ;;
    application/x-7z-compressed|application/x-rar|application/vnd.rar|application/x-rar-compressed)
      7z x -y -o"$dest" "$archive" >/dev/null ;;
    text/html) echo "got an HTML page, not a file (use a direct download link)"; return 1 ;;
    *) cp "$archive" "$dest/download.bsp" ;;
  esac
}

install_map() {
  local map="$1" dir="$2" bsp root
  bsp="$(find "$dir" -type f -iname "$map.bsp" | head -n1)"
  [ -n "$bsp" ] || bsp="$(find "$dir" -type f -name 'download.bsp' | head -n1)"
  [ -n "$bsp" ] || { echo "archive has no $map.bsp"; return 1; }

  root="$(dirname "$bsp")"
  if [ "$(basename "$root" | tr '[:upper:]' '[:lower:]')" = "maps" ]; then
    root="$(dirname "$root")"
    cp -a "$root/." "$CONTENT/"
  else
    find "$root" -maxdepth 1 -type f \( -iname '*.res' -o -iname '*.txt' \) -exec cp {} "$CONTENT/maps/" \;
    find "$root" -mindepth 1 -maxdepth 1 -type d -exec cp -a {} "$CONTENT/" \;
  fi
  cp "$bsp" "$CONTENT/maps/$map.bsp"
  find "$dir" -type f -iname '*.wad' -exec cp {} "$CONTENT/" \;
}

reason=""
while read -r map url _; do
  [[ -z "$map" || "$map" == \#* ]] && continue
  if [ -e "$CONTENT/maps/$map.bsp" ] && [ "$FORCE" = "0" ]; then
    skipped+=("$map"); continue
  fi
  if [ -z "${url:-}" ] || [[ "$url" == \#* ]]; then
    no_url+=("$map"); continue
  fi

  work="$(mktemp -d)"
  echo "==> $map"
  if curl -fsSL --retry 3 -o "$work/download" "$url" \
     && mkdir "$work/x" && reason="$(extract "$work/download" "$work/x")" \
     && reason="$(install_map "$map" "$work/x")"; then
    ok+=("$map")
  else
    failed+=("$map${reason:+ ($reason)}")
  fi
  rm -rf "$work"
  reason=""
done < "$MANIFEST"

if [ -d "$ASSETS" ]; then
  cp -a "$ASSETS/." "$CONTENT/"
  echo "==> plugin assets synced from server/plugins/assets"
fi
chmod -R a+rX "$CONTENT"

summary() { local label="$1"; shift; [ "$#" -gt 0 ] && printf '%-8s %s\n' "$label" "$*"; return 0; }
echo
summary "ok:" "${ok[@]}"
summary "skipped:" "${skipped[@]}"
summary "no url:" "${no_url[@]}"
summary "failed:" "${failed[@]}"

[ "${#failed[@]}" -eq 0 ]
