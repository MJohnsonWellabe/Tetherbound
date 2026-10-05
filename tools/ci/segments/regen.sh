#!/usr/bin/env bash
# Re-generate one CI segment checkpoint by RUNNING its producer segment(s)
# through the real game and save code, then installing what they saved.
#
#   tools/ci/segments/regen.sh <boundary>        e.g. midride/setup
#
# For each role of the boundary (tests/helpers/ci_segments.gd BOUNDARIES), runs
# the producer scenario with TB_SEGMENT_REGEN=1; its `seg_checkpoint` step
# checks the contract on the save it just wrote and records the state digest.
# Then replaces tests/fixtures/segments/<boundary>/<role>/ with that capture's
# saves/, worlds/ and characters/ (gzipped, deterministic header) and writes
# manifest.json (digest, character id, producer fingerprint, commit). Never
# edit a checkpoint by hand: the handoff check refuses a manifest mismatch.
# Upstream boundaries must be fresh first (a producer starts from them).
set -euo pipefail
[ $# -eq 1 ] || { sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
boundary="$1"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
godot="${GODOT_BIN:-${GODOT:-$(command -v godot || echo "$HOME/godot-bin/godot")}}"
cd "$repo"
info="$("$godot" --headless --path . --script tools/ci/segments/boundary_info.gd -- --boundary="$boundary" 2>/dev/null | sed -n 's/^BOUNDARY_INFO //p')"
[ -n "$info" ] || { echo "regen: unknown boundary '$boundary'" >&2; exit 2; }
work="$(mktemp -d "${TMPDIR:-/tmp}/ci-segment-regen-XXXXXX")"
# Kept on failure (the producer's run.log, PROOF.md and peer logs), removed on success.
trap 'rc=$?; if [ "$rc" -eq 0 ]; then rm -rf "$work"; else echo "regen: logs kept in $work" >&2; fi' EXIT
# One run per distinct producer (both roles of a two-peer segment come from one run).
mapfile -t producers < <(python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print("\n".join(sorted({r["producer"]+"\t"+r["runner"]+"\t"+" ".join(r["runner_args"]) for r in d["roles"].values()})))' "$info")
i=0
for line in "${producers[@]}"; do
	IFS=$'\t' read -r producer runner runner_args <<<"$line"
	i=$((i + 1)); out="$work/run-$i"; mkdir -p "$out/net" "$out/home"
	if [ "${producer##*.}" = "gd" ]; then
		# A solo smoke segment: its own isolated user:// and output dir.
		echo "regen: running $(basename "$producer") $runner_args"
		# shellcheck disable=SC2086
		run=(env TB_SEGMENT_REGEN=1 TB_SEGMENT_OUT="$out" XDG_DATA_HOME="$out/home" \
			"$godot" --headless --path . --script "$runner" -- $runner_args)
	else
		peers="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("peers",2))' "$producer")"
		echo "regen: running $(basename "$producer") ($peers peer(s))"
		run=(env TB_SEGMENT_REGEN=1 TB_PROOF_SCENARIO="$producer" TB_PROOF_OUT="$out" TB_NET_RUN_ID="net-regen-$i-$$" \
			TB_NET_OUT_DIR="$out/net" TB_NET_PEERS="$peers" \
			"$godot" --headless --path . --script "$runner")
	fi
	if ! "${run[@]}" >"$out/run.log" 2>&1; then
		grep -E '^(FAIL|ERROR)|SCRIPT ERROR' "$out/run.log" | head -40 >&2 || tail -40 "$out/run.log" >&2
		echo "regen: producer $(basename "$producer") failed; checkpoint $boundary NOT changed" >&2
		exit 1
	fi
done
commit="$(git rev-parse HEAD)$(git diff --quiet HEAD -- . ':!tests/fixtures/segments' || echo '+dirty')"
python3 - "$info" "$work" "$commit" <<'PY'
import json, os, shutil, subprocess, sys, glob
info, work, commit = json.loads(sys.argv[1]), sys.argv[2], sys.argv[3]
records = {}
for path in glob.glob(os.path.join(work, "run-*", "**", "segment_checkpoint.json"), recursive=True):
    if "/home/" in path[len(work):]:
        continue
    rec = json.load(open(path))
    if rec.get("boundary") == info["boundary"]:
        records[rec["role"]] = (os.path.dirname(path), rec)
manifest = {"boundary": info["boundary"], "produced_at_commit": commit,
            "generated_by": "tools/ci/segments/regen.sh " + info["boundary"], "roles": {}}
for role, spec in info["roles"].items():
    if role not in records:
        sys.exit("regen: producer wrote no seg_checkpoint record for role %s" % role)
    src, rec = records[role]
    if rec.get("contract_failures"):
        sys.exit("regen: %s misses its contract: %s" % (role, rec["contract_failures"]))
    dst = spec["dir"]
    shutil.rmtree(dst, ignore_errors=True)
    for sub in ("saves", "worlds", "characters"):
        if os.path.isdir(os.path.join(src, sub)):
            shutil.copytree(os.path.join(src, sub), os.path.join(dst, sub))
    for f in glob.glob(os.path.join(dst, "**", "*.json"), recursive=True):
        subprocess.check_call(["gzip", "-n", "-9", f])
    manifest["roles"][role] = {"producer": os.path.relpath(spec["producer"]), "producer_peer": spec["peer"],
                               "producer_fingerprint": rec["producer_fingerprint"], "digest": rec["digest"],
                               "character_id": rec["character_id"], "summary": rec["summary"]}
    print("regen: installed %s:%s digest %s" % (info["boundary"], role, rec["digest"][:12]))
with open(info["manifest"], "w") as f:
    json.dump(manifest, f, indent=1, sort_keys=True)
    f.write("\n")
PY
