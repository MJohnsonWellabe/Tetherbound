#!/usr/bin/env bash
# Run the unit suite on N parallel lanes (default: CPU count) and merge the
# verdict. Same files and assertions as `tests/run_tests.gd`; only wall time
# changes (owner, 13 Oct 2026: unit tests must not take hours).
#   tools/run_units.sh            # all files, nproc lanes
#   tools/run_units.sh 8          # 8 lanes
#   tools/run_units.sh 4 --only=water   # extra runner args pass through
#
# Scheduling: the files measured at ~10 minutes each (HEAVY, below) start
# first, one per lane, because a fixed `--shard=i/N` split can stack two of
# them on one lane and that lane alone then sets the wall time. Everything
# else is cut into small `--shard` slices of the remaining files, and every
# lane pulls the next unclaimed slice when it is free (claimed with `mkdir`,
# which is atomic), so the light files fill in around the heavy ones.
# With --only, the runner's own filter decides the files: no heavy split.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
N="${1:-$(nproc)}"; shift || true
OUT="${UNITS_OUT:-/tmp/tb-units}"; rm -rf "$OUT"; mkdir -p "$OUT/claims"
# Slowest first. Measured 13 Oct 2026 after the shared-placement memo:
# test_scatter_rules ~1200 s, test_harvest ~750 s, test_veg_corridor ~570 s.
HEAVY=(test_scatter_rules.gd test_harvest.gd test_veg_corridor.gd)
start=$(date +%s)

only=0
for a in "$@"; do
  [[ "$a" == --only=* ]] && only=1
  if [[ "$a" == --skip=* ]]; then echo "run_units.sh: --skip is reserved for its own lanes; use --only" >&2; exit 2; fi
done
if [ "$only" = 1 ]; then HEAVY=(); fi
SLICES=$(( N * 4 ))
skip=$(IFS=,; echo "${HEAVY[*]}")

run() { # log-name, runner args...
  local name="$1"; shift
  "$GODOT" --headless --path . --script tests/run_tests.gd -- "$@" > "$OUT/$name.log" 2>&1
}

lane() {
  local i="$1"
  # Heavy file k (0-based) runs on lane k % N, so fewer lanes than heavy files
  # still runs every one of them.
  for k in "${!HEAVY[@]}"; do
    if [ $(( k % N + 1 )) -eq "$i" ]; then run "heavy-$((k + 1))" --only="${HEAVY[$k]}" "$@"; fi
  done
  for s in $(seq 1 "$SLICES"); do
    mkdir "$OUT/claims/$s" 2>/dev/null || continue
    if [ -n "$skip" ]; then run "slice-$s" --skip="$skip" --shard="$s/$SLICES" "$@"
    else run "slice-$s" --shard="$s/$SLICES" "$@"; fi
  done
}

for i in $(seq 1 "$N"); do lane "$i" "$@" & done
wait

rc=0; tests=0; failed=0
for log in "$OUT"/*.log; do
  line=$(grep -E '^[0-9]+ tests, [0-9]+ assertions, [0-9]+ failed' "$log" | tail -1)
  if [ -z "$line" ]; then echo "$(basename "$log"): no verdict (crash?) -- see $log"; rc=1; continue; fi
  t=$(echo "$line" | awk '{print $1}'); f=$(echo "$line" | awk '{print $5}')
  tests=$((tests + t)); failed=$((failed + f))
  [ "$f" -gt 0 ] && rc=1
done
echo "== FAILURES"; grep -h '^  FAIL' "$OUT"/*.log || echo "  none"
echo "== SLOWEST FILES (across lanes)"
grep -hE '^ +[0-9]+\.[0-9] s  ' "$OUT"/*.log | sort -rn | head -15
echo "== $tests tests, $failed failed, $N lanes, wall $(( $(date +%s) - start )) s (logs: $OUT)"
exit $rc
