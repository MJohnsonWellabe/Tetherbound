#!/usr/bin/env bash
# Cloud lane setup (WORKFLOW §8). Idempotent. Installs the pinned Godot editor
# at ~/godot-bin/godot, puts `godot` on PATH, makes sure xvfb is present for
# production-path renders, and warms the project's .godot import cache when a
# checkout is found, so a fresh or restarted lane session starts ready.
# Usable as the environment's setup script or run by hand: bash tools/cloud_setup.sh
set -uo pipefail
GODOT_VERSION=${GODOT_VERSION:-4.7-stable}
BIN="$HOME/godot-bin/godot"
if [ ! -x "$BIN" ]; then
  base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}"
  mkdir -p "$HOME/godot-bin"
  tmp=$(mktemp -d)
  curl -fsSL --retry 4 -o "$tmp/godot.zip" "${base}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
    && unzip -q "$tmp/godot.zip" -d "$tmp" \
    && mv "$tmp/Godot_v${GODOT_VERSION}_linux.x86_64" "$BIN" && chmod +x "$BIN" \
    || echo "cloud_setup: Godot download failed" >&2
  rm -rf "$tmp"
fi
[ -x "$BIN" ] && ln -sf "$BIN" /usr/local/bin/godot 2>/dev/null || true
# vp_capture.sh and other capture tools look here by default.
mkdir -p "$HOME/.cache/tetherbound-art" && ln -sf "$BIN" "$HOME/.cache/tetherbound-art/godot"
if ! command -v xvfb-run >/dev/null 2>&1; then
  (apt-get install -y -qq xvfb || sudo apt-get install -y -qq xvfb) >/dev/null 2>&1 || true
fi
# Warm the import cache. The first import on a clean checkout exits non-zero
# after finishing (Terrain3D shutdown abort, see ci.yml); the second is quick.
for repo in "${TETHERBOUND_REPO:-}" "$PWD" /home/user/Tetherbound /home/user/tetherbound; do
  [ -n "$repo" ] && [ -f "$repo/project.godot" ] || continue
  timeout 900 "$BIN" --headless --path "$repo" --import >/dev/null 2>&1 || true
  timeout 300 "$BIN" --headless --path "$repo" --import >/dev/null 2>&1 || true
  echo "cloud_setup: import cache warmed in $repo"
  break
done
"$BIN" --version 2>/dev/null | sed 's/^/cloud_setup: godot /' || true
exit 0
