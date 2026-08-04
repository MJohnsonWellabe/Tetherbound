#!/usr/bin/env bash
# Put GDExtension libraries where the engine actually looks for them.
#
#   tools/stage_gdextension_libs.sh <export-dir>
#
# Godot's exporter copies a GDExtension's shared library FLAT into the export
# directory — `libterrain.windows.release.x86_64.dll` beside the .exe. The
# engine then tries to open it at the path written in the `.gdextension` file,
# `res://addons/terrain_3d/bin/libterrain...`, resolved relative to the
# executable. Those are not the same place, so the library is not found, the
# extension does not load, and every class it provides silently ceases to exist.
#
# For Tetherbound that means Terrain3D is absent, `_build_terrain()` returns
# null, and the player spawns in mid-air over an empty world and falls forever.
# That build shipped. It passed 107 unit tests, seven smoke tests, and an export
# check that verified the .exe was a real PE binary — because every one of those
# runs the project from source, where addons load from res:// and always work.
#
# So: copy each library into the directory its .gdextension claims, and leave
# the flat copy alone. Both locations cost a few megabytes and neither can be
# the wrong one.
set -euo pipefail

DIR="${1:?usage: stage_gdextension_libs.sh <export-dir>}"
cd "$(dirname "$0")/.."

staged=0
while IFS= read -r ext; do
  # Lines look like:  windows.release.x86_64 = "res://addons/.../libfoo.dll"
  while IFS= read -r target; do
    rel="${target#res://}"
    name="$(basename "$rel")"
    if [ -f "$DIR/$name" ]; then
      mkdir -p "$DIR/$(dirname "$rel")"
      cp -f "$DIR/$name" "$DIR/$rel"
      staged=$((staged + 1))
    elif [ -f "$rel" ]; then
      # Not exported for this target (e.g. the Linux .so during a Windows
      # build). Copy from the project so a locally-run pack still works.
      mkdir -p "$DIR/$(dirname "$rel")"
      cp -f "$rel" "$DIR/$rel"
      staged=$((staged + 1))
    fi
  done < <(grep -oE '"res://[^"]+"' "$ext" | tr -d '"' | grep -E '\.(dll|so|dylib)$')
done < <(find addons -name "*.gdextension" 2>/dev/null)

echo "staged $staged GDExtension librar$([ "$staged" = 1 ] && echo y || echo ies) under $DIR/addons/"
