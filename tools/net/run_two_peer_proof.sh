#!/usr/bin/env bash
# Run a two-peer PROOF: real host and guest Godot processes playing a scripted
# scenario, capturing each peer's saved world and (with --render) screenshots.
#
#   tools/net/run_two_peer_proof.sh <scenario.json> [--render] [--out=DIR]
#
#   <scenario.json>  steps to play; format: the header of tests/smoke_net_proof_two_peer.gd
#   --render         peers render (not --headless) under one xvfb-run display,
#                    so `screenshot` steps write PNGs; needs xvfb-run
#   --out=DIR        where the proof lands; evidence goes under your lane's
#                    ralph/reports/<LANE>/ (default: ${TMPDIR:-/tmp}/proof-<name>-<utc>)
#
# Output: DIR/PROOF.md (every step, verdict, detail, captured files),
# DIR/peer-<i>/*.png, DIR/peer-<i>/<label>/{saves,worlds,characters}/ and the
# raw net run (peer logs, SUMMARY.md) under DIR/net/. Exit status is the
# run's: 0 only when every step met its expectation.
#
# Built on tools/net/run_net_smoke.sh + tests/smoke_net_proof_two_peer.gd;
# a loopback run is local evidence, never internet or Steam acceptance.
set -uo pipefail

usage() {
	sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//' >&2
	exit 2
}

scenario=""
render=0
out=""
for arg in "$@"; do
	case "$arg" in
		--render) render=1 ;;
		--out=*) out="${arg#--out=}" ;;
		-h|--help) usage ;;
		-*) echo "unknown option: $arg" >&2; usage ;;
		*) scenario="$arg" ;;
	esac
done
[ -n "$scenario" ] || usage

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ -f "$scenario" ] || scenario="$repo_root/$scenario"
if [ ! -f "$scenario" ]; then
	echo "no such scenario: $scenario" >&2
	exit 2
fi
scenario="$(cd "$(dirname "$scenario")" && pwd)/$(basename "$scenario")"
name="$(basename "$scenario" .json)"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
out="${out:-${TMPDIR:-/tmp}/proof-${name}-${stamp}}"
mkdir -p "$out/net"
out="$(cd "$out" && pwd)"

export TB_PROOF_SCENARIO="$scenario"
export TB_PROOF_OUT="$out"
peers="$(python3 -c 'import json,sys; print(int(json.load(open(sys.argv[1])).get("peers", 2)))' "$scenario" 2>/dev/null || echo 2)"

cmd=("$repo_root/tools/net/run_net_smoke.sh" proof_two_peer "--peers=$peers" "--out=$out/net")
if [ "$render" = 1 ]; then
	command -v xvfb-run >/dev/null || { echo "--render needs xvfb-run" >&2; exit 2; }
	export TB_NET_RENDER=1
	cmd=(xvfb-run -a -s "-screen 0 1920x1080x24" "${cmd[@]}")
fi

echo "proof:    $name"
echo "scenario: $scenario"
echo "out:      $out"
"${cmd[@]}"
status=$?
echo
echo "PROOF.md: $out/PROOF.md (exit $status)"
exit $status
