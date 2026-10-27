#!/usr/bin/env bash
# Restore archived lane assets from main's own git history (they are reachable
# through the 27 Oct archive merge, so this works after the branches are deleted).
# Usage, from the repository root:
#   ralph/reports/ARCHIVE/lane-work/restore_assets.sh                # every asset
#   ralph/reports/ARCHIVE/lane-work/restore_assets.sh meshy-1024     # one lane
#   ralph/reports/ARCHIVE/lane-work/restore_assets.sh '' meadows_    # paths containing a string
set -euo pipefail
here="$(dirname "$0")"
lane="${1:-}"; match="${2:-}"
tail -n +2 "$here/ASSETS.tsv" | while IFS=$'\t' read -r path blob from _bytes; do
  [ -n "$lane" ] && [ "$from" != "$lane" ] && continue
  [ -n "$match" ] && [[ "$path" != *"$match"* ]] && continue
  mkdir -p "$(dirname "$path")"
  git cat-file -p "$blob" > "$path"
  echo "restored $path"
done
