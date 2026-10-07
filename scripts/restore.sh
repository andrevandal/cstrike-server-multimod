#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 <backups/cs16-state-....tar.gz>" >&2
  echo "env:   CSTRIKE_CONTAINER=<name> to stop/start a container directly (e.g. on Coolify)" >&2
  exit 1
}

archive="${1:-}"
[ -f "$archive" ] || usage
archive="$(realpath "$archive")"

cd "$(dirname "$0")/.."

stop_server() {
  if [ -n "${CSTRIKE_CONTAINER:-}" ]; then docker stop "$CSTRIKE_CONTAINER"; else docker compose stop cstrike; fi
}

start_server() {
  if [ -n "${CSTRIKE_CONTAINER:-}" ]; then docker start "$CSTRIKE_CONTAINER"; else docker compose start cstrike; fi
}

stop_server

mkdir -p backups state
safety="backups/pre-restore-$(date +%Y-%m-%dT%H-%M-%S).tar.gz"
tar -czf "$safety" -C state .
echo "current state saved to $safety"

tar -xzf "$archive" --strip-components=2 -C state
echo "restored $archive into ./state"

start_server
