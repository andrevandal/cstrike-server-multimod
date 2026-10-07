#!/usr/bin/env bash
# Bumps the ARG pins in server/Dockerfile to the latest stable upstream releases:
# ReHLDS, ReGameDLL, Metamod-R, ReAPI, ReUnion (newest non-prerelease GitHub release),
# AMX Mod X (newest 1.10 build on amxmodx.org) and WHBlocker (newest PluginyCS/BasePack release).
# Review the diff, rebuild, smoke-test, then commit.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKERFILE="$ROOT/server/Dockerfile"
API=https://api.github.com/repos

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1" >&2; exit 1; }; }
need curl; need sha256sum; need sed

# GitHub's /releases/latest skips prereleases and drafts.
latest_release() {
  curl -fsSL "$API/$1/releases/latest" | sed -n 's/^  "tag_name": "\(.*\)",$/\1/p'
}

set_arg() {
  local name="$1" value="$2" current
  [ -n "$value" ] || { echo "could not resolve $name" >&2; exit 1; }
  current="$(sed -n "s/^ARG $name=//p" "$DOCKERFILE")"
  if [ "$current" = "$value" ]; then
    printf '  %-20s %s (unchanged)\n' "$name" "$value"
  else
    sed -i "s|^ARG $name=.*|ARG $name=$value|" "$DOCKERFILE"
    printf '  %-20s %s -> %s\n' "$name" "$current" "$value"
  fi
}

echo "Updating $DOCKERFILE"
set_arg REHLDS_VERSION "$(latest_release rehlds/ReHLDS)"
set_arg REGAMEDLL_VERSION "$(latest_release rehlds/ReGameDLL_CS)"
set_arg METAMOD_R_VERSION "$(latest_release rehlds/Metamod-R)"
set_arg REAPI_VERSION "$(latest_release rehlds/ReAPI)"
set_arg REUNION_VERSION "$(latest_release rehlds/ReUnion)"

# AMXX 1.10 has no tagged release; every server runs the newest 1.10 build.
amxx="$(curl -fsSL https://www.amxmodx.org/amxxdrop/1.10/ \
  | grep -oE 'amxmodx-1\.10\.0-git[0-9]+-cstrike-linux\.tar\.gz' \
  | sed -E 's/^amxmodx-(1\.10\.0-git[0-9]+)-cstrike-linux\.tar\.gz$/\1/' | sort -uV | tail -n1)"
set_arg AMXX_VERSION "$amxx"

basepack_tag="$(latest_release PluginyCS/BasePack)"
basepack_ref="$(curl -fsSL "$API/PluginyCS/BasePack/commits/$basepack_tag" | sed -n 's/^  "sha": "\(.*\)",$/\1/p' | head -n1)"
whb_sha="$(curl -fsSL "https://raw.githubusercontent.com/PluginyCS/BasePack/$basepack_ref/cstrike/addons/whblocker/whblocker_mm_i386.so" \
  | sha256sum | cut -d' ' -f1)"
echo "  BasePack release $basepack_tag"
set_arg BASEPACK_REF "$basepack_ref"
set_arg WHBLOCKER_SHA256 "$whb_sha"

echo
echo "Next: docker compose build cstrike, boot it, check logs, then commit server/Dockerfile."
