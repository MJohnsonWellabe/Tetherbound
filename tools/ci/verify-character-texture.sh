#!/usr/bin/env bash
set -euo pipefail

character_run_root=$(mktemp -d "${RUNNER_TEMP:-/tmp}/character-texture.XXXXXX")
mkdir -p "$character_run_root/config" "$character_run_root/data" "$character_run_root/cache"
echo "Character texture receipts: $character_run_root (first and only attempt)"
set +e
timeout --kill-after=5s 45s env \
  XDG_CONFIG_HOME="$character_run_root/config" \
  XDG_DATA_HOME="$character_run_root/data" \
  XDG_CACHE_HOME="$character_run_root/cache" \
  godot --headless --path . --script tools/probe_character_teal_accent.gd -- --validate-only \
  2>&1 | tee "$character_run_root/engine.log"
statuses=("${PIPESTATUS[@]}")
set -e
if (( statuses[0] != 0 || statuses[1] != 0 )); then
  echo "::error::Character texture probe failed or could not write its complete log"
  exit 1
fi
if grep -niE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$character_run_root/engine.log"; then
  echo "::error::Character texture probe emitted a native error"
  exit 1
fi
if ! grep -Fxq 'CHARACTER_ACCENT checks=7 failures=[]' "$character_run_root/engine.log"; then
  echo "::error::Character texture probe did not complete all seven checks"
  exit 1
fi
