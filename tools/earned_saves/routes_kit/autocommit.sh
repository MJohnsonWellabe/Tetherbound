#!/usr/bin/env bash
# Watch a chain.sh output file; commit each piece that ENDs with exit=0 (commit_piece.sh) as fixture <prefix><name>.
#   EDIT=... autocommit.sh <chain.out> <prefix>     (run detached next to chain.sh)
out="$1"; pre="$2"; done_list="$out.committed"; touch "$done_list"; here="$(dirname "$0")"; RB="${RB:-$HOME/rb}"
while true; do
  grep -oE "^END [^ ]+ exit=0" "$out" | awk '{print $2}' | while read -r n; do
    grep -qx "$n" "$done_list" && continue
    if "$here/commit_piece.sh" "$n" "${pre}${n}" >> "$out.commit.log" 2>&1; then echo "$n" >> "$done_list"; echo "COMMITTED $n"; else echo "COMMIT-FAIL $n"; fi
  done
  grep -qE "^(STOP|COMPLETE)" "$out" && [ "$(grep -c '^END .* exit=0' "$out")" -le "$(wc -l < "$done_list")" ] && break
  sleep 30
done
