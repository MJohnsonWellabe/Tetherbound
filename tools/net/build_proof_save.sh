#!/usr/bin/env bash
# Build a declared-start proof save at the current save version from a spec,
# through the game's own new-game and save code.
#
#   tools/net/build_proof_save.sh tools/net/proof_save_specs/<fixture>.json
#
# Runs tools/net/build_proof_save.gd headless in a throwaway user://
# (XDG_DATA_HOME), then replaces tools/net/proof_saves/<fixture>/'s saves/,
# worlds/ and characters/ with what the production save path wrote, gzipped.
# The fixture's README.md (kept) lists the disclosed state writes.
set -euo pipefail
[ $# -eq 1 ] || { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
godot="${GODOT_BIN:-${GODOT:-$HOME/godot-bin/godot}}"
spec="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
fixture_name="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["fixture"])' "$spec")"
case "$fixture_name" in ""|*/*|.*) echo "bad fixture name '$fixture_name' in $spec" >&2; exit 2 ;; esac
fixture="$repo_root/tools/net/proof_saves/$fixture_name"
home="$(mktemp -d "${TMPDIR:-/tmp}/proof-save-build-XXXXXX")"
trap 'rm -rf "$home"' EXIT
log="$home/build.log"
if ! XDG_DATA_HOME="$home" "$godot" --headless --path "$repo_root" \
		--script tools/net/build_proof_save.gd -- --spec="$spec" >"$log" 2>&1; then
	tail -40 "$log" >&2
	exit 1
fi
grep -q '^BUILD_PROOF_SAVE ' "$log" || { tail -40 "$log" >&2; exit 1; }
user="$home/godot/app_userdata/Tetherbound"
mkdir -p "$fixture"
for sub in saves worlds characters; do
	rm -rf "${fixture:?}/$sub"
	cp -R "$user/$sub" "$fixture/$sub"
done
# Stored gzipped (deterministic header) like the other proof saves;
# proof_steps.gd's load_save inflates any `.gz` as it copies.
find "$fixture/saves" "$fixture/worlds" "$fixture/characters" -name '*.json' -exec gzip -n -9 {} +
grep '^BUILD_PROOF_SAVE ' "$log"
