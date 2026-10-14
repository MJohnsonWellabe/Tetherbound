#!/usr/bin/env bash
# Run the unit suite as N parallel shards (default: CPU count) and merge the
# verdict. Same files and assertions as `tests/run_tests.gd`; only wall time
# changes (owner, 13 Oct 2026: unit tests must not take hours).
#   tools/run_units.sh            # all files, nproc shards
#   tools/run_units.sh 8          # 8 shards
#   tools/run_units.sh 4 --only=water   # extra runner args pass through
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
N="${1:-$(nproc)}"; shift || true
OUT="${UNITS_OUT:-/tmp/tb-units}"; rm -rf "$OUT"; mkdir -p "$OUT"
start=$(date +%s)
for i in $(seq 1 "$N"); do
  "$GODOT" --headless --path . --script tests/run_tests.gd -- --shard="$i/$N" "$@" > "$OUT/shard-$i.log" 2>&1 &
done
wait
rc=0; tests=0; failed=0
for i in $(seq 1 "$N"); do
  line=$(grep -E '^[0-9]+ tests, [0-9]+ assertions, [0-9]+ failed' "$OUT/shard-$i.log" | tail -1)
  if [ -z "$line" ]; then echo "shard $i/$N: no verdict (crash?) -- see $OUT/shard-$i.log"; rc=1; continue; fi
  t=$(echo "$line" | awk '{print $1}'); f=$(echo "$line" | awk '{print $5}')
  tests=$((tests + t)); failed=$((failed + f))
  [ "$f" -gt 0 ] && rc=1
done
echo "== FAILURES"; grep -h '^  FAIL' "$OUT"/shard-*.log || echo "  none"
echo "== SLOWEST FILES (across shards)"
grep -hE '^ +[0-9]+\.[0-9] s  ' "$OUT"/shard-*.log | sort -rn | head -15
echo "== $tests tests, $failed failed, $N shards, wall $(( $(date +%s) - start )) s (logs: $OUT)"
exit $rc
