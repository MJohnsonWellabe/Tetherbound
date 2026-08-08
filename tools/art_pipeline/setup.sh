#!/usr/bin/env bash
# Fetch the tools the art pipeline needs, without installing anything.
#
#   tools/art_pipeline/setup.sh          # everything
#   tools/art_pipeline/setup.sh blender  # just one
#   tools/art_pipeline/setup.sh --print   # paths only, fetch nothing
#
# Both Blender and Godot ship self-contained builds that run from wherever they
# are unpacked, so nothing here needs root, touches the system, or has to be
# undone. They land in a cache directory outside the repository and are never
# committed — a 350 MB Blender in Git would be worse than any problem it solves.
#
# Idempotent: a tool already present is left alone. Safe to run at the start of
# any session, which is the point, because the cloud containers this project is
# built in are ephemeral and start with neither tool installed.
#
# WHY NOT MCP. TETHERBOUND_3D_ART_PIPELINE.md section 3.2 and Tier B assume a
# Meshy MCP server and a Blender MCP bridge. Scripts are used instead. See
# docs/decisions/D11 for the reasoning; the short version is that an MCP server
# cannot be added to a session already running, it dies with the session, and
# Blender's --background --python does everything the cleanup pass needs. A
# committed script survives; a session-local MCP config does not.
set -uo pipefail

CACHE="${TETHERBOUND_ART_CACHE:-$HOME/.cache/tetherbound-art}"

# Pinned. An art pipeline that silently changes Blender version between runs
# produces different geometry from the same inputs, and 4.2 is the LTS line.
BLENDER_VERSION="4.2.9"
BLENDER_SERIES="4.2"

# Must match .github/workflows/ci.yml. Validation renders are only meaningful if
# they come from the engine the game ships on.
GODOT_VERSION="4.7-stable"

BLENDER_DIR="$CACHE/blender-${BLENDER_VERSION}-linux-x64"
BLENDER="$BLENDER_DIR/blender"
GODOT="$CACHE/godot"

fetch_blender() {
  if [ -x "$BLENDER" ]; then
    echo "blender  present  $BLENDER"
    return 0
  fi
  local url="https://download.blender.org/release/Blender${BLENDER_SERIES}/blender-${BLENDER_VERSION}-linux-x64.tar.xz"
  echo "blender  fetching ${BLENDER_VERSION} ..."
  mkdir -p "$CACHE"
  if ! curl -fsSL --retry 3 --retry-delay 2 -o "$CACHE/blender.tar.xz" "$url"; then
    echo "blender  FAILED to download from $url" >&2
    return 1
  fi
  tar -xJf "$CACHE/blender.tar.xz" -C "$CACHE" && rm -f "$CACHE/blender.tar.xz"
  [ -x "$BLENDER" ] || { echo "blender  unpacked but no executable at $BLENDER" >&2; return 1; }
  echo "blender  ready    $("$BLENDER" --version 2>/dev/null | head -1)"
}

fetch_godot() {
  if [ -x "$GODOT" ]; then
    echo "godot    present  $GODOT"
    return 0
  fi
  local base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}"
  echo "godot    fetching ${GODOT_VERSION} ..."
  mkdir -p "$CACHE"
  if ! curl -fsSL --retry 3 --retry-delay 2 -o "$CACHE/godot.zip" \
      "${base}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"; then
    echo "godot    FAILED to download" >&2
    return 1
  fi
  unzip -qo "$CACHE/godot.zip" -d "$CACHE" && rm -f "$CACHE/godot.zip"
  mv -f "$CACHE/Godot_v${GODOT_VERSION}_linux.x86_64" "$GODOT"
  chmod +x "$GODOT"
  echo "godot    ready    $("$GODOT" --version 2>/dev/null | head -1)"
}

fetch_python() {
  # Pillow and numpy, for crop_views.py and compare_sheet.py. Blender ships its
  # own Python and does not use these.
  if python3 -c "import PIL, numpy" 2>/dev/null; then
    echo "python   present  Pillow + numpy"
    return 0
  fi
  echo "python   installing Pillow + numpy ..."
  pip install --quiet pillow numpy || {
    echo "python   FAILED — install pillow and numpy by hand" >&2
    return 1
  }
  echo "python   ready"
}

# Rendering needs a display and a software rasteriser. Reported rather than
# installed, because this is the one step that does need root and the caller may
# not have it.
check_render_deps() {
  local missing=()
  command -v xvfb-run >/dev/null || missing+=("xvfb")
  [ -e /usr/share/vulkan/icd.d ] || [ -n "$(ls /usr/lib/*/libGL.so* 2>/dev/null)" ] || missing+=("mesa-utils")
  if [ ${#missing[@]} -gt 0 ]; then
    echo "render   MISSING  ${missing[*]}"
    echo "                  sudo apt-get install -y xvfb mesa-vulkan-drivers"
    return 1
  fi
  echo "render   present  xvfb + GL"
}

if [ "${1:-}" = "--print" ]; then
  echo "BLENDER=$BLENDER"
  echo "GODOT=$GODOT"
  echo "CACHE=$CACHE"
  exit 0
fi

status=0
case "${1:-all}" in
  blender) fetch_blender || status=1 ;;
  godot)   fetch_godot   || status=1 ;;
  python)  fetch_python  || status=1 ;;
  all)
    fetch_blender    || status=1
    fetch_godot      || status=1
    fetch_python     || status=1
    check_render_deps || true   # advisory: headless inspection works without it
    ;;
  *) echo "usage: $0 [all|blender|godot|python|--print]" >&2; exit 2 ;;
esac

echo
echo "cache: $CACHE  (never committed; safe to delete and re-fetch)"
exit $status
