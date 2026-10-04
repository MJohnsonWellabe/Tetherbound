#!/usr/bin/env bash
# Regenerate tools/net/proof_saves/host_meadows_stormwood_route_open/ at the
# current save version, through the game's own new-game and save code.
#
#   tools/net/build_proof_save_host_meadows_stormwood_route_open.sh
#
# Runs the builder headless in a throwaway user:// (XDG_DATA_HOME), then
# replaces the fixture's saves/, worlds/ and characters/ with what the
# production save path wrote. See the builder's header and the fixture's
# README.md for the disclosed state writes.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
godot="${GODOT_BIN:-${GODOT:-$HOME/godot-bin/godot}}"
fixture="$repo_root/tools/net/proof_saves/host_meadows_stormwood_route_open"
home="$(mktemp -d "${TMPDIR:-/tmp}/proof-save-build-XXXXXX")"
trap 'rm -rf "$home"' EXIT
log="$home/build.log"
if ! XDG_DATA_HOME="$home" "$godot" --headless --path "$repo_root" \
		--script tools/net/build_proof_save_host_meadows_stormwood_route_open.gd >"$log" 2>&1; then
	tail -40 "$log" >&2
	exit 1
fi
grep -q '^BUILD_PROOF_SAVE ' "$log" || { tail -40 "$log" >&2; exit 1; }
user="$home/godot/app_userdata/Tetherbound"
for sub in saves worlds characters; do
	rm -rf "${fixture:?}/$sub"
	cp -R "$user/$sub" "$fixture/$sub"
done
# Stored gzipped (deterministic header) like the other proof saves;
# proof_steps.gd's load_save inflates any `.gz` as it copies.
find "$fixture/saves" "$fixture/worlds" "$fixture/characters" -name '*.json' -exec gzip -n -9 {} +
grep '^BUILD_PROOF_SAVE ' "$log"
